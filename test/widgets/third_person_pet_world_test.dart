import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    expect(find.byKey(const ValueKey('world-mini-map')), findsOneWidget);
    expect(find.byKey(const ValueKey('desktop-3d-controls')), findsOneWidget);
    expect(find.textContaining('WASD move'), findsOneWidget);
    expect(find.textContaining('walk into bowl'), findsOneWidget);
    expect(find.text('WORLD MAP • E / ACTION'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('world-place-vetClinic')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('world-place-petBed')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('world-place-toyYard')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('world-place-gameStation')),
      findsOneWidget,
    );
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

  testWidgets('pet moves while nearby scenery stays fixed', (tester) async {
    await tester.pumpWidget(_worldHarness(PetType.cat, const Size(1000, 650)));
    await tester.pump(const Duration(milliseconds: 20));

    final pet = find.byKey(const ValueKey('world-pet-position'));
    final bowl = find.byKey(const ValueKey('world-food-bowl-position'));
    final petBefore = tester.getTopLeft(pet);
    final bowlBefore = tester.getTopLeft(bowl);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyW);
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyW);

    final petAfter = tester.getTopLeft(pet);
    final bowlAfter = tester.getTopLeft(bowl);
    expect((petAfter - petBefore).distance, greaterThan(10));
    expect((bowlAfter - bowlBefore).distance, lessThan(0.01));
  });

  testWidgets('companions are smaller and can be tapped to select',
      (tester) async {
    final companion = Pet(id: 'buddy', name: 'Buddy', type: PetType.dog);
    Pet? selected;
    await tester.pumpWidget(
      _worldHarness(
        PetType.cat,
        const Size(1000, 650),
        companionPets: [companion],
        onSelectPet: (pet) => selected = pet,
      ),
    );
    await tester.pump(const Duration(milliseconds: 20));

    final activePet = find.byKey(const ValueKey('world-pet-position'));
    final companionPet =
        find.byKey(ValueKey('world-companion-${companion.id}'));
    expect(companionPet, findsOneWidget);
    expect(
      tester.getSize(activePet).width,
      greaterThan(tester.getSize(companionPet).width),
    );

    await tester.tap(companionPet);
    expect(selected, same(companion));
  });

  testWidgets('birds receive dedicated vertical flight controls',
      (tester) async {
    await tester.pumpWidget(_worldHarness(PetType.bird, const Size(430, 720)));
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.text('FLY UP'), findsOneWidget);
    expect(find.text('FLY DOWN'), findsOneWidget);
  });
}

Widget _worldHarness(
  PetType type,
  Size size, {
  List<Pet> companionPets = const [],
  ValueChanged<Pet>? onSelectPet,
}) {
  final pet = Pet(name: type.name, type: type);
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox.fromSize(
          size: size,
          child: ThirdPersonPetWorld(
            pet: pet,
            companionPets: companionPets,
            onSelectPet: onSelectPet,
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
