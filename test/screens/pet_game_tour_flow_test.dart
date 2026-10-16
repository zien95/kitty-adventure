import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zona_pets/models/pet.dart';
import 'package:zona_pets/providers/game_provider.dart';
import 'package:zona_pets/screens/pet_game_screen.dart';
import 'package:zona_pets/services/update_service.dart';
import 'package:zona_pets/widgets/app_wrapper.dart';
import 'package:zona_pets/widgets/game_tutorial_overlay.dart';
import 'package:zona_pets/widgets/whats_new_dialog.dart';

const _tutorialPreferenceKey = 'zonaPetsGameTutorialRevision';
const _tutorialRevision = 3;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first run opens the guided tour and saves its revision',
      (tester) async {
    final pet = Pet(id: 'tour-pet', name: 'Mochi', type: PetType.cat);
    SharedPreferences.setMockInitialValues({
      'kittyCatCollection': jsonEncode([pet.toJson()]),
      'selectedKittyCatIndex': 0,
      'dailyStreakDate': _todayKey(),
      'dailyStreakCount': 1,
    });

    final provider = GameProvider();
    await _pumpGame(tester, provider);

    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Meet Your Pet'), findsOneWidget);
    expect(find.text('Step 1 of 10'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pump();

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getInt(_tutorialPreferenceKey),
      _tutorialRevision,
    );
    expect(find.text('Meet Your Pet'), findsNothing);
    expect(tester.takeException(), isNull);

    await _disposeGame(tester, provider);
  });

  testWidgets('Settings How to Play replays an already-seen tour',
      (tester) async {
    final pet = Pet(id: 'returning-pet', name: 'Bean', type: PetType.dog);
    SharedPreferences.setMockInitialValues({
      'kittyCatCollection': jsonEncode([pet.toJson()]),
      'selectedKittyCatIndex': 0,
      'dailyStreakDate': _todayKey(),
      'dailyStreakCount': 1,
      _tutorialPreferenceKey: _tutorialRevision,
    });

    final provider = GameProvider();
    await _pumpGame(tester, provider);

    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Meet Your Pet'), findsNothing);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();

    expect(find.text('Settings'), findsOneWidget);
    final replayAction = find.text('How to Play');
    await tester.ensureVisible(replayAction);
    await tester.tap(replayAction);
    await tester.pump();
    await tester.pump();

    expect(find.text('Meet Your Pet'), findsOneWidget);
    expect(find.text('Step 1 of 10'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _disposeGame(tester, provider);
  });

  testWidgets(
      'fresh app finishes all ten tour steps, remembers completion, and replays from Settings',
      (tester) async {
    // Start without a saved pet, tutorial revision, streak, or release notes.
    // Disable device audio only; exercise the actual first-run UI sequence.
    SharedPreferences.setMockInitialValues({
      'soundEnabled': false,
      'musicEnabled': false,
      'vibrationEnabled': false,
    });
    final provider = GameProvider();
    await provider.loadGame();
    await _pumpGame(tester, provider, withAppWrapper: true);

    expect(find.byType(WhatsNewDialog), findsOneWidget);
    await tester.tap(find.text("Let's Play!"));
    await tester.pump();
    expect(find.byType(WhatsNewDialog), findsNothing);
    expect(find.text('Pick Your Pet'), findsOneWidget);
    expect(find.byType(GameTutorialOverlay), findsNothing);

    await tester.tap(find.text('${PetType.cat.emoji} ${PetType.cat.name}'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Day 1 Streak'), findsOneWidget);
    expect(find.byType(GameTutorialOverlay), findsNothing);

    await tester.tap(find.text('Claimed'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.text('Meet Your Pet'), findsOneWidget);
    await _finishAllTourSteps(tester);

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getInt(_tutorialPreferenceKey), _tutorialRevision);
    expect(preferences.getString('lastWhatsNewVersion'),
        UpdateService.currentVersion);
    expect(preferences.getString('kittyCatCollection'), isNotNull);
    expect(find.byType(GameTutorialOverlay), findsNothing);
    expect(tester.takeException(), isNull);
    await _disposeGame(tester, provider);

    // A new provider and route use the saved preferences, as a relaunch would.
    final returningProvider = GameProvider();
    await returningProvider.loadGame();
    await _pumpGame(tester, returningProvider, withAppWrapper: true);
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump();
    expect(find.byType(WhatsNewDialog), findsNothing);
    expect(find.byType(GameTutorialOverlay), findsNothing);
    expect(find.text('Pick Your Pet'), findsNothing);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();
    final replayAction = find.text('How to Play');
    await tester.ensureVisible(replayAction);
    await tester.tap(replayAction);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await _finishAllTourSteps(tester);
    expect(preferences.getInt(_tutorialPreferenceKey), _tutorialRevision);
    expect(find.byType(GameTutorialOverlay), findsNothing);
    expect(tester.takeException(), isNull);
    await _disposeGame(tester, returningProvider);
  });
}

Future<void> _finishAllTourSteps(WidgetTester tester) async {
  // A Settings replay begins in a post-frame callback; render the measured
  // spotlight on the following frame before asserting its geometry.
  await tester.pump();
  const titles = [
    'Meet Your Pet',
    'Choose Your Pet',
    'Read The Need Meters',
    'Follow The Next Suggestion',
    'Food Lowers Hunger',
    'Toy Raises Happiness',
    'Clean Restores Care',
    'Rest, Grow, And Heal',
    'Open The Pet Hub',
    'Settings And Help',
  ];

  for (var index = 0; index < titles.length; index++) {
    expect(find.text(titles[index]), findsOneWidget);
    expect(find.text('Step ${index + 1} of 10'), findsOneWidget);
    expect(find.byKey(const ValueKey('game-tour-highlight')), findsOneWidget,
        reason: 'Highlight missing at step ${index + 1}: ${titles[index]}');
    final action = find.descendant(
      of: find.byType(GameTutorialOverlay),
      matching: find.text(index == titles.length - 1 ? 'Finish' : 'Next'),
    );
    await tester.ensureVisible(action);
    await tester.pump();
    await tester.tap(action);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(tester.takeException(), isNull);
  }
}

Future<void> _pumpGame(WidgetTester tester, GameProvider provider,
    {bool withAppWrapper = false}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<GameProvider>.value(
      value: provider,
      child: MaterialApp(
        home: withAppWrapper
            ? const AppWrapper(child: PetGameScreen())
            : const PetGameScreen(),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _disposeGame(WidgetTester tester, GameProvider provider) async {
  await tester.pumpWidget(const SizedBox.shrink());
  provider.dispose();
}

String _todayKey() {
  final now = DateTime.now();
  return '${now.year}-${now.month}-${now.day}';
}
