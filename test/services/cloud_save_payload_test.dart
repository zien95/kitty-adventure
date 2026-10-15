import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zona_pets/services/cloud_save_service.dart';
import 'package:zona_pets/models/pet.dart';
import 'package:zona_pets/providers/game_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('snapshot includes game progress and excludes account credentials',
      () async {
    SharedPreferences.setMockInitialValues({
      'kittyCatCollection': '[]',
      'dailyStreakCount': 3,
      'zonaPetsCareProgressV1': '{}',
      'musicVolume': 0.25,
      'user_account': 'private legacy profile',
      'cloudSaveOwner': 'private uid',
      'kitty_update_manifest_url': 'https://example.test',
    });
    final snapshot =
        CloudSaveService.snapshot(await SharedPreferences.getInstance());
    expect(
        snapshot.keys,
        unorderedEquals([
          'kittyCatCollection',
          'dailyStreakCount',
          'zonaPetsCareProgressV1',
          'musicVolume'
        ]));
    expect(CloudSaveService.validatePayload(jsonEncode(snapshot)), snapshot);
  });
  test('rejects malformed and oversized cloud data before restoring', () {
    for (final payload in [
      '[]',
      '{',
      '{"kittyCatCollection":"{}"}',
      '{"pet":"[]"}',
      '{"musicVolume":{}}'
    ]) {
      expect(() => CloudSaveService.validatePayload(payload),
          throwsFormatException);
    }
    expect(
        () =>
            CloudSaveService.validatePayload(jsonEncode({'pet': 'x' * 800001})),
        throwsFormatException);
  });
  test('unknown cloud keys cannot overwrite local authentication', () {
    expect(
        CloudSaveService.validatePayload(
            '{"cloudSaveOwner":"someone-else","user_account":"x"}'),
        isEmpty);
  });

  test('cloud snapshot preserves an incubating egg and its hatch deadline',
      () async {
    final egg = jsonEncode({
      'id': 'saved-egg',
      'species': PetType.fox.index,
      'startedAt': '2026-10-15T12:00:00.000',
      'readyAt': '2026-10-15T12:02:00.000',
    });
    SharedPreferences.setMockInitialValues({'petFiascoNestV1': egg});
    final snapshot =
        CloudSaveService.snapshot(await SharedPreferences.getInstance());
    final restored = CloudSaveService.validatePayload(jsonEncode(snapshot));
    expect(restored['petFiascoNestV1'], egg);
  });

  test('snapshot merges the freshest active pet into the saved family',
      () async {
    final pet = Pet(id: 'active', name: 'Bean', type: PetType.dog);
    final old = pet.toJson();
    pet.coins += 100;
    SharedPreferences.setMockInitialValues({
      'pet': jsonEncode(pet.toJson()),
      'kittyCatCollection': jsonEncode([old])
    });
    final data =
        CloudSaveService.snapshot(await SharedPreferences.getInstance());
    expect(jsonDecode(data['kittyCatCollection'])[0]['coins'], pet.coins);
  });

  test('loading a restored empty save clears the previous pet and scores',
      () async {
    SharedPreferences.setMockInitialValues({});
    final game = GameProvider();
    game.setPet(Pet(name: 'Bean', type: PetType.dog));
    await game.saveGame();
    game.globalStats['totalScore'] = 999;
    game.availableGames.first['highScore'] = 123;
    await (await SharedPreferences.getInstance()).remove('pet');
    await game.loadGame();
    expect(game.pet, isNull);
    expect(game.globalStats['totalScore'], 0);
    expect(game.availableGames.first['highScore'], 0);
    game.dispose();
  });
}
