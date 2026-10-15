import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zona_pets/widgets/audio_credits_page.dart';

void main() {
  testWidgets('lists every real animal recording and license', (tester) async {
    expect(
      animalSoundCredits.map((credit) => credit.species),
      ['Cat', 'Dog', 'Bunny', 'Fox', 'Panda', 'Bird'],
    );
    expect(
      animalSoundCredits.map((credit) => credit.license),
      [
        'CC0 1.0',
        'CC0 1.0',
        'CC0 1.0',
        'CC BY-SA 4.0',
        'Public domain',
        'CC BY 4.0',
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(home: AnimalSoundCreditsPage()),
    );

    expect(find.text('Animal Sound Credits'), findsOneWidget);
    expect(find.text('Cat'), findsOneWidget);
    expect(find.text('Dog'), findsOneWidget);
  });
}
