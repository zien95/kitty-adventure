import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:vibration/vibration.dart';

class SoundService with WidgetsBindingObserver {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal()
      : _createPlayer = ((id) => AudioPlayer(playerId: id));

  @visibleForTesting
  SoundService.forTesting({required AudioPlayer Function(String) createPlayer})
      : _createPlayer = createPlayer;

  final AudioPlayer Function(String) _createPlayer;

  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _soundPack = 'classic';
  final List<AudioPlayer?> _sfxPlayers = List.filled(3, null);
  final List<Future<void>> _effectQueues =
      List.generate(3, (_) => Future<void>.value());
  AudioPlayer? _musicPlayer;
  Future<void> _musicQueue = Future<void>.value();
  int _nextEffect = 0;
  int _audioRevision = 0;
  int _musicRevision = 0;
  bool _observing = false;
  bool _suspended = false;
  bool _interacted = false;
  bool _musicEnabled = true;
  double _effectsVolume = 0.8;
  double _musicVolume = 0.25;
  String _musicTrack = 'auto';
  String _mood = 'happy';
  String? _playingMusic;

  static const musicTracks = <String, String>{
    'auto': 'Follow pet mood',
    'main_theme': 'Moon Garden',
    'kitty_hub': 'Pet Hub',
    'night_mode': 'Sleepy Stars',
    'mini_game': 'Playtime',
    'photo_booth': 'Best Friends',
    'release_day': 'Celebration',
  };

  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  String get soundPack => _soundPack;

  static const Set<String> _validSoundPacks = {
    'classic',
    'soft',
    'arcade',
    'quiet',
    'cute',
  };

  static const Map<String, String> _soundFiles = {
    'button_pop': 'button_pop.wav',
    'cat_meow': 'cat_meow.wav',
    'clean': 'clean.wav',
    'click': 'click.wav',
    'feed': 'feed.wav',
    'level_up': 'level_up.wav',
    'medicine': 'medicine.wav',
    'notification': 'notification.wav',
    'play': 'play.wav',
    'reward': 'reward.wav',
    'secret_code': 'secret_code.wav',
    'sleep': 'sleep.wav',
    'train': 'train.wav',
    'pet_cat': 'cat_meow.wav',
    'pet_dog': 'play.wav',
    'pet_bunny': 'button_pop.wav',
    'pet_fox': 'secret_code.wav',
    'pet_panda': 'sleep.wav',
    'pet_bird': 'notification.wav',
  };

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    _audioRevision++;
    if (!enabled) {
      unawaited(_stopEffects());
      unawaited(stopBackgroundMusic());
    } else if (_interacted) {
      unawaited(playBackgroundMusic());
    }
  }

  void setVibrationEnabled(bool enabled) {
    _vibrationEnabled = enabled;
  }

  void setSoundPack(String pack) {
    if (!_validSoundPacks.contains(pack)) return;
    _soundPack = pack;
  }

  void setEffectsVolume(double volume) {
    if (!volume.isFinite) return;
    _effectsVolume = volume.clamp(0, 1).toDouble();
    if (_effectsVolume == 0) {
      _audioRevision++;
      unawaited(_stopEffects());
    }
  }

  void setMusicVolume(double volume) {
    if (!volume.isFinite) return;
    _musicVolume = volume.clamp(0, 1).toDouble();
    if (_interacted) unawaited(playBackgroundMusic());
  }

  void setMusicEnabled(bool enabled, {bool userInitiated = true}) {
    _musicEnabled = enabled;
    if (enabled) {
      if (userInitiated) _interacted = true;
      if (_interacted) unawaited(playBackgroundMusic());
    } else {
      unawaited(stopBackgroundMusic());
    }
  }

  void setMusicTrack(String track) {
    if (!musicTracks.containsKey(track)) return;
    _musicTrack = track;
    if (_interacted) unawaited(playBackgroundMusic());
  }

  void setMood(String mood) {
    _mood = mood;
    if (_interacted && _musicTrack == 'auto') {
      unawaited(playBackgroundMusic());
    }
  }

  void _observeLifecycle() {
    if (_observing) return;
    WidgetsBinding.instance.addObserver(this);
    _observing = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _suspended = state != AppLifecycleState.resumed;
    if (_suspended) {
      _audioRevision++;
      unawaited(_stopEffects());
      unawaited(stopBackgroundMusic());
    } else if (_interacted) {
      unawaited(playBackgroundMusic());
    }
  }

  Future<void> playSound(String soundName) async {
    _observeLifecycle();
    _interacted = true;
    if (_suspended) return;
    unawaited(playBackgroundMusic());
    if (!_soundEnabled && !_vibrationEnabled) return;

    await Future.wait([
      if (_soundEnabled && _effectsVolume > 0) _playAssetSound(soundName),
      if (_vibrationEnabled) _triggerHapticFeedback(soundName),
    ]);

    await _triggerVisualFeedback(soundName);
  }

  Future<void> _playAssetSound(String soundName) async {
    final name = _soundFiles.containsKey(soundName) ? soundName : 'click';
    final theme = _soundPack == 'quiet' ? 'soft' : _soundPack;
    final asset = theme == 'classic'
        ? 'sounds/${_soundFiles[name]}'
        : 'sounds/$theme/$name.wav';
    final slot = _nextEffect++ % _sfxPlayers.length;
    final revision = _audioRevision;
    final volume = _effectsVolume * _packVolume;
    return _effectQueues[slot] = _effectQueues[slot].then((_) async {
      if (revision != _audioRevision || !_soundEnabled || _suspended) return;
      try {
        final player =
            _sfxPlayers[slot] ??= _createPlayer('zona_pets_sfx_$slot');
        await player.setReleaseMode(ReleaseMode.stop);
        await player.stop();
        if (revision != _audioRevision) return;
        await player.play(AssetSource(asset), volume: volume);
        if (revision != _audioRevision) await player.stop();
      } catch (_) {
        // Audio is best-effort; browsers can require another user gesture.
      }
    });
  }

  Future<void> _triggerVisualFeedback(String soundName) async {
    // Visual feedback placeholder - can be extended with visual cues
    // This provides accessibility for users who can't hear or feel vibrations
    switch (soundName) {
      case 'level_up':
        // Could trigger a visual celebration animation
        break;
      case 'notification':
        // Could trigger a visual notification
        break;
      default:
        // Subtle visual feedback
        break;
    }
  }

  Future<void> _triggerHapticFeedback(String soundName) async {
    await _triggerFlutterHapticFeedback(soundName);

    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        switch (soundName) {
          case 'feed':
          case 'play':
          case 'clean':
          case 'sleep':
          case 'train':
          case 'medicine':
            await Vibration.vibrate(duration: 50, amplitude: 100);
            break;
          case 'level_up':
            await Vibration.vibrate(pattern: [0, 100, 50, 100]);
            break;
          case 'notification':
            await Vibration.vibrate(duration: 200, amplitude: 150);
            break;
          case 'click':
          default:
            await Vibration.vibrate(duration: 25);
            break;
        }
      }
    } catch (e) {
      // Silently handle vibration errors
    }
  }

  Future<void> _triggerFlutterHapticFeedback(String soundName) async {
    try {
      switch (soundName) {
        case 'feed':
        case 'play':
        case 'clean':
        case 'sleep':
        case 'train':
        case 'medicine':
          await HapticFeedback.lightImpact();
          break;
        case 'level_up':
        case 'reward':
        case 'secret_code':
          await HapticFeedback.heavyImpact();
          break;
        case 'notification':
          await HapticFeedback.mediumImpact();
          break;
        case 'click':
        default:
          await HapticFeedback.selectionClick();
          break;
      }
    } catch (_) {
      // Haptics are best-effort and device-dependent.
    }
  }

  Future<void> playBackgroundMusic() async {
    _observeLifecycle();
    if (!_soundEnabled || !_musicEnabled || _suspended || !_interacted) return;
    final track = _musicTrack != 'auto'
        ? _musicTrack
        : switch (_mood) {
            'sleepy' || 'sleep' => 'night_mode',
            'excited' || 'playful' => 'mini_game',
            'loving' => 'photo_booth',
            _ => 'main_theme',
          };
    final revision = ++_musicRevision;
    return _musicQueue = _musicQueue.then((_) async {
      if (revision != _musicRevision) return;
      try {
        final player = _musicPlayer ??= _createPlayer('zona_pets_music');
        if (_playingMusic != track) {
          await player.setReleaseMode(ReleaseMode.loop);
          if (revision != _musicRevision) return;
          await player.play(AssetSource('music/$track.wav'),
              volume: _musicVolume);
          _playingMusic = track;
        } else {
          await player.setVolume(_musicVolume);
        }
        if (revision != _musicRevision) {
          await player.stop();
          _playingMusic = null;
        }
      } catch (_) {
        _playingMusic = null;
      }
    });
  }

  Future<void> stopBackgroundMusic() async {
    ++_musicRevision;
    return _musicQueue = _musicQueue.then((_) async {
      try {
        await _musicPlayer?.stop();
      } catch (_) {}
      _playingMusic = null;
    });
  }

  Future<void> _stopEffects() async {
    for (final player in _sfxPlayers) {
      try {
        await player?.stop();
      } catch (_) {}
    }
  }

  void dispose() {
    _audioRevision++;
    _musicRevision++;
    if (_observing) WidgetsBinding.instance.removeObserver(this);
    _observing = false;
    _interacted = false;
    _suspended = false;
    for (var i = 0; i < _sfxPlayers.length; i++) {
      final player = _sfxPlayers[i];
      if (player != null) unawaited(player.dispose().catchError((_) {}));
      _sfxPlayers[i] = null;
    }
    final music = _musicPlayer;
    if (music != null) unawaited(music.dispose().catchError((_) {}));
    _musicPlayer = null;
    _playingMusic = null;
  }

  double get _packVolume {
    switch (_soundPack) {
      case 'soft':
        return 0.55;
      case 'arcade':
        return 1.0;
      case 'quiet':
        return 0.22;
      case 'classic':
      case 'cute':
      default:
        return 0.82;
    }
  }
}
