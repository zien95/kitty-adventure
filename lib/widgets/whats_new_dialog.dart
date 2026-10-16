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
                      Icons.threed_rotation,
                      'THIRD-PERSON PET WORLD',
                      'Walk around the garden in real X, Y, and Z space. Orbit the camera and follow the live coordinate display.',
                      const Color(0xFF5AA9E6),
                    ),
                    _buildNewFeature(
                      Icons.sports_esports,
                      'PC & MOBILE CONTROLS',
                      'Use WASD, arrows, Space, Q or Shift, and E on PC. On mobile, use the joystick and action buttons.',
                      const Color(0xFF8A68D6),
                    ),
                    _buildNewFeature(
                      Icons.restaurant,
                      'JUMP ON THE BOWL TO EAT',
                      'Approach the food bowl, then jump or fly onto it. Landing triggers the normal feeding action and rewards.',
                      const Color(0xFFFFA33C),
                    ),
                    _buildNewFeature(
                      Icons.flight,
                      'BIRDS CAN FLY',
                      'Birds can take off, climb, swoop through the yard, descend, and land. Their Y coordinate tracks altitude.',
                      const Color(0xFF66C58D),
                    ),
                    _buildNewFeature(
                      Icons.auto_awesome,
                      'AGE & MOOD ART',
                      'Every species now has generated character art for five life stages and eight mood expressions.',
                      const Color(0xFFFF76B7),
                    ),
                    _buildNewFeature(
                      Icons.pets,
                      'ELEPHANTS ARRIVE',
                      'Adopt an elephant, grow from calf to elder, explore Gentle Giant Grove, and hear a real CC0 trumpet.',
                      const Color(0xFF8FA9C7),
                    ),
                    _buildNewFeature(
                      Icons.graphic_eq,
                      'REAL ANIMAL SOUND CREDITS',
                      'The credits page now includes the elephant source and Creative Commons license alongside every other animal.',
                      const Color(0xFF66C58D),
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
                          'Version ${UpdateService.currentVersion}: a third-person world with elephants, flight, age, and mood art',
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
