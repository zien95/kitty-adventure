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
}
