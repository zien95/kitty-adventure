import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zona_pets/services/sound_service.dart';

class _Player extends Fake implements AudioPlayer {
  final List<String> assets = [];
  double volume = 0;
  int stops = 0;
  ReleaseMode? configuredReleaseMode;

  @override
  Future<void> play(Source source,
      {double? volume,
      double? balance,
      AudioContext? ctx,
      Duration? position,
      PlayerMode? mode}) async {
    assets.add((source as AssetSource).path);
    this.volume = volume ?? this.volume;
  }

  @override
  Future<void> setVolume(double volume) async => this.volume = volume;
  @override
  Future<void> setReleaseMode(ReleaseMode mode) async =>
      configuredReleaseMode = mode;
  @override
  Future<void> stop() async {
    stops++;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, _Player> players;
  late SoundService sounds;
  setUp(() {
    players = {};
    sounds =
        SoundService.forTesting(createPlayer: (id) => players[id] = _Player());
    sounds.setVibrationEnabled(false);
  });
  tearDown(() => sounds.dispose());

  test('themes use distinct assets, with independent effects volume', () async {
    sounds.setMusicEnabled(false);
    sounds.setEffectsVolume(.5);
    for (final pack in ['cute', 'soft', 'arcade']) {
      sounds.setSoundPack(pack);
      await sounds.playSound('feed');
    }
    expect(players.values.map((p) => p.assets.single), [
      'sounds/cute/feed.wav',
      'sounds/soft/feed.wav',
      'sounds/arcade/feed.wav',
    ]);
    expect(players.values.last.volume, .5);
    sounds.setSoundEnabled(false);
    await sounds.playSound('clean');
    expect(players.values.expand((p) => p.assets).length, 3);
  });

  test('music follows mood, respects override and master mute', () async {
    sounds.setMusicEnabled(true, userInitiated: false);
    await sounds.playBackgroundMusic();
    expect(players, isEmpty, reason: 'Do not autoplay before an interaction');
    await sounds.playSound('click');
    await sounds.playBackgroundMusic();
    final music = players['zona_pets_music']!;
    expect(music.assets.last, 'music/main_theme.wav');
    expect(music.configuredReleaseMode, ReleaseMode.loop);
    sounds.setMood('sleepy');
    await sounds.playBackgroundMusic();
    expect(music.assets.last, 'music/night_mode.wav');
    sounds.setMusicTrack('release_day');
    sounds.setMood('loving');
    await sounds.playBackgroundMusic();
    expect(music.assets.last, 'music/release_day.wav');
    sounds.setMusicVolume(.1);
    await sounds.playBackgroundMusic();
    expect(music.volume, .1);
    final plays = music.assets.length;
    sounds.setSoundEnabled(false);
    await sounds.stopBackgroundMusic();
    await sounds.playSound('feed');
    expect(music.assets.length, plays);
    expect(music.stops, greaterThan(0));
  });

  test('backgrounding stops audio and resuming preserves music setting',
      () async {
    await sounds.playSound('click');
    await sounds.playBackgroundMusic();
    final music = players['zona_pets_music']!;
    sounds.didChangeAppLifecycleState(AppLifecycleState.paused);
    await sounds.stopBackgroundMusic();
    final plays = music.assets.length;
    await sounds.playSound('reward');
    expect(music.assets.length, plays);
    sounds.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await sounds.playBackgroundMusic();
    expect(music.assets.length, greaterThan(plays));
    sounds.setMusicEnabled(false);
    await sounds.stopBackgroundMusic();
    final stoppedPlays = music.assets.length;
    sounds.didChangeAppLifecycleState(AppLifecycleState.paused);
    sounds.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await sounds.playBackgroundMusic();
    expect(music.assets.length, stoppedPlays);
  });
}
