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
                  Text(
                    'WHAT\'S NEW v${UpdateService.currentVersion}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
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
                      Icons.pets,
                      'NEW UI + CAT',
                      'Cleaner home screen\n'
                          'Consistent gray kitty art\n'
                          'Tidier stats, badges, and action buttons',
                      const Color(0xFFFFD166),
                    ),
                    _buildNewFeature(
                      Icons.build_circle,
                      'BUG FIXES',
                      'Fixed layout overflow issues\n'
                          'Fixed pet action buttons\n'
                          'Bug fixes and app polish',
                      const Color(0xFF70E1F5),
                    ),
                    _buildNewFeature(
                      Icons.groups,
                      'CAT MANAGER CENTER',
                      'Adopt more cats\n'
                          'Rename and switch cats\n'
                          'Edit personality, favorite food, toy, bio, mood, and stats',
                      const Color(0xFFFF80AB),
                    ),
                    _buildNewFeature(
                      Icons.dark_mode,
                      'LIGHT & DARK MODE',
                      'Switch the whole game between bright daytime and cozy nighttime',
                      const Color(0xFF9A8CFF),
                    ),
                    _buildNewFeature(
                      Icons.movie,
                      'GROUP PLAY',
                      'Play now opens a cute cutscene when your cats play together',
                      const Color(0xFFFF996F),
                    ),
                    _buildNewFeature(
                      Icons.work,
                      'CAT JOBS',
                      'Send cats scouting, napping, toy testing, or coin hunting\n'
                          'Come back later to claim rewards',
                      const Color(0xFF8CCB87),
                    ),
                    _buildNewFeature(
                      Icons.home,
                      'ROOM EFFECTS',
                      'Rooms now boost matching actions like sleep, play, train, food, and bond',
                      const Color(0xFF8CD7FF),
                    ),
                    _buildNewFeature(
                      Icons.checkroom,
                      'OUTFIT SETS',
                      'Collect matching outfit pieces and activate set bonuses',
                      const Color(0xFFD77BFF),
                    ),
                    _buildNewFeature(
                      Icons.lock_open,
                      'SECRET CODES',
                      'Redeem one-time codes in Kitty Hub for bonus rewards',
                      const Color(0xFFFFD45E),
                    ),
                    _buildNewFeature(
                      Icons.celebration,
                      '3RD ANNIVERSARY',
                      'New corner banner\n'
                          'Easter Egg Journal with found-secret tracking\n'
                          'Tap, double-tap, and long-press around to see what answers back',
                      const Color(0xFFFF76B7),
                    ),
                    _buildNewFeature(
                      Icons.query_stats,
                      'MORE PET INFO',
                      'Health, hunger, happy, energy, clean, IQ, social, bond, sleep, and level stay visible',
                      const Color(0xFF66D0C4),
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
                          'Version ${UpdateService.currentVersion}: New UI, cat updates, and bug fixes',
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
