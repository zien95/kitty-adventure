import 'package:flutter_test/flutter_test.dart';
import 'package:zona_pets/gameplay/pet_world_simulation.dart';

void main() {
  test('ground pets move in X/Z space and land after jumping', () {
    final world = PetWorldSimulation(canFly: false);

    world.step(dt: 0.5, forward: 1, right: 1);
    expect(world.x, greaterThan(0));
    expect(world.z, greaterThan(0));

    expect(world.jumpOrFlap(), isTrue);
    world.step(dt: 0.05);
    expect(world.y, greaterThan(0));
    for (var index = 0; index < 80; index++) {
      world.step(dt: 0.05);
    }
    expect(world.y, 0);
  });

  test('birds climb, descend, and stay inside the flight ceiling', () {
    final world = PetWorldSimulation(canFly: true);

    for (var index = 0; index < 80; index++) {
      world.step(dt: 0.05, ascend: true);
    }
    expect(world.y, PetWorldSimulation.maxFlightHeight);

    for (var index = 0; index < 80; index++) {
      world.step(dt: 0.05, descend: true);
    }
    expect(world.y, 0);
  });

  test('landing on the food bowl triggers one eat event per approach', () {
    final world = PetWorldSimulation(
      canFly: false,
      x: PetWorldSimulation.foodX,
      z: PetWorldSimulation.foodZ,
    );

    world.jumpOrFlap();
    expect(world.step(dt: 0.05), isEmpty);
    expect(world.step(dt: 0.05), contains(PetWorldEvent.ateFood));
    expect(world.step(dt: 0.05), isNot(contains(PetWorldEvent.ateFood)));
  });

  test('walking a ground pet into the bowl steps up and eats', () {
    final world = PetWorldSimulation(
      canFly: false,
      x: PetWorldSimulation.foodX,
      z: PetWorldSimulation.foodZ - 1.1,
    );

    final events = <PetWorldEvent>{};
    for (var index = 0; index < 4; index++) {
      events.addAll(world.step(dt: 0.05, forward: 1));
    }

    expect(world.onFoodBowl, isTrue);
    expect(world.y, PetWorldSimulation.foodBowlHeight);
    expect(events, contains(PetWorldEvent.ateFood));
  });

  test('expanded yard contains every exploration landmark', () {
    expect(
      PetWorldSimulation.maxX - PetWorldSimulation.minX,
      greaterThanOrEqualTo(72),
    );
    expect(
      PetWorldSimulation.maxZ - PetWorldSimulation.minZ,
      greaterThanOrEqualTo(90),
    );
    expect(PetWorldSimulation.landmarks, hasLength(greaterThanOrEqualTo(9)));

    for (final landmark in PetWorldSimulation.landmarks) {
      expect(
          landmark.x,
          inInclusiveRange(
            PetWorldSimulation.minX,
            PetWorldSimulation.maxX,
          ));
      expect(
          landmark.z,
          inInclusiveRange(
            PetWorldSimulation.minZ,
            PetWorldSimulation.maxZ,
          ));
    }
  });

  test('every place can be used with the action command', () {
    for (final landmark in PetWorldSimulation.landmarks) {
      final world = PetWorldSimulation(
        canFly: false,
        x: landmark.x,
        z: landmark.z,
      );

      final result = world.performAction();
      expect(result, isNotNull, reason: landmark.label);
      expect(result!.landmark, same(landmark), reason: landmark.label);
      expect(result.isFoodBowl, isFalse, reason: landmark.label);
    }
  });
}
