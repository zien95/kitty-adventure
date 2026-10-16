import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AnimalSoundCredit {
  const AnimalSoundCredit({
    required this.species,
    required this.recording,
    required this.creator,
    required this.license,
    required this.licenseUrl,
    required this.sourceUrl,
  });

  final String species;
  final String recording;
  final String creator;
  final String license;
  final String licenseUrl;
  final String sourceUrl;
}

const animalSoundCredits = <AnimalSoundCredit>[
  AnimalSoundCredit(
    species: 'Cat',
    recording: 'Meow of a Siamese cat',
    creator: 'freemaster2',
    license: 'CC0 1.0',
    licenseUrl: 'https://creativecommons.org/publicdomain/zero/1.0/',
    sourceUrl:
        'https://commons.wikimedia.org/wiki/File:Meow_of_a_Siamese_cat_-_freemaster2.wav',
  ),
  AnimalSoundCredit(
    species: 'Dog',
    recording: 'Dog barking.wav',
    creator: 'Ryding',
    license: 'CC0 1.0',
    licenseUrl: 'https://creativecommons.org/publicdomain/zero/1.0/',
    sourceUrl: 'https://freesound.org/people/Ryding/sounds/110134/',
  ),
  AnimalSoundCredit(
    species: 'Bunny',
    recording: 'rabbit eating.wav',
    creator: 'BeeProductive',
    license: 'CC0 1.0',
    licenseUrl: 'https://creativecommons.org/publicdomain/zero/1.0/',
    sourceUrl: 'https://freesound.org/people/BeeProductive/sounds/380890/',
  ),
  AnimalSoundCredit(
    species: 'Fox',
    recording: 'Red Fox (Vulpes vulpes), British Library W1CDR0001529 BD12',
    creator: 'Aubrey John Williams / The British Library Board',
    license: 'CC BY-SA 4.0',
    licenseUrl: 'https://creativecommons.org/licenses/by-sa/4.0/',
    sourceUrl:
        'https://commons.wikimedia.org/wiki/File:Red_Fox_(Vulpes_vulpes)_(W1CDR0001529_BD12).ogg',
  ),
  AnimalSoundCredit(
    species: 'Panda',
    recording: 'Giant panda twittering',
    creator: 'Mizunoryu',
    license: 'Public domain',
    licenseUrl:
        'https://commons.wikimedia.org/wiki/File:Giant_panda_twittering.ogg#Licensing',
    sourceUrl:
        'https://commons.wikimedia.org/wiki/File:Giant_panda_twittering.ogg',
  ),
  AnimalSoundCredit(
    species: 'Bird',
    recording: 'Bird chirp 2',
    creator: 'Gravity Sound',
    license: 'CC BY 4.0',
    licenseUrl: 'https://creativecommons.org/licenses/by/4.0/',
    sourceUrl:
        'https://commons.wikimedia.org/wiki/File:Bird_chirp_2_(Gravity_Sound).mp3',
  ),
  AnimalSoundCredit(
    species: 'Elephant',
    recording: 'Elephant voice - trumpeting',
    creator: 'தகவலுழவன் (Info-farmer)',
    license: 'CC0 1.0',
    licenseUrl: 'https://creativecommons.org/publicdomain/zero/1.0/',
    sourceUrl:
        'https://commons.wikimedia.org/wiki/File:Elephant_voice_-_trumpeting.ogg',
  ),
];

class AnimalSoundCreditsPage extends StatelessWidget {
  const AnimalSoundCreditsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Animal Sound Credits')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Pet Fiasco uses real animal recordings shared by generous '
            'recordists. Each clip was excerpted, downmixed to mono, resampled '
            'to 44.1 kHz, normalized, faded, and exported as 16-bit WAV.',
          ),
          const SizedBox(height: 8),
          const Text(
            'CC0 and public-domain creators are credited as a thank-you even '
            'when attribution is not required. The fox derivative remains '
            'available under CC BY-SA 4.0.',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),
          for (final credit in animalSoundCredits)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      credit.species,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(credit.recording),
                    Text('Creator: ${credit.creator}'),
                    Text('License: ${credit.license}'),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: () => _open(context, credit.sourceUrl),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Source'),
                        ),
                        TextButton.icon(
                          onPressed: () => _open(context, credit.licenseUrl),
                          icon: const Icon(Icons.description_outlined),
                          label: const Text('License'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context, String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open that credit link.')),
      );
    }
  }
}
