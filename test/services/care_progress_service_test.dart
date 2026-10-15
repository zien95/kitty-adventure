import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zona_pets/models/pet.dart';
import 'package:zona_pets/services/care_progress_service.dart';
import 'package:zona_pets/widgets/care_journal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;
  late CareProgressService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    now = DateTime(2026, 10, 15, 12);
    service = CareProgressService(now: () => now);
    await service.initialize();
  });

  tearDown(() => service.dispose());

  test('combo requires three distinct actions in one rolling minute', () async {
    expect(await service.recordCare('a', 'feed'), 0);
    expect(await service.recordCare('a', 'feed'), 0);
    now = now.add(const Duration(seconds: 61));
    expect(await service.recordCare('a', 'play'), 0);
    expect(await service.recordCare('a', 'clean'), 0);
    expect(service.progressFor('a').comboProgress, 2);
    expect(await service.recordCare('a', 'rest'), 30);
    expect(await service.recordCare('a', 'bond'), 0);
    expect(service.progressFor('a').comboRewardEarned, isTrue);
  });

  test('daily checklist cannot be claimed early or by another pet', () async {
    for (final action in ['feed', 'play', 'clean', 'rest']) {
      await service.recordCare('a', action);
    }
    expect(await service.claimDailyReward('a'), 0);
    await service.recordCare('b', 'bond');
    expect(await service.claimDailyReward('a'), 0);
    await service.recordCare('a', 'bond');
    expect(service.progressFor('a').canClaimDailyReward, isTrue);
    expect(await service.claimDailyReward('a'), 100);
    expect(await service.claimDailyReward('a'), 0);
    expect(await service.claimDailyReward('b'), 0);
  });

  test('concurrent care and claims award each reward only once', () async {
    final rewards = await Future.wait(CareProgressService.careActions
        .map((action) => service.recordCare('a', action)));
    expect(rewards.fold<int>(0, (sum, value) => sum + value), 30);
    final claims = await Future.wait([
      service.claimDailyReward('a'),
      service.claimDailyReward('a'),
    ]);
    expect(claims, [100, 0]);
  });

  test('reopening keeps progress and claimed rewards; next day starts fresh',
      () async {
    for (final action in CareProgressService.careActions) {
      await service.recordCare('a', action);
    }
    await service.claimDailyReward('a');
    service.dispose();
    service = CareProgressService(now: () => now);
    await service.initialize();
    expect(service.progressFor('a').dailyRewardClaimed, isTrue);
    expect(service.progressFor('a').comboRewardEarned, isTrue);
    expect(await service.recordCare('a', 'feed'), 0);
    now = DateTime(2026, 10, 16);
    expect(service.progressFor('a').completedActions, isEmpty);
    expect(await service.claimDailyReward('a'), 0);
    for (final action in ['feed', 'play']) {
      expect(await service.recordCare('a', action), 0);
    }
    expect(await service.recordCare('a', 'clean'), 30);
    now = DateTime(2026, 10, 15, 15);
    expect(await service.claimDailyReward('a'), 0);
  });

  test('combo timestamps survive reopening and expire', () async {
    await service.recordCare('a', 'feed');
    await service.recordCare('a', 'play');
    service.dispose();
    now = now.add(const Duration(seconds: 61));
    service = CareProgressService(now: () => now);
    await service.initialize();
    expect(service.progressFor('a').comboProgress, 0);
    expect(await service.recordCare('a', 'clean'), 0);
  });

  test('birthday rewards are once yearly and never on adoption day', () async {
    final pet = Pet(
      id: 'birthday-pet',
      name: 'Mochi',
      type: PetType.cat,
      createdAt: DateTime(2026, 10, 15),
    );
    expect(service.birthdayFor(pet).date, DateTime(2027, 10, 15));
    expect(await service.celebrateBirthday(pet), 0);
    now = DateTime(2027, 10, 14);
    expect(await service.celebrateBirthday(pet), 0);
    now = DateTime(2027, 10, 15);
    expect(service.birthdayFor(pet).age, 1);
    expect(await service.celebrateBirthday(pet), 150);
    service.dispose();
    service = CareProgressService(now: () => now);
    await service.initialize();
    expect(await service.celebrateBirthday(pet), 0);
    now = DateTime(2028, 10, 15);
    expect(await service.celebrateBirthday(pet), 150);
  });

  test('birthday calendar sorts family and preserves leap-day birthdays', () {
    final leapPet = Pet(
      id: 'leap',
      name: 'Leap',
      type: PetType.bunny,
      createdAt: DateTime(2024, 2, 29),
    );
    final tomorrowPet = Pet(
      id: 'tomorrow',
      name: 'Bean',
      type: PetType.dog,
      createdAt: DateTime(2025, 10, 16),
    );
    final birthdays = service.birthdaysFor([leapPet, tomorrowPet]);
    expect(birthdays.first.pet.id, 'tomorrow');
    expect(birthdays.first.daysUntil, 1);
    expect(birthdays.last.date, DateTime(2028, 2, 29));
    now = DateTime(2028, 2, 29);
    expect(service.birthdayFor(leapPet).isToday, isTrue);
  });

  test('invalid saved data does not block a fresh journal', () async {
    service.dispose();
    SharedPreferences.setMockInitialValues({
      CareProgressService.preferenceKey: '{invalid json',
    });
    service = CareProgressService(now: () => now);
    await service.initialize();
    expect(service.progressFor('a').completedActions, isEmpty);
    expect(await service.recordCare('a', 'feed'), 0);
  });

  test('unrecognized care actions do not fill the checklist', () {
    expect(() => service.recordCare('a', 'free-coins'), throwsArgumentError);
    expect(() => service.recordCare('', 'feed'), throwsArgumentError);
  });

  testWidgets(
      'journal fits a narrow screen and shows care and birthday rewards',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final pet = Pet(
      id: 'a',
      name: 'Birthday Mochi',
      type: PetType.cat,
      createdAt: DateTime(2025, 10, 15),
    );
    await tester.runAsync(() async {
      for (final action in CareProgressService.careActions) {
        await service.recordCare('a', action);
      }
    });
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: CareJournal(
              pets: [pet],
              service: service,
              activePetId: 'a',
              onReward: (petId, coins) async {},
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Claim 100 coins'));
    expect(find.text('Claim 100 coins'), findsOneWidget);
    expect(find.text('Birthday Mochi’s Daily Care'), findsOneWidget);
    expect(service.progressFor('a').canClaimDailyReward, isTrue);
    await tester.ensureVisible(find.text('Celebrate +150 coins'));
    expect(find.text('Celebrate +150 coins'), findsOneWidget);
    expect(find.text('🎂 Turns 1 today!'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
