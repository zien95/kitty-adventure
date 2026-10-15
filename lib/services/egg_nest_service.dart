import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet.dart';
import 'cloud_save_service.dart';

class IncubatingEgg {
  final String id;
  final PetType species;
  final DateTime startedAt;
  final DateTime readyAt;
  const IncubatingEgg(this.id, this.species, this.startedAt, this.readyAt);
  Map<String, dynamic> toJson() => {
        'id': id,
        'species': species.index,
        'startedAt': startedAt.toIso8601String(),
        'readyAt': readyAt.toIso8601String()
      };
}

class EggNestService extends ChangeNotifier {
  static const preferenceKey = 'petFiascoNestV1';
  static const incubation = Duration(minutes: 2);
  final DateTime Function() _now;
  EggNestService({DateTime Function()? now}) : _now = now ?? DateTime.now;
  IncubatingEgg? egg;
  SharedPreferences? _prefs;
  Future<void>? _initialization;
  Future<void> _queue = Future.value();
  bool _disposed = false;

  Duration get remaining {
    final difference = egg?.readyAt.difference(_now()) ?? Duration.zero;
    return difference.isNegative ? Duration.zero : difference;
  }

  bool get ready => egg != null && remaining == Duration.zero;
  double get progress => egg == null
      ? 0
      : (1 - remaining.inMilliseconds / incubation.inMilliseconds).clamp(0, 1);

  Future<void> initialize() => _initialization ??= _load();
  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.get(preferenceKey);
    if (raw is String) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final index = data['species'] as int;
        final start = DateTime.parse(data['startedAt']);
        final end = DateTime.parse(data['readyAt']);
        final id = data['id'] as String;
        if (id.isEmpty ||
            index < 0 ||
            index >= PetType.values.length ||
            end.difference(start) != incubation) throw const FormatException();
        egg = IncubatingEgg(id, PetType.values[index], start, end);
      } catch (_) {
        egg = null;
      }
    }
    _notify();
  }

  Future<void> _serialized(Future<void> Function() action) {
    final result = _queue.then((_) async {
      await initialize();
      await action();
    });
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> start(PetType species) => _serialized(() async {
        if (egg != null) throw StateError('An egg is already in the nest.');
        final now = _now();
        final next = IncubatingEgg(
            '${now.microsecondsSinceEpoch}-${Random().nextInt(0x7fffffff)}',
            species,
            now,
            now.add(incubation));
        if (!await _prefs!.setString(preferenceKey, jsonEncode(next.toJson())))
          throw StateError('Could not save egg.');
        egg = next;
        CloudSaveService.instance.scheduleSave();
        _notify();
      });

  Future<void> hatch(
          Future<void> Function(PetType species, String petId) adopt) =>
      _serialized(() async {
        final current = egg;
        if (current == null || !ready) return;
        // The deterministic pet ID makes a retry safe if adoption succeeds but
        // clearing the nest is interrupted. The caller persists before returning.
        await adopt(current.species, 'hatched-${current.id}');
        if (!await _prefs!.remove(preferenceKey))
          throw StateError('Could not save hatch.');
        egg = null;
        CloudSaveService.instance.scheduleSave();
        _notify();
      });

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
