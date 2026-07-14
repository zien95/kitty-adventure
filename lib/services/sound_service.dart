import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool _soundEnabled = true;

  bool get soundEnabled => _soundEnabled;

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  Future<void> playSound(String soundName) async {
    if (!_soundEnabled) return;

    try {
      // Enhanced sound feedback with multiple attempts
      await SystemSound.play(SystemSoundType.click);

      // Add haptic feedback for better accessibility
      await _triggerHapticFeedback(soundName);

      // Visual feedback alternative
      await _triggerVisualFeedback(soundName);
    } catch (e) {
      // Multiple fallback options
      try {
        await _triggerHapticFeedback(soundName);
      } catch (e2) {
        // Final fallback - silent operation
      }
    }
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
    try {
      bool? hasVibrator = await Vibration.hasVibrator();
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

  Future<void> playBackgroundMusic() async {
    if (!_soundEnabled) return;
    // Background music disabled for now
  }

  Future<void> stopBackgroundMusic() async {
    // No background music to stop
  }

  void dispose() {
    // Nothing to dispose
  }
}
