import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zona_pets/models/pet.dart';
import 'package:zona_pets/services/egg_nest_service.dart';
import 'package:zona_pets/widgets/egg_nest.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('incubation survives restarting and cannot hatch early', () async {
    var now = DateTime(2026, 10, 15, 12);
    final nest = EggNestService(now: () => now);
    await nest.start(PetType.fox);
    var adopted = 0;
    await nest.hatch((_, __) async {
      adopted++;
    });
    expect(adopted, 0);
    now = now.add(const Duration(seconds: 60));
    final restored = EggNestService(now: () => now);
    await restored.initialize();
    expect(restored.egg!.species, PetType.fox);
    expect(restored.remaining, const Duration(minutes: 1));
    now = now.add(const Duration(seconds: 60));
    expect(restored.ready, isTrue);
    await Future.wait([
      restored.hatch((species, id) async {
        expect(species, PetType.fox);
        adopted++;
      }),
      restored.hatch((_, __) async {
        adopted++;
      })
    ]);
    expect(adopted, 1);
    expect(restored.egg, isNull);
    expect(
        (await SharedPreferences.getInstance())
            .containsKey(EggNestService.preferenceKey),
        isFalse);
    nest.dispose();
    restored.dispose();
  });

  test('failed adoption keeps the same egg ID for a safe retry', () async {
    var now = DateTime(2026, 10, 15, 12);
    final nest = EggNestService(now: () => now);
    await nest.start(PetType.panda);
    now = now.add(EggNestService.incubation);
    String? attempted;
    await expectLater(nest.hatch((_, id) async {
      attempted = id;
      throw StateError('storage unavailable');
    }), throwsStateError);
    expect(nest.ready, isTrue);
    await nest.hatch((_, id) async {
      expect(id, attempted);
    });
    expect(nest.egg, isNull);
    nest.dispose();
  });

  test('one nest serializes concurrent start attempts', () async {
    final nest = EggNestService();
    await nest.start(PetType.bird);
    await expectLater(nest.start(PetType.cat), throwsStateError);
    expect(nest.egg!.species, PetType.bird);
    nest.dispose();
  });

  test('malformed saved eggs recover to an empty nest', () async {
    for (final value in [
      'broken',
      jsonEncode(
          {'id': 'egg', 'species': 99, 'startedAt': 'bad', 'readyAt': 'bad'})
    ]) {
      SharedPreferences.setMockInitialValues(
          {EggNestService.preferenceKey: value});
      final nest = EggNestService();
      await nest.initialize();
      expect(nest.egg, isNull);
      nest.dispose();
    }
  });

  testWidgets('nest shows countdown, enables hatch at zero, and adopts once',
      (tester) async {
    var now = DateTime(2026, 10, 15, 12);
    final nest = EggNestService(now: () => now);
    await nest.start(PetType.bunny);
    var adopted = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: EggNest(
                service: nest,
                onHatch: (_, __) async {
                  adopted++;
                }))));
    await tester.pump();
    expect(find.text('Hatches in 02:00'), findsOneWidget);
    now = now.add(EggNestService.incubation);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Ready to hatch!'), findsOneWidget);
    await tester.tap(find.text('Hatch & adopt Bunny'));
    await tester.pump();
    await tester.pump();
    expect(adopted, 1);
    expect(nest.egg, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    nest.dispose();
  });
}
