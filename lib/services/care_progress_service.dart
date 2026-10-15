import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pet.dart';

class CareDayProgress {
  final Set<String> completedActions;
  final int comboProgress;
  final bool comboRewardEarned;
  final bool dailyRewardClaimed;

  const CareDayProgress({
    required this.completedActions,
    required this.comboProgress,
    required this.comboRewardEarned,
    required this.dailyRewardClaimed,
  });

  bool get checklistComplete =>
      completedActions.containsAll(CareProgressService.careActions);
  bool get canClaimDailyReward => checklistComplete && !dailyRewardClaimed;
}

class PetBirthday {
  final Pet pet;
  final DateTime date;
  final int age;
  final int daysUntil;
  final bool celebrated;

  const PetBirthday({
    required this.pet,
    required this.date,
    required this.age,
    required this.daysUntil,
    required this.celebrated,
  });

  bool get isToday => daysUntil == 0;
  bool get canCelebrate => isToday && !celebrated;
}

/// Tracks each pet separately. Currency is awarded by the caller, which owns
/// the saved pet collection; this service returns only newly earned rewards.
class CareProgressService extends ChangeNotifier {
  static const preferenceKey = 'zonaPetsCareProgressV1';
  static const careActions = {'feed', 'play', 'clean', 'rest', 'bond'};
  static const comboRewardCoins = 30;
  static const dailyRewardCoins = 100;
  static const birthdayRewardCoins = 150;
  static const comboWindow = Duration(seconds: 60);

  final DateTime Function() _now;
  final Map<String, Map<String, _CareRecord>> _days = {};
  final Set<String> _birthdayClaims = {};
  SharedPreferences? _preferences;
  Future<void>? _initialization;
  Future<void> _pending = Future<void>.value();
  bool _disposed = false;
  bool isInitialized = false;

  CareProgressService({DateTime Function()? now}) : _now = now ?? DateTime.now;

  Future<void> initialize() => _initialization ??= _load();

  Future<void> _load() async {
    _preferences = await SharedPreferences.getInstance();
    final saved = _preferences!.get(preferenceKey);
    if (saved is String) {
      try {
        _restore(jsonDecode(saved));
      } on FormatException {
        // A malformed journal must not prevent the pet game from opening.
        _days.clear();
        _birthdayClaims.clear();
      }
    }
    isInitialized = true;
    _notify();
  }

  CareDayProgress progressFor(String petId) {
    final now = _now();
    final record = _days[_dayKey(now)]?[petId];
    return CareDayProgress(
      completedActions: Set.unmodifiable(record?.actions ?? <String>{}),
      comboProgress: record == null ? 0 : _recentActions(record, now).length,
      comboRewardEarned: record?.comboClaimed ?? false,
      dailyRewardClaimed: record?.dailyClaimed ?? false,
    );
  }

  /// Call only after a care action succeeds, including its normal cost.
  /// Repeating one action never advances a combo or the five-action checklist.
  Future<int> recordCare(String petId, String action) {
    if (petId.trim().isEmpty || !careActions.contains(action)) {
      throw ArgumentError('A pet ID and a supported care action are required.');
    }
    return _mutate(() {
      final now = _now();
      final record = (_days[_dayKey(now)] ??= {})[petId] ??= _CareRecord();
      record.actions.add(action);
      record.recent.removeWhere((_, at) => !_withinWindow(at, now));
      record.recent[action] = now;
      if (!record.comboClaimed && record.recent.length >= 3) {
        record.comboClaimed = true;
        return comboRewardCoins;
      }
      return 0;
    });
  }

  Future<int> claimDailyReward(String petId) => _mutate(() {
        final record = _days[_dayKey(_now())]?[petId];
        if (record == null ||
            record.dailyClaimed ||
            !record.actions.containsAll(careActions)) {
          return 0;
        }
        record.dailyClaimed = true;
        return dailyRewardCoins;
      });

  /// Birthdays use the saved adoption month/day, starting one year later.
  /// February 29 pets celebrate on their next actual February 29.
  PetBirthday birthdayFor(Pet pet) {
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    final adopted = pet.createdAt.toLocal();
    var year = now.year > adopted.year ? now.year : adopted.year + 1;
    late DateTime birthday;
    while (true) {
      birthday = DateTime(year, adopted.month, adopted.day);
      if (birthday.month == adopted.month &&
          birthday.day == adopted.day &&
          !birthday.isBefore(today)) {
        break;
      }
      year++;
    }
    return PetBirthday(
      pet: pet,
      date: birthday,
      age: birthday.year - adopted.year,
      daysUntil: DateTime.utc(birthday.year, birthday.month, birthday.day)
          .difference(DateTime.utc(today.year, today.month, today.day))
          .inDays,
      celebrated: _birthdayClaims.contains('${pet.id}:$year'),
    );
  }

  List<PetBirthday> birthdaysFor(Iterable<Pet> pets) =>
      pets.map(birthdayFor).toList()..sort((a, b) => a.date.compareTo(b.date));

  Future<int> celebrateBirthday(Pet pet) => _mutate(() {
        final birthday = birthdayFor(pet);
        if (pet.id.trim().isEmpty || !birthday.canCelebrate) return 0;
        _birthdayClaims.add('${pet.id}:${birthday.date.year}');
        return birthdayRewardCoins;
      });

  /// Refresh an open journal after midnight or after a combo timer expires.
  void refresh() => _notify();

  Set<String> _recentActions(_CareRecord record, DateTime now) =>
      record.recent.entries
          .where((entry) => _withinWindow(entry.value, now))
          .map((entry) => entry.key)
          .toSet();

  bool _withinWindow(DateTime at, DateTime now) {
    final age = now.difference(at);
    return !age.isNegative && age <= comboWindow;
  }

  // Serialize rapid taps/claims so two concurrent callers cannot earn twice.
  // Restore the in-memory journal if persistence fails, allowing a retry.
  Future<T> _mutate<T>(T Function() operation) async {
    await initialize();
    final result = _pending.then((_) async {
      final previous = _toJson();
      try {
        final value = operation();
        final saved = await _preferences!.setString(
          preferenceKey,
          jsonEncode(_toJson()),
        );
        if (!saved) throw StateError('Could not save the care journal.');
        _notify();
        return value;
      } catch (_) {
        _restore(previous);
        rethrow;
      }
    });
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Map<String, dynamic> _toJson() => {
        'days': _days.map((day, pets) => MapEntry(
              day,
              pets.map((id, record) => MapEntry(id, record.toJson())),
            )),
        'birthdays': _birthdayClaims.toList(),
      };

  void _restore(dynamic value) {
    _days.clear();
    _birthdayClaims.clear();
    if (value is! Map) return;
    final days = value['days'];
    if (days is Map) {
      for (final day in days.entries) {
        if (day.key is! String || day.value is! Map) continue;
        final pets = <String, _CareRecord>{};
        for (final pet in (day.value as Map).entries) {
          if (pet.key is String && pet.value is Map) {
            pets[pet.key as String] = _CareRecord.fromJson(pet.value as Map);
          }
        }
        _days[day.key as String] = pets;
      }
    }
    final birthdays = value['birthdays'];
    if (birthdays is List) {
      _birthdayClaims.addAll(birthdays.whereType<String>());
    }
  }

  static String _dayKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class _CareRecord {
  final Set<String> actions;
  final Map<String, DateTime> recent;
  bool comboClaimed;
  bool dailyClaimed;

  _CareRecord({
    Set<String>? actions,
    Map<String, DateTime>? recent,
    this.comboClaimed = false,
    this.dailyClaimed = false,
  })  : actions = actions ?? {},
        recent = recent ?? {};

  factory _CareRecord.fromJson(Map value) {
    final actions = value['actions'];
    final savedRecent = value['recent'];
    final recent = <String, DateTime>{};
    if (savedRecent is Map) {
      for (final entry in savedRecent.entries) {
        if (!CareProgressService.careActions.contains(entry.key) ||
            entry.value is! String) {
          continue;
        }
        final at = DateTime.tryParse(entry.value as String);
        if (at != null) recent[entry.key as String] = at;
      }
    }
    return _CareRecord(
      actions: actions is List
          ? actions
              .whereType<String>()
              .where(CareProgressService.careActions.contains)
              .toSet()
          : {},
      recent: recent,
      comboClaimed: value['comboClaimed'] == true,
      dailyClaimed: value['dailyClaimed'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'actions': actions.toList(),
        'recent':
            recent.map((action, at) => MapEntry(action, at.toIso8601String())),
        'comboClaimed': comboClaimed,
        'dailyClaimed': dailyClaimed,
      };
}
