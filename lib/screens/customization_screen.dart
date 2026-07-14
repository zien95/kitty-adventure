import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/account_provider.dart';
import '../models/pet.dart';

class CustomizationScreen extends StatefulWidget {
  const CustomizationScreen({super.key});

  @override
  State<CustomizationScreen> createState() => _CustomizationScreenState();
}

class _CustomizationScreenState extends State<CustomizationScreen> {
  String? selectedAccessory;
  String selectedTheme = 'default';
  double petSize = 1.0;
  Color selectedColor = Colors.blue;

  final List<Map<String, dynamic>> themes = [
    {
      'name': 'default',
      'color': Colors.blue,
      'icon': Icons.palette,
      'isPremium': false,
    },
    {
      'name': 'dark',
      'color': Colors.grey[800]!,
      'icon': Icons.nightlight,
      'isPremium': false,
    },
    {
      'name': 'ocean',
      'color': Colors.cyan,
      'icon': Icons.waves,
      'isPremium': false,
    },
    {
      'name': 'forest',
      'color': Colors.green,
      'icon': Icons.forest,
      'isPremium': false,
    },
    {
      'name': 'sunset',
      'color': Colors.orange,
      'icon': Icons.wb_sunny,
      'isPremium': false,
    },
    {
      'name': 'galaxy',
      'color': Colors.purple,
      'icon': Icons.star,
      'isPremium': true,
    },
    {
      'name': 'rainbow',
      'color': Colors.pink,
      'icon': Icons.gradient,
      'isPremium': true,
    },
    {
      'name': 'golden',
      'color': Colors.amber,
      'icon': Icons.auto_awesome,
      'isPremium': true,
    },
  ];

  final List<Map<String, dynamic>> accessories = [
    {
      'name': 'hat',
      'emoji': '🎩',
      'price': 20,
      'type': 'gem',
      'isPremium': false,
    },
    {
      'name': 'scarf',
      'emoji': '🧣',
      'price': 15,
      'type': 'gem',
      'isPremium': false,
    },
    {
      'name': 'glasses',
      'emoji': '🕶️',
      'price': 25,
      'type': 'gem',
      'isPremium': false,
    },
    {
      'name': 'bow',
      'emoji': '🎀',
      'price': 10,
      'type': 'gem',
      'isPremium': false,
    },
    {
      'name': 'collar',
      'emoji': '📿',
      'price': 18,
      'type': 'gem',
      'isPremium': false,
    },
    {
      'name': 'crown',
      'emoji': '👑',
      'price': 50,
      'type': 'gem',
      'isPremium': true,
    },
    {
      'name': 'wings',
      'emoji': '👼',
      'price': 100,
      'type': 'gem',
      'isPremium': true,
    },
    {
      'name': 'halo',
      'emoji': '😇',
      'price': 75,
      'type': 'gem',
      'isPremium': true,
    },
    {
      'name': 'throne',
      'emoji': '👸',
      'price': 150,
      'type': 'gem',
      'isPremium': true,
    },
    {
      'name': 'magic',
      'emoji': '✨',
      'price': 200,
      'type': 'gem',
      'isPremium': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameProvider, AccountProvider>(
      builder: (context, gameProvider, accountProvider, child) {
        final pet = gameProvider.pet;
        final isPremium = accountProvider.isPremium;

        if (pet == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF2D2D3A),
            body: Center(
              child: Text(
                'Create a pet first!',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFF2D2D3A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF7B1FA2),
            title: Row(
              children: [
                const Text(
                  '🎨 Customization',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isPremium) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Text(
                      'PREMIUM',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Preview'),
                _buildPreview(pet, gameProvider),
                const SizedBox(height: 24),
                _buildSectionTitle('Themes'),
                _buildThemeSelector(isPremium),
                const SizedBox(height: 24),
                _buildSectionTitle('Size'),
                _buildSizeSlider(),
                const SizedBox(height: 24),
                _buildSectionTitle('Accessories'),
                _buildAccessoryGrid(gameProvider, isPremium),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton(
                    onPressed: () => _saveCustomization(gameProvider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B1FA2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPreview(Pet pet, GameProvider gameProvider) {
    String currentAccessoryEmoji = '';
    if (selectedAccessory != null) {
      final accessory = accessories.firstWhere(
        (acc) => acc['name'] == selectedAccessory,
        orElse: () => {'emoji': ''},
      );
      currentAccessoryEmoji = accessory['emoji'];
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3D3D4A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Preview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Transform.scale(
            scale: petSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: pet.type.color.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: pet.type.color, width: 4),
                  ),
                  child: Text(
                    pet.type.emoji,
                    style: const TextStyle(fontSize: 70),
                  ),
                ),
                if (currentAccessoryEmoji.isNotEmpty)
                  Positioned(
                    top: -10,
                    right: -10,
                    child: Text(
                      currentAccessoryEmoji,
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${pet.name} - Level ${pet.level}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(bool isPremium) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: themes.length,
      itemBuilder: (context, index) {
        final theme = themes[index];
        final isSelected = selectedTheme == theme['name'];
        final isLocked = theme['isPremium'] as bool && !isPremium;

        return GestureDetector(
          onTap: isLocked
              ? null
              : () {
                  setState(() {
                    selectedTheme = theme['name'];
                    selectedColor = theme['color'];
                  });
                },
          child: Container(
            decoration: BoxDecoration(
              color: isLocked
                  ? Colors.grey.withValues(alpha: 0.2)
                  : theme['color'].withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? theme['color']!
                    : isLocked
                        ? Colors.grey.withValues(alpha: 0.3)
                        : theme['color'].withValues(alpha: 0.3),
                width: isSelected ? 3 : 1,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        theme['icon'],
                        color: isLocked
                            ? Colors.grey
                            : isSelected
                                ? theme['color'] as Color
                                : Colors.white70,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        theme['name'].toUpperCase(),
                        style: TextStyle(
                          color: isLocked
                              ? Colors.grey
                              : isSelected
                                  ? theme['color'] as Color
                                  : Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLocked)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(Icons.lock, color: Colors.amber, size: 16),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSizeSlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF3D3D4A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Size',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Text(
                '${(petSize * 100).toInt()}%',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: petSize,
            min: 0.5,
            max: 1.5,
            divisions: 10,
            activeColor: selectedColor,
            onChanged: (value) {
              setState(() {
                petSize = value;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Small',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const Text(
                'Normal',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const Text(
                'Large',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccessoryGrid(GameProvider gameProvider, bool isPremium) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: accessories.length,
      itemBuilder: (context, index) {
        final accessory = accessories[index];
        final isSelected = selectedAccessory == accessory['name'];
        final isOwned =
            gameProvider.pet?.accessories.contains(accessory['name']) ?? false;
        final isLocked = accessory['isPremium'] as bool && !isPremium;
        final canAfford = !isLocked &&
            ((accessory['type'] == 'gem' &&
                    (gameProvider.pet?.gems ?? 0) >= accessory['price']) ||
                (accessory['type'] == 'coin' &&
                    (gameProvider.pet?.coins ?? 0) >= accessory['price']));

        return GestureDetector(
          onTap: isLocked || !canAfford
              ? null
              : () => _selectAccessory(accessory, gameProvider),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? selectedColor.withValues(alpha: 0.3)
                  : (isLocked
                      ? Colors.grey.withValues(alpha: 0.2)
                      : const Color(0xFF3D3D4A)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? selectedColor
                    : (isLocked
                        ? Colors.grey
                        : (isOwned ? Colors.green : Colors.grey)),
                width: isSelected ? 3 : 1,
              ),
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      accessory['emoji'],
                      style: TextStyle(
                        fontSize: 24,
                        color: isLocked ? Colors.grey : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      accessory['name'].toUpperCase(),
                      style: TextStyle(
                        color: isSelected
                            ? selectedColor
                            : (isLocked
                                ? Colors.grey
                                : (isOwned ? Colors.green : Colors.grey)),
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isOwned && !isLocked)
                      Text(
                        '${accessory['price']} ${accessory['type']}',
                        style: TextStyle(
                          color: canAfford ? Colors.white : Colors.red,
                          fontSize: 8,
                        ),
                      ),
                  ],
                ),
                if (isLocked)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(Icons.lock, color: Colors.amber, size: 16),
                  ),
                if (!canAfford && !isLocked)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(Icons.money_off, color: Colors.red, size: 16),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _selectAccessory(
    Map<String, dynamic> accessory,
    GameProvider gameProvider,
  ) {
    setState(() {
      selectedAccessory = accessory['name'];
    });
  }

  void _saveCustomization(GameProvider gameProvider) {
    // Apply theme color to pet
    gameProvider.updatePetColor(selectedColor);

    // Apply selected accessory
    if (selectedAccessory != null) {
      gameProvider.addAccessory(selectedAccessory!);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Customization saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
