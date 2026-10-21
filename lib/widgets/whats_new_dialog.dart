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
                    child: Column(
                      children: [
                        Text(
                          'WHAT\'S NEW v${UpdateService.currentVersion}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'EXPLORATION UPDATE • PART 1',
                          style: TextStyle(
                            color: Color(0xFFFFD45E),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
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
                      Icons.map,
                      'A MUCH BIGGER WORLD',
                      'Explore a 72 by 90 unit world with faster movement, a live minimap, and room for future Exploration updates.',
                      const Color(0xFF5AA9E6),
                    ),
                    _buildNewFeature(
                      Icons.location_city,
                      'PLACES THAT LOOK LIKE PLACES',
                      'Visit an illustrated vet clinic, pet bed, toy yard, arcade station, cottage, pond, climbing tree, park, and flower garden.',
                      const Color(0xFF62C9D2),
                    ),
                    _buildNewFeature(
                      Icons.touch_app,
                      'ENTER & ACTION NOW WORK',
                      'Press E on PC or the changing Action button on mobile. Places now trigger healing, sleep, play, cleaning, training, bonding, and games.',
                      const Color(0xFFFFA33C),
                    ),
                    _buildNewFeature(
                      Icons.pets,
                      'THE PET MOVES—NOT THE FURNITURE',
                      'The pet visibly crosses the nearby world. The camera waits until the pet reaches the view edge before following.',
                      const Color(0xFF66C58D),
                    ),
                    _buildNewFeature(
                      Icons.groups,
                      'EXPLORE WITH THE PET FAMILY',
                      'Your other pets appear as smaller companions. Tap a companion to make it the larger selected pet without losing your place in the world.',
                      const Color(0xFFFF76B7),
                    ),
                    _buildNewFeature(
                      Icons.phone_iphone,
                      'MOBILE-ONLY TAURI SHELL',
                      'Android and iPadOS open the hosted game in Tauri, receive hosted updates automatically, and hide the download button.',
                      const Color(0xFFB88CFF),
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
                          'Exploration Update: Part 1 • Version ${UpdateService.currentVersion}',
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
