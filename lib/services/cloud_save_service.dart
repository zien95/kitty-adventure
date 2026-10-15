import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet.dart';

/// Only game data is backed up; authentication stays in the Firebase SDK.
class CloudSaveService extends ChangeNotifier {
  static final instance = CloudSaveService();
  static const saveKeys = {
    'kittyCatCollection',
    'selectedKittyCatIndex',
    'pet',
    'globalStats',
    'availableGames',
    'dailyStreakDate',
    'dailyStreakCount',
    'dailyQuestDate',
    'dailyQuestProgress',
    'claimedDailyQuests',
    'foundEasterEggs',
    'redeemedSecretCodes',
    'zonaPetsCareProgressV1',
    'petFiascoNestV1',
    'soundEnabled',
    'vibrationEnabled',
    'soundPack',
    'effectsVolume',
    'musicVolume',
    'musicEnabled',
    'musicTrack',
    'darkModeEnabled',
    'liteModeEnabled',
  };

  bool available = false;
  bool busy = false;
  bool needsChoice = false;
  bool cloudExists = false;
  String status = 'Play offline. Sign in to save across devices.';
  DateTime? lastSaved;
  int restoreRevision = 0;
  int _revision = 0;
  int _session = 0;
  String? _uid;
  String? _lastPayload;
  Timer? _timer;
  Timer? _saveDebounce;
  StreamSubscription<User?>? _authSubscription;
  Future<void>? _pendingSave;
  User? get user => available ? FirebaseAuth.instance.currentUser : null;

  Future<void> initialize() async {
    available = true;
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      unawaited(_accountChanged(user));
    });
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => save());
  }

  DocumentReference<Map<String, dynamic>> _document(String uid) =>
      FirebaseFirestore.instance.doc('players/$uid/saves/current');

  Future<void> _accountChanged(User? account) async {
    final session = ++_session;
    _uid = account?.uid;
    needsChoice = account != null;
    cloudExists = false;
    _lastPayload = null;
    lastSaved = null;
    _revision = 0;
    busy = account != null;
    status = account == null
        ? 'Signed out. Progress is saved on this device.'
        : 'Checking your cloud save…';
    notifyListeners();
    if (account == null) return;
    try {
      final remote = await _document(account.uid)
          .get(const GetOptions(source: Source.server));
      final prefs = await SharedPreferences.getInstance();
      if (session != _session) return;
      cloudExists = remote.exists;
      _revision = (remote.data()?['revision'] as num?)?.toInt() ?? 0;
      lastSaved = (remote.data()?['updatedAt'] as Timestamp?)?.toDate();
      final sameSave = prefs.getString('cloudSaveOwner') == account.uid &&
          prefs.getInt('cloudSaveRevision') == _revision;
      needsChoice = !sameSave;
      status = needsChoice
          ? 'Choose which progress to keep.'
          : 'Cloud saving is on.';
    } catch (_) {
      status =
          'Cloud is unavailable. Your device progress is safe. Retry when online.';
    } finally {
      if (session == _session) {
        busy = false;
        notifyListeners();
      }
    }
  }

  Future<void> retry() async => _accountChanged(user);

  void scheduleSave() {
    if (!available) return;
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(seconds: 2), () => save());
  }

  static Map<String, dynamic> snapshot(SharedPreferences prefs) {
    final result = <String, dynamic>{
      for (final key in saveKeys.toList()..sort())
        if (prefs.containsKey(key)) key: prefs.get(key),
    };
    // The active pet's timer saves more often than the collection. Keep the
    // complete family snapshot coherent with its most recent active pet.
    if (result['pet'] is String && result['kittyCatCollection'] is String) {
      try {
        final pet = jsonDecode(result['pet']);
        final collection = jsonDecode(result['kittyCatCollection']) as List;
        final index = collection.indexWhere((item) => item['id'] == pet['id']);
        if (index >= 0) collection[index] = pet;
        result['kittyCatCollection'] = jsonEncode(collection);
      } catch (_) {/* Validation reports malformed data before upload. */}
    }
    return result;
  }

  /// Validate the entire payload before changing any local preference.
  static Map<String, dynamic> validatePayload(String payload) {
    if (utf8.encode(payload).length > 800000)
      throw const FormatException('Save is too large.');
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic>)
      throw const FormatException('Invalid save.');
    final values = <String, dynamic>{};
    const booleans = {
      'soundEnabled',
      'vibrationEnabled',
      'musicEnabled',
      'darkModeEnabled',
      'liteModeEnabled'
    };
    const integers = {'selectedKittyCatIndex', 'dailyStreakCount'};
    const volumes = {'effectsVolume', 'musicVolume'};
    for (final entry in decoded.entries) {
      if (!saveKeys.contains(entry.key)) continue;
      final value = entry.value;
      final valid = booleans.contains(entry.key)
          ? value is bool
          : integers.contains(entry.key)
              ? value is int && value >= 0
              : volumes.contains(entry.key)
                  ? value is num && value.isFinite && value >= 0 && value <= 1
                  : value is String;
      if (!valid) {
        throw const FormatException('Invalid save value.');
      }
      values[entry.key] = value;
    }
    final collection = values['kittyCatCollection'];
    if (collection != null &&
        (collection is! String || jsonDecode(collection) is! List)) {
      throw const FormatException('Invalid pet collection.');
    }
    try {
      if (collection != null) {
        for (final pet in jsonDecode(collection)) {
          Pet.fromJson(Map<String, dynamic>.from(pet));
        }
      }
      if (values['pet'] != null)
        Pet.fromJson(Map<String, dynamic>.from(jsonDecode(values['pet'])));
    } catch (_) {
      throw const FormatException('Invalid pet data.');
    }
    for (final key in [
      'pet',
      'globalStats',
      'dailyQuestProgress',
      'zonaPetsCareProgressV1',
      'petFiascoNestV1'
    ]) {
      if (values[key] != null &&
          (values[key] is! String || jsonDecode(values[key]) is! Map)) {
        throw const FormatException('Invalid game data.');
      }
    }
    return values;
  }

  Future<void> useDevice() async {
    if (busy || _uid == null) return;
    // Explicit choice authorizes replacing a different cloud snapshot.
    await save(force: true);
  }

  Future<void> save({bool force = false}) {
    if (_pendingSave != null) return _pendingSave!;
    final future = _save(force: force);
    _pendingSave = future;
    return future.whenComplete(() => _pendingSave = null);
  }

  Future<void> _save({required bool force}) async {
    final uid = _uid;
    final session = _session;
    if (!available || uid == null || busy || (needsChoice && !force)) return;
    busy = true;
    if (force) notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode(snapshot(prefs));
      validatePayload(payload);
      if (!force && payload == _lastPayload) return;
      final expected = _revision;
      final next = await FirebaseFirestore.instance
          .runTransaction<int>((transaction) async {
        final document = _document(uid);
        final remote = await transaction.get(document);
        final current = (remote.data()?['revision'] as num?)?.toInt() ?? 0;
        if (!force && current != expected) throw StateError('conflict');
        if (session != _session) throw StateError('account-changed');
        transaction.set(document, {
          'schema': 1,
          'payload': payload,
          'revision': current + 1,
          'updatedAt': FieldValue.serverTimestamp(),
          'appVersion': '26.9.1',
        });
        return current + 1;
      }).timeout(const Duration(seconds: 25));
      if (session != _session) return;
      _revision = next;
      _lastPayload = payload;
      needsChoice = false;
      cloudExists = true;
      lastSaved = DateTime.now();
      await prefs.setString('cloudSaveOwner', uid);
      await prefs.setInt('cloudSaveRevision', next);
      status = 'Saved to your account.';
    } catch (error) {
      if (session != _session) return;
      if (error is StateError && error.message == 'conflict') {
        needsChoice = true;
        status =
            'Another device saved progress. Choose a save before continuing cloud sync.';
      } else {
        status =
            'Could not save online. Device progress is safe; retry when connected.';
      }
    } finally {
      if (session == _session) {
        busy = false;
        notifyListeners();
      }
    }
  }

  Future<void> restore() async {
    final uid = _uid;
    final session = _session;
    if (uid == null || busy) return;
    busy = true;
    notifyListeners();
    try {
      final remote =
          await _document(uid).get(const GetOptions(source: Source.server));
      if (!remote.exists) throw StateError('No cloud save yet.');
      final data = remote.data()!;
      final payload = data['payload'] as String;
      final values = validatePayload(payload);
      final prefs = await SharedPreferences.getInstance();
      if (session != _session) return;
      // Keep a recoverable local snapshot before a user-requested restore.
      await prefs.setString(
          'petFiascoBeforeRestore', jsonEncode(snapshot(prefs)));
      for (final key in saveKeys) {
        if (!values.containsKey(key)) {
          await prefs.remove(key);
          continue;
        }
        final value = values[key];
        if (value is String) {
          await prefs.setString(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is num) {
          await prefs.setDouble(key, value.toDouble());
        } else {
          await prefs.setStringList(key, List<String>.from(value));
        }
      }
      _revision = (data['revision'] as num).toInt();
      await prefs.setString('cloudSaveOwner', uid);
      await prefs.setInt('cloudSaveRevision', _revision);
      _lastPayload = payload;
      needsChoice = false;
      cloudExists = true;
      lastSaved = (data['updatedAt'] as Timestamp?)?.toDate();
      restoreRevision++;
      status = 'Cloud progress restored.';
    } catch (_) {
      status =
          'Could not restore. Device progress has been kept; retry when online.';
    } finally {
      if (session == _session) {
        busy = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _saveDebounce?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }
}
