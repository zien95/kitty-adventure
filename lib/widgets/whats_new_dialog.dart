import 'package:flutter/material.dart';

import '../services/update_service.dart';

class WhatsNewDialog extends StatelessWidget {
  final VoidCallback onClose;

  const WhatsNewDialog({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF182235),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF263B60), Color(0xFF2D6F7A)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.celebration, color: Colors.white),
                  SizedBox(width: 8),
                  Flexible(
                      child: Text(
                    'WHAT\'S NEW v${UpdateService.currentVersion}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  )),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNewFeature(
                      Icons.egg_outlined,
                      'HATCH A NEW FRIEND',
                      'Choose an egg in Hub → Egg Nest. A clear two-minute timer keeps going while you are away. Hatch it into a new pet for your family.',
                      const Color(0xFFFFA33C),
                    ),
                    _buildNewFeature(
                      Icons.pets,
                      'WELCOME TO PET FIASCO',
                      'New name, new home: pet-fiasco.web.app. Your existing pet family stays with you.',
                      const Color(0xFF66C58D),
                    ),
                    _buildNewFeature(
                      Icons.cloud_sync,
                      'ACCOUNTS & CLOUD SAVES',
                      'Sign in with email from Settings → Account & Cloud Save. Choose device or cloud progress and save your family across devices.',
                      const Color(0xFF5AA9E6),
                    ),
                    _buildNewFeature(
                      Icons.auto_awesome,
                      'DAYS, AGE & EVOLUTION',
                      'See your pet’s day and age. Tap the growth strip to follow Baby, Child, Teen, Adult, and Elder stages. Grow through time or levels.',
                      const Color(0xFFFFA33C),
                    ),
                    _buildNewFeature(
                      Icons.music_note,
                      'HAPPY PAWS & SOUND',
                      'Hear care actions, pet voices, rewards, and taps. Choose Cute, Cozy, or Arcade sounds with separate effects and music volume.',
                      const Color(0xFFFF76B7),
                    ),
                    _buildNewFeature(
                      Icons.checklist,
                      'CARE JOURNAL & COMBOS',
                      'Track daily care for each pet and earn rewards for varied care. Open the Journal tab in Pet Hub.',
                      const Color(0xFF66C58D),
                    ),
                    _buildNewFeature(
                      Icons.cake,
                      'BIRTHDAYS & REACTIONS',
                      'Celebrate pet birthdays, see new care reactions, and let background music follow your pet\'s mood.',
                      const Color(0xFFFFA33C),
                    ),
                    _buildNewFeature(
                      Icons.celebration,
                      'PET PARADE',
                      'Open Pet Hub and start a moving parade with every pet in your family.',
                      const Color(0xFF66C58D),
                    ),
                    _buildNewFeature(
                      Icons.menu_book,
                      'ANIMAL ALMANAC',
                      'Every species now has a habitat entry, adoption status, and a matching care boost.',
                      const Color(0xFFFF76B7),
                    ),
                    _buildNewFeature(
                      Icons.home_work,
                      'HABITAT BOOSTS',
                      'Cats, dogs, bunnies, foxes, pandas, and birds each get bonus power from their favorite care action.',
                      const Color(0xFFFFA33C),
                    ),
                    _buildNewFeature(
                      Icons.local_fire_department,
                      'DAILY STREAK CARD',
                      'The Hub now shows your streak day and tomorrow\'s care reward.',
                      const Color(0xFF5AA9E6),
                    ),
                    _buildNewFeature(
                      Icons.graphic_eq,
                      'SOUND PACKS',
                      'Settings now has Classic, Soft, Arcade, and Quiet sound packs.',
                      const Color(0xFFFF76B7),
                    ),
                    _buildNewFeature(
                      Icons.bug_report,
                      'BUG FIXES',
                      'Race difficulty is fairer, save feedback is clearer, and pet labels now match the animal you picked.',
                      const Color(0xFF8A68D6),
                    ),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF223047),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star, color: Color(0xFFFFD45E), size: 18),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Version ${UpdateService.currentVersion}: More sounds, daily care, birthdays, and happier paws',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version ${UpdateService.currentVersion}',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D6F7A),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Let\'s Play!',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewFeature(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
