import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zona_pets/models/pet.dart';
import 'package:zona_pets/widgets/third_person_pet_world.dart';

void main() {
  testWidgets('desktop yard shows XYZ coordinates and keyboard controls',
      (tester) async {
    await tester
        .pumpWidget(_worldHarness(PetType.elephant, const Size(1000, 650)));
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.byKey(const ValueKey('world-coordinate-hud')), findsOneWidget);
    expect(find.byKey(const ValueKey('desktop-3d-controls')), findsOneWidget);
    expect(find.textContaining('WASD move'), findsOneWidget);
    expect(find.textContaining('X  +0.00'), findsOneWidget);
    expect(find.bySemanticsLabel('Baby Elephant, happy mood'), findsOneWidget);
  });

  testWidgets('mobile yard exposes touch movement and action controls',
      (tester) async {
    await tester.pumpWidget(_worldHarness(PetType.cat, const Size(430, 720)));
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.byKey(const ValueKey('mobile-move-control')), findsOneWidget);
    expect(find.byKey(const ValueKey('mobile-jump-fly')), findsOneWidget);
    expect(find.byKey(const ValueKey('mobile-world-action')), findsOneWidget);
    expect(find.byKey(const ValueKey('desktop-3d-controls')), findsNothing);
  });

  testWidgets('birds receive dedicated vertical flight controls',
      (tester) async {
    await tester.pumpWidget(_worldHarness(PetType.bird, const Size(430, 720)));
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.text('FLY UP'), findsOneWidget);
    expect(find.text('FLY DOWN'), findsOneWidget);
  });
}

Widget _worldHarness(PetType type, Size size) {
  final pet = Pet(name: type.name, type: type);
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox.fromSize(
          size: size,
          child: ThirdPersonPetWorld(
            pet: pet,
            petAgeAsset: 'assets/images/pet_3d_age_${type.name}_v26_10.png',
            petMoodAsset: 'assets/images/pet_3d_moods_${type.name}_v26_10.png',
            moodAtlasRows: type == PetType.dog || type == PetType.fox ? 1 : 5,
            reactionAnimation: const AlwaysStoppedAnimation(0),
            onEat: () {},
            onPetTap: () {},
            onPetSecret: () {},
          ),
        ),
      ),
    ),
  );
}
