import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zona_pets/widgets/game_tutorial_overlay.dart';

void main() {
  testWidgets('moves through tutorial steps and finishes', (tester) async {
    final rootKey = GlobalKey();
    final firstTargetKey = GlobalKey();
    final secondTargetKey = GlobalKey();
    var currentStep = 0;
    var finished = false;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            final steps = [
              GameTutorialStep(
                targetKey: firstTargetKey,
                icon: Icons.pets,
                accentColor: Colors.pink,
                title: 'Meet Your Pet',
                description: 'The pet reacts to care.',
                clickHint: 'Tap the pet after the tour.',
              ),
              GameTutorialStep(
                targetKey: secondTargetKey,
                icon: Icons.set_meal,
                accentColor: Colors.orange,
                title: 'Food Lowers Hunger',
                description: 'Lower hunger is better.',
                clickHint: 'Click FOOD when Hunger is high.',
              ),
            ];

            return Stack(
              key: rootKey,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    key: firstTargetKey,
                    width: 180,
                    height: 100,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    key: secondTargetKey,
                    width: 200,
                    height: 70,
                  ),
                ),
                Positioned.fill(
                  child: GameTutorialOverlay(
                    rootKey: rootKey,
                    steps: steps,
                    currentStep: currentStep,
                    onBack: () => setState(() => currentStep--),
                    onNext: () {
                      if (currentStep == steps.length - 1) {
                        finished = true;
                      } else {
                        setState(() => currentStep++);
                      }
                    },
                    onSkip: () {},
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    expect(find.text('Meet Your Pet'), findsOneWidget);
    expect(find.text('Step 1 of 2'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    await tester.pumpAndSettle();
    final highlight = find.byKey(const ValueKey('game-tour-highlight'));
    expect(
      tester.getRect(highlight),
      tester.getRect(find.byKey(firstTargetKey)).inflate(8),
    );

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Food Lowers Hunger'), findsOneWidget);
    expect(find.text('Step 2 of 2'), findsOneWidget);
    expect(find.text('Finish'), findsOneWidget);
    expect(
      tester.getRect(highlight),
      tester.getRect(find.byKey(secondTargetKey)).inflate(8),
    );

    await tester.tap(find.text('Finish'));
    await tester.pump();
    expect(finished, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('skip works without overflowing on a narrow phone',
      (tester) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final rootKey = GlobalKey();
    final targetKey = GlobalKey();
    var skipped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          key: rootKey,
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                key: targetKey,
                width: 350,
                height: 120,
              ),
            ),
            Positioned.fill(
              child: GameTutorialOverlay(
                rootKey: rootKey,
                steps: [
                  GameTutorialStep(
                    targetKey: targetKey,
                    icon: Icons.health_and_safety,
                    accentColor: Colors.blue,
                    title: 'Rest, Grow, And Heal',
                    description:
                        'Sleep restores Energy and Health. Train raises IQ and XP. Bond grows friendship and scenes.',
                    clickHint:
                        'Click the matching small button when a meter needs care.',
                  ),
                ],
                currentStep: 0,
                onBack: () {},
                onNext: () {},
                onSkip: () => skipped = true,
              ),
            ),
          ],
        ),
      ),
    );

    expect(find.text('Rest, Grow, And Heal'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Skip'));
    await tester.pump();
    expect(skipped, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('highlighted target stays clickable during the tour',
      (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final rootKey = GlobalKey();
    final targetKey = GlobalKey();
    var targetTaps = 0;
    var backgroundTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          key: rootKey,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => backgroundTaps++,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                key: targetKey,
                behavior: HitTestBehavior.opaque,
                onTap: () => targetTaps++,
                child: const SizedBox(width: 160, height: 72),
              ),
            ),
            Positioned.fill(
              child: GameTutorialOverlay(
                rootKey: rootKey,
                steps: [
                  GameTutorialStep(
                    targetKey: targetKey,
                    icon: Icons.set_meal,
                    accentColor: Colors.orange,
                    title: 'Food Lowers Hunger',
                    description: 'Food should remain tappable.',
                    clickHint: 'Tap FOOD to feed your pet.',
                  ),
                ],
                currentStep: 0,
                onBack: () {},
                onNext: () {},
                onSkip: () {},
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The target is measured after layout, even when no parent rebuilds.
    final highlight = find.byKey(const ValueKey('game-tour-highlight'));
    expect(highlight, findsOneWidget);
    expect(tester.getRect(highlight),
        tester.getRect(find.byKey(targetKey)).inflate(8));

    await tester.tapAt(const Offset(30, 560));
    expect(backgroundTaps, 0);

    await tester.tap(find.byKey(targetKey));
    await tester.pump();

    expect(targetTaps, 1);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(600, 400);
    await tester.pumpAndSettle();
    expect(
      tester.getRect(highlight),
      tester.getRect(find.byKey(targetKey)).inflate(8),
    );
    await tester.tap(find.byKey(targetKey));
    expect(targetTaps, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing target blocks the game while tour controls still work',
      (tester) async {
    final rootKey = GlobalKey();
    var backgroundTaps = 0;
    var finished = false;

    await tester.pumpWidget(MaterialApp(
      home: Stack(
        key: rootKey,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => backgroundTaps++,
            ),
          ),
          Positioned.fill(
            child: GameTutorialOverlay(
              rootKey: rootKey,
              steps: [_step(GlobalKey())],
              currentStep: 0,
              onBack: () {},
              onNext: () => finished = true,
              onSkip: () {},
            ),
          ),
        ],
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(30, 560));
    expect(backgroundTaps, 0);
    expect(find.byKey(const ValueKey('game-tour-highlight')), findsNothing);
    await tester.tap(find.text('Finish'));
    expect(finished, isTrue);
    expect(tester.takeException(), isNull);
  });

  for (final scenario in [
    (size: const Size(700, 280), textScale: 1.0),
    (size: const Size(320, 570), textScale: 3.0),
  ]) {
    testWidgets(
        'tour stays usable at ${scenario.size} and ${scenario.textScale}x text',
        (tester) async {
      tester.view.physicalSize = scenario.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final rootKey = GlobalKey();
      final targetKey = GlobalKey();
      var targetTaps = 0;
      var finished = false;

      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scenario.textScale),
          ),
          child: child!,
        ),
        home: Stack(
          key: rootKey,
          children: [
            Positioned(
              bottom: 0,
              left: 70,
              width: 160,
              height: 48,
              child: GestureDetector(
                key: targetKey,
                behavior: HitTestBehavior.opaque,
                onTap: () => targetTaps++,
              ),
            ),
            Positioned.fill(
              child: GameTutorialOverlay(
                rootKey: rootKey,
                steps: [_step(targetKey)],
                currentStep: 0,
                onBack: () {},
                onNext: () => finished = true,
                onSkip: () {},
              ),
            ),
          ],
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(targetKey));
      expect(targetTaps, 1);
      await tester.ensureVisible(find.text('Finish'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Finish'));
      expect(finished, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}

GameTutorialStep _step(GlobalKey targetKey) => GameTutorialStep(
      targetKey: targetKey,
      icon: Icons.health_and_safety,
      accentColor: Colors.blue,
      title: 'Rest, Grow, And Heal',
      description:
          'Sleep restores Energy and Health. Train raises IQ and XP. Bond grows friendship and scenes.',
      clickHint: 'Click the matching small button when a meter needs care.',
    );
