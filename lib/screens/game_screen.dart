import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/pet.dart';
import '../providers/game_provider.dart';
import '../providers/account_provider.dart';
import '../widgets/stat_bar.dart';
import 'settings_screen.dart';
import 'help_screen.dart';
import 'obstacle_course_screen.dart';
import 'account_screen.dart';
import 'messages_screen.dart';
import '../widgets/notification_bell.dart';

// Pet care game changelog
final List<Map<String, String>> _petCareChangelog = [
  {
    'version': 'v26.8.5 - Kitty Hub Update',
    'features': '''
🐾 CAT MANAGER CENTER: Adopt, rename, switch, manage profiles, and play together
🧰 CAT JOBS: Send cats out for timed rewards
🏠 ROOM EFFECTS: Equipped rooms boost matching actions
👗 OUTFIT SETS: Matching outfits unlock bonus boosts
🔐 SECRET CODES: One-time reward codes in Kitty Hub
📖 EASTER EGG JOURNAL: Found secrets are tracked
🎉 3RD ANNIVERSARY: Corner banner and hidden jokes
📊 DETAILED STATS: Health, sleep, level, bond, social, IQ, and more
🎮 MINI-GAMES: Puzzle, racing, rhythm, memory, quiz, and more
🛠️ BUG FIXES: Layout polish and smoother play
    ''',
  },
  {
    'version': 'v2.0 - Enhanced Pet Care',
    'features': '''
🧬 Evolution System: 5 stages with stat bonuses
🎮 Mini-Games Suite: 6 fully functional games
👗 Accessories & Customization: 5 wearable items
😊 Dynamic Mood System: 8 different moods
🏆 Achievement System: Auto-detection and rewards
🎒 Inventory & Items: 4 strategic items
🎯 Skills & Progression: 4 trainable skills
💝 Social & Bonding: Friendship and loyalty
    ''',
  },
  {
    'version': 'v1.0 - Foundation',
    'features': '''
🎮 Basic Pet Care Gameplay
📊 Stat Management (Health, Happiness, Hunger, Energy)
⏰ Time-based Needs System
🎯 Simple Actions (Feed, Play, Clean, Sleep)
💾 Local Save System
📱 Touch Controls
    ''',
  },
];

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _showActions = false;

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

  void _showPetCareChangelog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.new_releases, color: Colors.pink),
              const SizedBox(width: 8),
              Text(
                "What's New",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _petCareChangelog.length,
              itemBuilder: (context, index) {
                final update = _petCareChangelog[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: const Color(0xFF4A4A6A),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          update['version']!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          update['features']!,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close', style: TextStyle(color: Colors.pink)),
            ),
          ],
          backgroundColor: const Color(0xFF2D2D3A),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<GameProvider, AccountProvider>(
      builder: (context, gameProvider, accountProvider, child) {
        final pet = gameProvider.pet!;
        final isPremium = accountProvider.isPremium;

        return Scaffold(
          backgroundColor: const Color(0xFF2D2D3A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF7B1FA2),
            title: Row(
              children: [
                const Text(
                  '🐾 Pet Care',
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
                      'AD-FREE',
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
            actions: [
              const NotificationBell(),
              IconButton(
                icon: const Icon(Icons.message, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MessagesScreen(),
                    ),
                  );
                },
                tooltip: 'Messages',
              ),
              IconButton(
                icon: const Icon(Icons.account_circle, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AccountScreen(),
                    ),
                  );
                },
                tooltip: 'Account',
              ),
              IconButton(
                icon: const Icon(Icons.new_releases, color: Colors.white),
                onPressed: () => _showPetCareChangelog(context),
                tooltip: 'What\'s New',
              ),
            ],
          ),
          body: Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              // Keyboard shortcuts for accessibility
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
                  case 'G':
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Container()),
                    );
                    return KeyEventResult.handled;
                  case 'O':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ObstacleCourseScreen(),
                      ),
                    );
                    return KeyEventResult.handled;
                  case 'H':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpScreen(),
                      ),
                    );
                    return KeyEventResult.handled;
                  case 'N':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MessagesScreen(),
                      ),
                    );
                    return KeyEventResult.handled;
                  case 'A':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AccountScreen(),
                      ),
                    );
                    return KeyEventResult.handled;
                  case 'Escape':
                    if (_showActions) {
                      setState(() {
                        _showActions = false;
                      });
                      return KeyEventResult.handled;
                    }
                    break;
                }
              }
              return KeyEventResult.ignored;
            },
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Header
                    _buildHeader(pet.name, pet.level),

                    // Pet Avatar
                    Container(
                      height: 200, // Fixed height instead of percentage
                      child: Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: pet.type.color.withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: pet.type.color,
                                  width: 4,
                                ),
                              ),
                              child: Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Text(
                                      pet.type.emoji,
                                      style: const TextStyle(fontSize: 80),
                                    ),
                                    if (pet.currentAccessory.isNotEmpty)
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Text(
                                          _getAccessoryEmoji(
                                            pet.currentAccessory,
                                          ),
                                          style: const TextStyle(fontSize: 24),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            // Mood indicator
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: _getMoodColor(pet.currentMood),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  pet.moodEmoji,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Stats Panel
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3D3D4A),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${pet.name} ${pet.evolutionEmoji}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    pet.moodEmoji,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getMoodColor(pet.currentMood),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      pet.currentMood.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Level ${pet.level} ${pet.personality.name}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Row(
                                children: [
                                  const Text(
                                    '💰',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    '${pet.coins}',
                                    style: const TextStyle(
                                      color: Colors.yellow,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '💎',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    '${pet.gems}',
                                    style: const TextStyle(
                                      color: Colors.cyan,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '❤️ ${_getFriendshipLevel(pet.friendshipLevel)}',
                                style: TextStyle(
                                  color: _getFriendshipColor(
                                    pet.friendshipLevel,
                                  ),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '🧠 ${_getIntelligenceLevel(pet.intelligence)}',
                                style: TextStyle(
                                  color: _getIntelligenceColor(
                                    pet.intelligence,
                                  ),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '👥 ${_getSocialLevel(pet.social)}',
                                style: TextStyle(
                                  color: _getSocialColor(pet.social),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Stats
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
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
                                'Pet Stats',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_getStatusEmoji(pet.status)} ${_getStatusLabel(pet.status)}',
                                style: TextStyle(
                                  color: _getStatusColor(pet.status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          StatBar(
                            icon: Icons.restaurant,
                            label: 'Hunger',
                            value: pet.hunger,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 12),
                          StatBar(
                            icon: Icons.bolt,
                            label: 'Energy',
                            value: pet.energy,
                            color: Colors.yellow,
                          ),
                          const SizedBox(height: 12),
                          StatBar(
                            icon: Icons.soap,
                            label: 'Cleanliness',
                            value: pet.cleanliness,
                            color: Colors.cyan,
                          ),
                          const SizedBox(height: 12),
                          StatBar(
                            icon: Icons.favorite,
                            label: 'Happiness',
                            value: pet.happiness,
                            color: Colors.pink,
                          ),
                          const SizedBox(height: 12),
                          StatBar(
                            icon: Icons.health_and_safety,
                            label: 'Health',
                            value: pet.health,
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Action Button or Grid
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: _showActions
                          ? _buildActionGrid(gameProvider)
                          : ElevatedButton.icon(
                              onPressed: () {
                                gameProvider.playClickSound();
                                setState(() => _showActions = true);
                              },
                              icon: const Icon(Icons.pets),
                              label: const Text('Interact with Pet'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7B1FA2),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(height: 20),

                    // Banner Ad - Only for non-premium users
                    if (!isPremium)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A4A6A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.ads_click,
                              color: Colors.grey[400],
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Advertisement - Upgrade to Premium to remove ads',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String name, int level) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF7B1FA2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$name - Lv $level',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  context.read<GameProvider>().playClickSound();
                  _showRenameDialog(context);
                },
                icon: const Icon(Icons.edit, color: Colors.white54),
              ),
              IconButton(
                onPressed: () {
                  context.read<GameProvider>().playClickSound();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HelpScreen()),
                  );
                },
                icon: const Icon(Icons.help_outline, color: Colors.white54),
              ),
              IconButton(
                onPressed: () {
                  context.read<GameProvider>().playClickSound();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.settings, color: Colors.white54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getStatusEmoji(String status) {
    switch (status) {
      case 'Critical':
        return '🚨';
      case 'Starving':
        return '😵';
      case 'Exhausted':
        return '😴';
      case 'Dirty':
        return '🧼';
      case 'Sad':
        return '😢';
      case 'Happy':
        return '😊';
      case 'Excellent':
        return '⭐';
      case 'Perfect':
        return '🌟';
      default:
        return '😐';
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'Critical':
        return 'Critical Care';
      case 'Starving':
        return 'Very Hungry';
      case 'Exhausted':
        return 'Very Tired';
      case 'Dirty':
        return 'Needs Clean';
      case 'Sad':
        return 'Feeling Down';
      case 'Happy':
        return 'Doing Great';
      case 'Excellent':
        return 'Excellent';
      case 'Perfect':
        return 'Perfect Care';
      default:
        return 'Okay';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Critical':
        return Colors.red;
      case 'Starving':
        return Colors.orange;
      case 'Exhausted':
        return Colors.deepOrange;
      case 'Dirty':
        return Colors.brown;
      case 'Sad':
        return Colors.blue;
      case 'Happy':
        return Colors.green;
      case 'Excellent':
        return Colors.purple;
      case 'Perfect':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Widget _buildActionGrid(GameProvider gameProvider) {
    final actions = [
      _ActionItem(
        icon: Icons.restaurant,
        label: 'Feed',
        color: Colors.orange,
        onTap: gameProvider.feed,
      ),
      _ActionItem(
        icon: Icons.sports_esports,
        label: 'Play',
        color: Colors.pink,
        onTap: gameProvider.play,
      ),
      _ActionItem(
        icon: Icons.bathtub,
        label: 'Clean',
        color: Colors.cyan,
        onTap: gameProvider.clean,
      ),
      _ActionItem(
        icon: Icons.bedtime,
        label: 'Sleep',
        color: Colors.indigo,
        onTap: gameProvider.sleep,
      ),
      _ActionItem(
        icon: Icons.fitness_center,
        label: 'Train',
        color: Colors.red,
        onTap: gameProvider.train,
      ),
      _ActionItem(
        icon: Icons.videogame_asset,
        label: 'Games',
        color: Colors.purple,
        onTap: () {
          context.read<GameProvider>().playClickSound();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Container()),
          );
        },
      ),
      _ActionItem(
        icon: Icons.directions_run,
        label: 'Course',
        color: Colors.orange,
        onTap: () {
          context.read<GameProvider>().playClickSound();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ObstacleCourseScreen(),
            ),
          );
        },
      ),
      _ActionItem(
        icon: Icons.local_hospital,
        label: 'Medicine',
        color: Colors.teal,
        onTap: gameProvider.giveMedicine,
      ),
      _ActionItem(
        icon: Icons.shopping_bag,
        label: 'Items',
        color: Colors.green,
        onTap: () {
          context.read<GameProvider>().playClickSound();
          _showItemsDialog(context, gameProvider);
        },
      ),
      _ActionItem(
        icon: Icons.emoji_events,
        label: 'Skills',
        color: Colors.amber,
        onTap: () {
          context.read<GameProvider>().playClickSound();
          _showSkillsDialog(context, gameProvider);
        },
      ),
      _ActionItem(
        icon: Icons.favorite,
        label: 'Bond',
        color: Colors.pink[300]!,
        onTap: () {
          gameProvider.increaseFriendship();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❤️ Friendship increased!')),
          );
        },
      ),
      _ActionItem(
        icon: Icons.accessibility,
        label: 'Accessories',
        color: Colors.blue[300]!,
        onTap: () {
          context.read<GameProvider>().playClickSound();
          _showAccessoriesDialog(context, gameProvider);
        },
      ),
      _ActionItem(
        icon: Icons.military_tech,
        label: 'Awards',
        color: Colors.yellow[700]!,
        onTap: () {
          context.read<GameProvider>().playClickSound();
          _showAchievementsDialog(context, gameProvider);
        },
      ),
      _ActionItem(
        icon: Icons.close,
        label: 'Close',
        color: Colors.grey,
        onTap: () {
          context.read<GameProvider>().playClickSound();
          setState(() => _showActions = false);
        },
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        return _ActionItemWidget(
          icon: actions[index].icon,
          label: actions[index].label,
          color: actions[index].color,
          onTap: actions[index].onTap,
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context) {
    final controller = TextEditingController(
      text: context.read<GameProvider>().pet!.name,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D3A),
        title: const Text(
          'Rename Your Pet',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter new name',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<GameProvider>().playClickSound();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                context.read<GameProvider>().renamePet(name);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B1FA2),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _getFriendshipLevel(int friendship) {
    if (friendship >= 95) return 'BFF 💕';
    if (friendship >= 80) return 'Besties 🤗';
    if (friendship >= 60) return 'Good Friends 😊';
    if (friendship >= 40) return 'Friends 👋';
    if (friendship >= 20) return 'Acquaintance 👤';
    return 'Stranger 👀';
  }

  Color _getFriendshipColor(int friendship) {
    if (friendship >= 95) return Colors.pinkAccent;
    if (friendship >= 80) return Colors.pink;
    if (friendship >= 60) return Colors.pink[300]!;
    if (friendship >= 40) return Colors.pink[200]!;
    if (friendship >= 20) return Colors.pink[100]!;
    return Colors.grey;
  }

  String _getIntelligenceLevel(int intelligence) {
    if (intelligence >= 80) return 'Genius 🧠';
    if (intelligence >= 60) return 'Smart 🎓';
    if (intelligence >= 40) return 'Clever 📚';
    if (intelligence >= 20) return 'Learning 📖';
    return 'Curious 🤔';
  }

  Color _getIntelligenceColor(int intelligence) {
    if (intelligence >= 80) return Colors.blueAccent;
    if (intelligence >= 60) return Colors.blue;
    if (intelligence >= 40) return Colors.blue[300]!;
    if (intelligence >= 20) return Colors.blue[200]!;
    return Colors.grey;
  }

  String _getSocialLevel(int social) {
    if (social >= 80) return 'Social Star ⭐';
    if (social >= 60) return 'Popular 🎉';
    if (social >= 40) return 'Friendly 😄';
    if (social >= 20) return 'Shy 😳';
    return 'Lonely 😔';
  }

  Color _getSocialColor(int social) {
    if (social >= 80) return Colors.greenAccent;
    if (social >= 60) return Colors.green;
    if (social >= 40) return Colors.green[300]!;
    if (social >= 20) return Colors.green[200]!;
    return Colors.grey;
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
        return '⭕';
      default:
        return '✨';
    }
  }

  Color _getMoodColor(PetMood mood) {
    switch (mood) {
      case PetMood.happy:
        return Colors.yellow;
      case PetMood.excited:
        return Colors.orange;
      case PetMood.sleepy:
        return Colors.purple;
      case PetMood.hungry:
        return Colors.red;
      case PetMood.sad:
        return Colors.blue;
      case PetMood.sick:
        return Colors.grey;
      case PetMood.playful:
        return Colors.green;
      case PetMood.loving:
        return Colors.pink;
    }
  }

  void _showItemsDialog(BuildContext context, GameProvider gameProvider) {
    final pet = gameProvider.pet!;
    final items = ['treat', 'toy', 'medicine', 'energy_drink'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎒 Inventory'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pet.inventory.isEmpty)
                const Text('No items in inventory')
              else
                Wrap(
                  spacing: 8,
                  children: pet.inventory.map((item) {
                    return Chip(
                      label: Text(item),
                      onDeleted: () {
                        gameProvider.useItem(item);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
              const Text(
                'Buy items:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...items.map(
                (item) => ListTile(
                  title: Text(item),
                  subtitle: Text('${item == 'medicine' ? '10' : '5'} coins'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      gameProvider.buyItem(item, item == 'medicine' ? 10 : 5);
                      Navigator.pop(context);
                    },
                    child: const Text('Buy'),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              gameProvider.playClickSound();
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSkillsDialog(BuildContext context, GameProvider gameProvider) {
    final pet = gameProvider.pet!;
    final skills = ['intelligence', 'strength', 'agility', 'charisma'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🏆 Skills'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: skills.map((skill) {
              final level = pet.skills[skill] ?? 0;
              return ListTile(
                title: Text(skill),
                subtitle: LinearProgressIndicator(value: level / 10),
                trailing: Text('Lv $level'),
                onTap: () {
                  if (level < 10) {
                    gameProvider.levelUpSkill(skill);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              gameProvider.playClickSound();
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAccessoriesDialog(BuildContext context, GameProvider gameProvider) {
    final pet = gameProvider.pet!;
    final accessories = ['hat', 'scarf', 'glasses', 'bow', 'collar'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('👗 Accessories'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (pet.accessories.isEmpty)
                const Text('No accessories owned')
              else
                Wrap(
                  spacing: 8,
                  children: pet.accessories.map((accessory) {
                    return FilterChip(
                      label: Text(accessory),
                      selected: pet.currentAccessory == accessory,
                      onSelected: (selected) {
                        if (selected) {
                          gameProvider.wearAccessory(accessory);
                        }
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
              const Text(
                'Buy accessories:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...accessories.map(
                (accessory) => ListTile(
                  title: Text(accessory),
                  subtitle: Text('20 gems'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      gameProvider.buyItem(accessory, 20, isGem: true);
                      if (pet.gems >= 20) {
                        gameProvider.addAccessory(accessory);
                      }
                      Navigator.pop(context);
                    },
                    child: const Text('Buy'),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              gameProvider.playClickSound();
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAchievementsDialog(
    BuildContext context,
    GameProvider gameProvider,
  ) {
    final pet = gameProvider.pet!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🏅 Achievements'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: pet.achievements.isEmpty
              ? const Center(child: Text('No achievements yet! Keep playing!'))
              : ListView.builder(
                  itemCount: pet.achievements.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: const Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                      ),
                      title: Text(pet.achievements[index]),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              gameProvider.playClickSound();
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _ActionItemWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionItemWidget({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80, // Increased height for better accessibility
        padding: const EdgeInsets.all(12), // Increased padding
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16), // Larger radius
          border: Border.all(
            color: color.withValues(alpha: 0.5),
            width: 2, // Thicker border for better visibility
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28), // Larger icon
            const SizedBox(height: 6), // More spacing
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 14, // Larger font for better readability
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
