import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/pet.dart';
import '../providers/game_provider.dart';
import 'help_screen.dart';
import 'obstacle_course_screen.dart';
import 'settings_screen.dart';
import 'customization_screen.dart';
import 'data_transfer_screen.dart';
import 'user_account_screen.dart';

class CompactGameScreen extends StatefulWidget {
  const CompactGameScreen({super.key});

  @override
  State<CompactGameScreen> createState() => _CompactGameScreenState();
}

class _CompactGameScreenState extends State<CompactGameScreen> {
  void _performAction(GameProvider gameProvider, String action) {
    switch (action) {
      case 'feed':
        gameProvider.feed();
        break;
      case 'play':
        gameProvider.play();
        break;
      case 'clean':
        gameProvider.clean();
        break;
      case 'sleep':
        gameProvider.sleep();
        break;
      case 'train':
        gameProvider.train();
        break;
      case 'medicine':
        gameProvider.giveMedicine();
        break;
    }
  }

  String _getAccessoryEmoji(String accessory) {
    switch (accessory) {
      case 'hat':
        return '🎩';
      case 'scarf':
        return '🧣';
      case 'glasses':
        return '🕶️';
      case 'bow':
        return '🎀';
      case 'collar':
        return '📿';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final pet = gameProvider.pet!;

        return Scaffold(
          backgroundColor: const Color(0xFF2D2D3A),
          body: Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                switch (event.logicalKey.keyLabel) {
                  case 'F':
                    _performAction(gameProvider, 'feed');
                    return KeyEventResult.handled;
                  case 'P':
                    _performAction(gameProvider, 'play');
                    return KeyEventResult.handled;
                  case 'C':
                    _performAction(gameProvider, 'clean');
                    return KeyEventResult.handled;
                  case 'S':
                    _performAction(gameProvider, 'sleep');
                    return KeyEventResult.handled;
                  case 'T':
                    _performAction(gameProvider, 'train');
                    return KeyEventResult.handled;
                  case 'M':
                    _performAction(gameProvider, 'medicine');
                    return KeyEventResult.handled;
                  case 'A':
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const UserAccountScreen()));
                    return KeyEventResult.handled;
                  case 'D':
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const DataTransferScreen()));
                    return KeyEventResult.handled;
                  case 'G':
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => Container()));
                    return KeyEventResult.handled;
                  case 'O':
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const ObstacleCourseScreen()));
                    return KeyEventResult.handled;
                  case 'H':
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const HelpScreen()));
                    return KeyEventResult.handled;
                  case 'Set':
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SettingsScreen()));
                    return KeyEventResult.handled;
                  case 'Z':
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CustomizationScreen()));
                    return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: SafeArea(
              child: Column(
                children: [
                  // Compact Header - Fixed Height
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${pet.name} - Level ${pet.level}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const CustomizationScreen())),
                              icon: const Icon(Icons.palette,
                                  color: Colors.white),
                            ),
                            IconButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const SettingsScreen())),
                              icon: const Icon(Icons.settings,
                                  color: Colors.white),
                            ),
                            IconButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const HelpScreen())),
                              icon: const Icon(Icons.help, color: Colors.white),
                            ),
                            IconButton(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const ObstacleCourseScreen())),
                              icon: const Icon(Icons.directions_run,
                                  color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Main Content - No Scrolling
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Pet Avatar & Quick Stats - Compact
                          Row(
                            children: [
                              // Pet Avatar - Smaller
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: pet.type.color.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: pet.type.color, width: 3),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Text(pet.type.emoji,
                                        style: const TextStyle(fontSize: 50)),
                                    if (pet.currentAccessory.isNotEmpty)
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Text(
                                          _getAccessoryEmoji(
                                              pet.currentAccessory),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Quick Stats - Most Important Only
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildCompactStatBar(
                                        'Health', pet.health, Colors.red),
                                    const SizedBox(height: 8),
                                    _buildCompactStatBar(
                                        'Hunger', pet.hunger, Colors.orange),
                                    const SizedBox(height: 8),
                                    _buildCompactStatBar('Happiness',
                                        pet.happiness, Colors.yellow),
                                    const SizedBox(height: 8),
                                    _buildCompactStatBar(
                                        'Energy', pet.energy, Colors.blue),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // MOST IMPORTANT ACTIONS - Priority Order
                          Expanded(
                            child: GridView.count(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              children: [
                                // 1. Feed - Most Critical
                                _buildCompactActionItem(
                                  icon: Icons.restaurant,
                                  label: 'Feed\n(F)',
                                  color: Colors.orange,
                                  onTap: () =>
                                      _performAction(gameProvider, 'feed'),
                                ),

                                // 2. Play - Very Important
                                _buildCompactActionItem(
                                  icon: Icons.toys,
                                  label: 'Play\n(P)',
                                  color: Colors.purple,
                                  onTap: () =>
                                      _performAction(gameProvider, 'play'),
                                ),

                                // 3. Sleep - Critical for Energy
                                _buildCompactActionItem(
                                  icon: Icons.bed,
                                  label: 'Sleep\n(S)',
                                  color: Colors.blue,
                                  onTap: () =>
                                      _performAction(gameProvider, 'sleep'),
                                ),

                                // 4. Clean - Important for Health
                                _buildCompactActionItem(
                                  icon: Icons.shower,
                                  label: 'Clean\n(C)',
                                  color: Colors.cyan,
                                  onTap: () =>
                                      _performAction(gameProvider, 'clean'),
                                ),

                                // 5. Train - For Intelligence
                                _buildCompactActionItem(
                                  icon: Icons.school,
                                  label: 'Train\n(T)',
                                  color: Colors.green,
                                  onTap: () =>
                                      _performAction(gameProvider, 'train'),
                                ),

                                // 6. Medicine - Emergency Only
                                _buildCompactActionItem(
                                  icon: Icons.medical_services,
                                  label: 'Medicine\n(M)',
                                  color: Colors.red,
                                  onTap: () =>
                                      _performAction(gameProvider, 'medicine'),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Bottom Navigation - Most Used Features
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => Container())),
                                  icon: const Icon(Icons.games),
                                  label: const Text('Games (G)'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const CustomizationScreen())),
                                  icon: const Icon(Icons.palette),
                                  label: const Text('Style (Z)'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.pink,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const ObstacleCourseScreen())),
                                  icon: const Icon(Icons.directions_run),
                                  label: const Text('Course (O)'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactStatBar(String label, int value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              '$value%',
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value / 100.0,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
