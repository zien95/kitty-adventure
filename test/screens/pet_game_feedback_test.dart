import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zona_pets/models/pet.dart';
import 'package:zona_pets/providers/game_provider.dart';
import 'package:zona_pets/screens/pet_game_screen.dart';
import 'package:zona_pets/services/sound_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final haptics = <Object?>[];
  final sound = SoundService();

  setUp(() {
    sound.setSoundEnabled(false);
    sound.setVibrationEnabled(true);
    haptics.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        haptics.add(call.arguments);
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
    sound.setSoundEnabled(true);
    sound.setVibrationEnabled(true);
  });

  testWidgets('new pet adoption finishes daily reward before starting the tour',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final provider = GameProvider();
    await _pumpGame(tester, provider);

    expect(find.text('Pick Your Pet'), findsOneWidget);
    await tester.tap(find.text('🐱 Cat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));

    expect(find.text('Day 1 Streak'), findsOneWidget);
    expect(find.text('Meet Your Pet'), findsNothing);
    expect(provider.pet?.type, PetType.cat);

    await tester.tap(find.text('Claimed'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.text('Day 1 Streak'), findsNothing);
    expect(find.text('Meet Your Pet'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pump();
    expect(
        (await SharedPreferences.getInstance())
            .getInt('zonaPetsGameTutorialRevision'),
        2);
    expect(tester.takeException(), isNull);
    await _disposeGame(tester, provider);
  });

  testWidgets('care feedback follows vibration preference without muting care',
      (tester) async {
    final pet = Pet(id: 'feedback-pet', name: 'Mochi', type: PetType.cat)
      ..hunger = 80;
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'kittyCatCollection': jsonEncode([pet.toJson()]),
      'selectedKittyCatIndex': 0,
      'dailyStreakDate': '${now.year}-${now.month}-${now.day}',
      'dailyStreakCount': 1,
      'zonaPetsGameTutorialRevision': 2,
    });
    final provider = GameProvider();
    await _pumpGame(tester, provider);

    await tester.tap(find.text('FOOD'));
    await tester.pump();
    expect(provider.pet?.hunger, 55);
    expect(haptics, contains('HapticFeedbackType.lightImpact'));

    haptics.clear();
    sound.setVibrationEnabled(false);
    await tester.tap(find.text('FOOD'));
    await tester.pump();
    expect(provider.pet?.hunger, 30);
    expect(haptics, isEmpty);
    expect(find.text('3rd Anniversary'), findsNothing);
    await tester.longPress(find.textContaining('Age 0d'));
    await tester.pump();
    final preferences = await SharedPreferences.getInstance();
    expect(jsonDecode(preferences.getString('foundEasterEggs')!),
        contains('growth'));
    expect(tester.takeException(), isNull);
    await _disposeGame(tester, provider);
  });
}

Future<void> _pumpGame(WidgetTester tester, GameProvider provider) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<GameProvider>.value(
      value: provider,
      child: const MaterialApp(home: PetGameScreen()),
    ),
  );
  await tester.pump();
}

Future<void> _disposeGame(WidgetTester tester, GameProvider provider) async {
  await tester.pumpWidget(const SizedBox.shrink());
  provider.dispose();
}
