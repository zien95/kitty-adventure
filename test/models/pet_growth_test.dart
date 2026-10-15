import 'package:flutter_test/flutter_test.dart';
import 'package:zona_pets/models/pet.dart';

void main() {
  test('age counts calendar days and clamps future adoption dates', () {
    final pet = Pet(
        name: 'Bean',
        type: PetType.dog,
        createdAt: DateTime(2026, 10, 14, 23, 59));
    expect(pet.ageInDaysAt(DateTime(2026, 10, 15, 0, 1)), 1);
    expect(pet.ageInDaysAt(DateTime(2026, 10, 13)), 0);
  });

  test('age evolution catches up and never repeats bonuses or regresses', () {
    final pet =
        Pet(name: 'Bean', type: PetType.dog, createdAt: DateTime(2026, 1, 1));
    pet.updateGrowth(now: DateTime(2026, 1, 8));
    expect(pet.evolutionStage, EvolutionStage.adult);
    final intelligence = pet.intelligence;
    pet.updateGrowth(now: DateTime(2026, 1, 8));
    pet.updateGrowth(now: DateTime(2026, 1, 2));
    expect(pet.evolutionStage, EvolutionStage.adult);
    expect(pet.intelligence, intelligence);
    pet.updateGrowth(now: DateTime(2026, 1, 31));
    expect(pet.evolutionStage, EvolutionStage.elder);
    final restored = Pet.fromJson(pet.toJson());
    expect(restored.evolutionStage, EvolutionStage.elder);
    expect(restored.createdAt, pet.createdAt);
  });

  test('levels can evolve a new pet ahead of calendar age', () {
    final pet = Pet(name: 'Bean', type: PetType.dog, level: 35);
    pet.updateGrowth();
    expect(pet.evolutionStage, EvolutionStage.adult);
  });
}
