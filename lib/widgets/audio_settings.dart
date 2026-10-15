import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../services/sound_service.dart';
import 'audio_credits_page.dart';

/// Shared audio controls for both the game dialog and full Settings screen.
class AudioSettings extends StatelessWidget {
  const AudioSettings({super.key});

  static const _packs = {
    'classic': 'Classic Pops',
    'cute': 'Cute Voices',
    'soft': 'Soft Cozy',
    'arcade': 'Arcade Clicks',
    'quiet': 'Quiet Nibbles',
  };

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          title: const Text('Sound'),
          subtitle: const Text('Pet voices, care sounds, and music'),
          secondary: const Icon(Icons.volume_up),
          value: game.soundEnabled,
          onChanged: (_) => game.toggleSound(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonFormField<String>(
            initialValue: game.soundPack,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Sound theme'),
            items: _packs.entries
                .map((entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) game.setSoundPack(value);
            },
          ),
        ),
        _volume('Effects volume', game.effectsVolume,
            game.soundEnabled ? game.setEffectsVolume : null),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          children: [
            TextButton.icon(
              onPressed: game.soundEnabled
                  ? () => SoundService().playSound('feed')
                  : null,
              icon: const Icon(Icons.restaurant),
              label: const Text('Try care sound'),
            ),
            TextButton.icon(
              onPressed: game.soundEnabled
                  ? () => SoundService().playSound('reward')
                  : null,
              icon: const Icon(Icons.star),
              label: const Text('Try reward'),
            ),
          ],
        ),
        SwitchListTile(
          title: const Text('Background music'),
          subtitle:
              const Text('Starts when you interact; pauses away from the app'),
          secondary: const Icon(Icons.music_note),
          value: game.musicEnabled,
          onChanged: game.soundEnabled ? game.setMusicEnabled : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonFormField<String>(
            initialValue: game.musicTrack,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Music'),
            items: SoundService.musicTracks.entries
                .map((entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ))
                .toList(),
            onChanged: game.soundEnabled && game.musicEnabled
                ? (value) {
                    if (value != null) game.setMusicTrack(value);
                  }
                : null,
          ),
        ),
        _volume(
            'Music volume',
            game.musicVolume,
            game.soundEnabled && game.musicEnabled
                ? game.setMusicVolume
                : null),
        SwitchListTile(
          title: const Text('Vibration'),
          secondary: const Icon(Icons.vibration),
          value: game.vibrationEnabled,
          onChanged: (_) => game.toggleVibration(),
        ),
        ListTile(
          leading: const Icon(Icons.pets),
          title: const Text('Animal sound credits'),
          subtitle: const Text('Sources and Creative Commons licenses'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AnimalSoundCreditsPage(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _volume(String label, double value, ValueChanged<double>? onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ${(value * 100).round()}%'),
          Slider(
            value: value,
            divisions: 20,
            label: '${(value * 100).round()}%',
            semanticFormatterCallback: (value) =>
                '${(value * 100).round()} percent',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
