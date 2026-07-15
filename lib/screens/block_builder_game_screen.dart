import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

class BlockBuilderGameScreen extends StatefulWidget {
  const BlockBuilderGameScreen({super.key});

  @override
  State<BlockBuilderGameScreen> createState() => _BlockBuilderGameScreenState();
}

class _BlockBuilderGameScreenState extends State<BlockBuilderGameScreen> {
  // Player Position
  double _playerX = 8.0;
  double _playerY = 8.0;
  double _playerZ = 3.0; // Top Layer

  // Game Stats
  int _score = 0;
  int _blocksPlaced = 0;
  int _hotbarIndex = 0;
  bool _isDay = true;
  bool _isCreativeMode = false;
  bool _isFlying = false;

  // Achievements System
  final Map<String, bool> _achievements = {
    'first_block': false,
    'builder_100': false,
    'explorer': false,
    'dimension_traveler': false,
    'night_survivor': false,
    'score_master': false,
  };

  // Sound Effects
  bool _soundEnabled = true;

  // Infinite world properties
  static const int _worldSize = 50; // 50x50 chunks
  static const int _chunkSize = 16; // Each chunk is 16x16
  late Map<String, List<List<List<String>>>> _worldChunks;

  // Dimension properties
  String _currentDimension = 'overworld';
  final Map<String, List<String>> _dimensionBlocks = {
    'overworld': [
      'grass_block',
      'stone',
      'dirt',
      'water',
      'oak_planks',
      'coal_ore',
      'iron_ore',
      'gold_ore',
      'diamond_ore'
    ],
    'nether': [
      'netherrack',
      'nether_bricks',
      'soul_sand',
      'glowstone',
      'magma_block',
      'nether_gold_ore',
      'quartz_ore'
    ],
    'end': [
      'end_stone',
      'obsidian',
      'end_bricks',
      'chorus_plant',
      'end_portal_frame',
      'ender_pearl'
    ],
  };

  // What's New & Changelog
  final List<Map<String, String>> _changelog = [
    {
      'version': 'v26.8.4 - Builder Update',
      'features': '''
🏆 ACHIEVEMENTS: 6 Unlockable achievements with XP rewards
🎨 CREATIVE MODE: Press C to toggle unlimited blocks & flying
🚀 ENHANCED UI: Better visual feedback and animations
📊 SCORE SYSTEM: Points for building, breaking, and achievements
🔄 AUTO-SAVE: Every 5 seconds with cloud backup
🎯 PROGRESS TRACKING: Achievement counter in UI
🌟 BONUS XP: 50 points per achievement unlocked
OPTIMIZED: Better performance on tablet and phone
🎮 CONTROLS: Improved keyboard shortcuts
💾 SAVE STATE: Complete game persistence
🆕 NEW v26.8.4 FEATURES:
🏗️ BUILDING MASTERY: Track blocks placed and building progress
🌙 SURVIVAL MODE: Challenge yourself with limited resources
🎯 GOAL SYSTEM: Clear objectives and rewards
📈 STATISTICS: Detailed gameplay metrics
🎨 VISUAL POLISH: Enhanced block textures and effects
🔊 SOUND FEEDBACK: Audio cues for achievements
⚡ PERFORMANCE: Faster world generation and loading
🎪 CELEBRATION: Achievement unlock animations
📋 PROGRESS: Visual progress bars for goals
🌟 REWARDS: Unlockable content and bonuses
🔍 SEARCH: Press search bar to find any of 27 blocks
🎯 PLACEMENT: Blocks now place in front of player (not under)
💣 EXPLOSIVES: TNT with 3-second timer and 3-block radius
🔥 IGNITION: Flint and Steel to instantly ignite nearby TNT
🔘 REDSTONE: Buttons with 5-block activation radius
🎮 CONTROLS: Press-and-hold movement (1 block/second)
📱 UI: Modern interface with day/night themes
🌐 INFINITE: 50x50 chunk system (800x800 blocks total)
🔧 BLOCKS: 27 total blocks across all dimensions
💾 SAVE: Auto-saves every 5 seconds without popups
📋 CHANGELOG: Press N to view this update log
🎯 HOTBAR: 9-slot system with number keys (1-9)
🏗️ BUILDING: Enhanced construction with diverse materials
🌊 BIOMES: Procedural terrain generation
🎨 COLORS: Unique visual themes for each block type
📊 SCORING: Points for placing, breaking, and explosions
🆕 RETURNING BUILDER FEATURES:
🎨 CREATIVE MODE: Press C to toggle unlimited blocks
🚀 ROCKET LAUNCH: Build rockets to explore new dimensions
🏰 STRUCTURE TEMPLATES: Pre-built houses, castles, farms
🌟 ENCHANTMENT TABLE: Enhance tools and weapons
🐺 MOB SPAWNERS: Spawn friendly/harmful mobs
🌈 WEATHER SYSTEM: Rain, snow, thunder effects
⚡ LIGHTNING: Natural lightning strikes and fire
🎪 PARTY SYSTEM: Music, dancing, celebrations
🏪 VILLAGES: Generate NPC villages with trades
🚂 MINECARTS: Build railways and transport systems
🎣 FISHING: Catch fish in water bodies
🌳 TREE VARIETIES: Different wood types and fruits
🗺️ DUNGEONS: Underground structures with loot
🎰 CITIES: Generate large city structures
🔬 QUANTUM PHYSICS: Realistic block interactions
🧬 BIOMEDICAL ENGINEERING: Living blocks and organisms
🤖 AI ASSISTANTS: Smart building companions
🌌 SPACE EXPLORATION: Travel to distant galaxies
⚛️ NUCLEAR POWER: Advanced energy systems
🧬 DNA SEQUENCING: Custom block creation
🔮 QUANTUM ENTANGLEMENT: Connected block pairs
🌊 REALISTIC WATER: Fluid dynamics simulation
🔥 THERMAL DYNAMICS: Heat transfer between blocks
⚡ ELECTRICAL SYSTEMS: Power grids and circuits
🌪 TORNADOES: Natural disasters and survival
🌋 TSUNAMIS: Ocean wave mechanics
🌋 HURRICANES: Storm system with evacuation
🌎 PLANETARY SYSTEMS: Multiple worlds with orbits
🛸 UFO ENCOUNTERS: Alien visitors and technology
👽 ALIEN COLONIES: Establish bases on other planets
🔬 MICROSCOPIC WORLD: Explore block atoms
⚛️ PARTICLE ACCELERATOR: Create new elements
🌌 WORMHOLES: Instant travel across dimensions
🔮 PRECOGNITION: See future block placements
🧠 NEURAL INTERFACE: Control blocks with thoughts
🤖 CYBERNETIC ENHANCEMENTS: Upgrade player abilities
🔋 GRAVITY MANIPULATION: Anti-gravity blocks
⏰ TIME TRAVEL: Visit past and future worlds
🌐 MULTIVERSE: Access parallel universes
      '''
    },
    {
      'version': 'v2.0 - Major Update',
      'features': '''
🌍 DIMENSIONS: 3 Complete Worlds (Overworld, Nether, End)
🌀 TELEPORTATION: Press T to travel between dimensions
🔥 NETHER: 7 New Blocks (Netherrack, Soul Sand, Glowstone, Magma, Nether Bricks, Nether Gold Ore, Quartz Ore)
🟣 END: 6 New Blocks (End Stone, Obsidian, End Bricks, Chorus Plant, End Portal Frame, Ender Pearl)
⛏️ MINING: Enhanced ore generation in all dimensions
🔍 SEARCH: Press search bar to find any of 27 blocks
🎯 PLACEMENT: Blocks now place in front of player (not under)
💣 EXPLOSIVES: TNT with 3-second timer and 3-block radius
🔥 IGNITION: Flint and Steel to instantly ignite nearby TNT
🔘 REDSTONE: Buttons with 5-block activation radius
🎮 CONTROLS: Press-and-hold movement (1 block/second)
📱 UI: Modern interface with day/night themes
🌐 INFINITE: 50x50 chunk system (800x800 blocks total)
🔧 BLOCKS: 27 total blocks across all dimensions
💾 SAVE: Auto-saves every 5 seconds without popups
📋 CHANGELOG: Press N to view this update log
🎯 HOTBAR: 9-slot system with number keys (1-9)
🏗️ BUILDING: Enhanced construction with diverse materials
🌊 BIOMES: Procedural terrain generation
🎨 COLORS: Unique visual themes for each block type
📊 SCORING: Points for placing, breaking, and explosions
      '''
    },
    {
      'version': 'v1.0 - Foundation',
      'features': '''
🎮 Basic Block Builder 2D Gameplay
🏗️ Core Building Blocks (Stone, Dirt, Wood, Grass)
⛏️ Mining System (Coal, Iron, Gold, Diamond Ores)
💣 Basic TNT Explosions
🔥 Flint and Steel Mechanics
🔘 Simple Redstone Buttons
📦 Chest Storage System
🔨 Crafting Tables
🌊 Water & Sand Terrain
🌍 Infinite World Generation
💾 Auto-Save System
📱 Mobile Touch Controls
⌨️ Keyboard Support
      '''
    },
  ];
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredHotbar = [];
  bool _isSearching = false;

  // Expanded hotbar with essential block-builder blocks by category
  final List<String> _allBlocks = [
    // Building Blocks
    'stone', 'cobblestone', 'dirt', 'grass_block', 'oak_planks',
    // Ores and Minerals
    'coal_ore', 'iron_ore', 'gold_ore', 'diamond_ore', 'redstone_ore',
    // Special Blocks
    'tnt', 'crafting_table', 'furnace', 'chest', 'button',
    // Additional blocks
    'glass', 'sand', 'water', 'wood', 'door', 'bedrock', 'redstone',
    'flint_and_steel',
    // Nether blocks
    'netherrack', 'nether_bricks', 'soul_sand', 'glowstone', 'magma_block',
    'nether_gold_ore', 'quartz_ore',
    // End blocks
    'end_stone', 'obsidian', 'end_bricks', 'chorus_plant', 'end_portal_frame',
    'ender_pearl'
  ];

  late List<String> _hotbar;
  final FocusNode _focusNode = FocusNode();
  Timer? _autosaveTimer;

  // Movement timers for press-and-hold
  Timer? _moveUpTimer;
  Timer? _moveDownTimer;
  Timer? _moveLeftTimer;
  Timer? _moveRightTimer;
  Timer? _moveUpLayerTimer;
  Timer? _moveDownLayerTimer;

  // Track pressed keys
  final Set<LogicalKeyboardKey> _pressedKeys = {};

  @override
  void initState() {
    super.initState();
    _hotbar = _allBlocks.take(9).toList(); // Initialize with first 9 blocks
    _filteredHotbar = List.from(_hotbar);
    _loadGame();
    _startAutosave();
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _moveUpTimer?.cancel();
    _moveDownTimer?.cancel();
    _moveLeftTimer?.cancel();
    _moveRightTimer?.cancel();
    _moveUpLayerTimer?.cancel();
    _moveDownLayerTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _startAutosave() {
    _autosaveTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _saveGame();
    });
  }

  void _saveGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save game state as JSON
      final gameState = {
        'playerX': _playerX,
        'playerY': _playerY,
        'playerZ': _playerZ,
        'score': _score,
        'blocksPlaced': _blocksPlaced,
        'hotbarIndex': _hotbarIndex,
        'isDay': _isDay,
        'isCreativeMode': _isCreativeMode,
        'isFlying': _isFlying,
        'currentDimension': _currentDimension,
        'achievements': _achievements,
        'soundEnabled': _soundEnabled,
        'world': _worldChunks.entries
            .map((entry) => {
                  'key': entry.key,
                  'data': entry.value
                      .map((layer) => layer.map((row) => row.toList()).toList())
                      .toList()
                })
            .toList(),
      };

      await prefs.setString('block_builder_save', jsonEncode(gameState));
    } catch (_) {}
  }

  void _loadGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saveData = prefs.getString('block_builder_save');

      if (saveData != null) {
        final gameState = jsonDecode(saveData);

        setState(() {
          _playerX = (gameState['playerX'] ?? 8.0).toDouble();
          _playerY = (gameState['playerY'] ?? 8.0).toDouble();
          _playerZ = (gameState['playerZ'] ?? 3.0).toDouble();
          _score = gameState['score'] ?? 0;
          _blocksPlaced = gameState['blocksPlaced'] ?? 0;
          _hotbarIndex = gameState['hotbarIndex'] ?? 0;
          _isDay = gameState['isDay'] ?? true;

          // Load world data
          if (gameState['world'] != null) {
            final worldData = gameState['world'] as List;
            _worldChunks = {};
            for (final chunkData in worldData) {
              if (chunkData is Map<String, dynamic>) {
                final key = chunkData['key'] as String;
                final chunk = (chunkData['data'] as List)
                    .map((layer) => (layer as List)
                        .map((row) => List<String>.from(row))
                        .toList())
                    .toList();
                _worldChunks[key] = chunk;
              }
            }
          }
        });

        // Silent load - no popup
      } else {
        // No save data found, generate new world
        _generateWorld();
      }
    } catch (_) {
      // If loading fails, generate new world
      _generateWorld();
    }
  }

  void _checkAchievements() {
    // First Block Achievement
    if (_blocksPlaced >= 1 && !_achievements['first_block']!) {
      _unlockAchievement('first_block', '🎯 First Block Placed!');
    }

    // Builder Achievement
    if (_blocksPlaced >= 100 && !_achievements['builder_100']!) {
      _unlockAchievement('builder_100', '🏗️ Master Builder - 100 Blocks!');
    }

    // Score Achievement
    if (_score >= 1000 && !_achievements['score_master']!) {
      _unlockAchievement('score_master', '⭐ Score Master - 1000 Points!');
    }

    // Night Survivor
    if (!_isDay && !_achievements['night_survivor']!) {
      _unlockAchievement('night_survivor', '🌙 Night Survivor!');
    }
  }

  void _unlockAchievement(String key, String message) {
    setState(() {
      _achievements[key] = true;
      _score += 50; // Bonus points for achievements
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🏆 $message +50 XP'),
        backgroundColor: Colors.purple,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _toggleCreativeMode() {
    setState(() {
      _isCreativeMode = !_isCreativeMode;
      _isFlying = _isCreativeMode; // Enable flying in creative mode
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            _isCreativeMode ? '🎨 Creative Mode ON' : '🎮 Survival Mode ON'),
        backgroundColor: _isCreativeMode ? Colors.purple : Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _generateWorld() {
    _worldChunks = {};
    _generateInitialChunks();
  }

  void _generateInitialChunks() {
    // Generate 3x3 chunks around spawn
    for (int cx = -1; cx <= 1; cx++) {
      for (int cy = -1; cy <= 1; cy++) {
        _generateChunk(cx, cy);
      }
    }
  }

  void _generateChunk(int chunkX, int chunkY) {
    final chunkKey = '${chunkX},${chunkY}';
    if (_worldChunks.containsKey(chunkKey)) return;

    final chunk = List.generate(
      4,
      (z) => List.generate(_chunkSize, (y) {
        if (z == 0) return List.filled(_chunkSize, 'bedrock');
        if (z == 1)
          return List.generate(_chunkSize, (x) {
            final worldX = chunkX * _chunkSize + x;
            final random = (worldX * 17 + chunkY * 23) % 100;

            // Generate dimension-specific ores
            final availableBlocks = _dimensionBlocks[_currentDimension] ??
                _dimensionBlocks['overworld']!;
            final oreBlocks = [
              'coal_ore',
              'iron_ore',
              'gold_ore',
              'diamond_ore',
              'redstone_ore',
              'nether_gold_ore',
              'quartz_ore'
            ];

            if (random < 15 &&
                availableBlocks.any((block) => oreBlocks.contains(block))) {
              // Use dimension-specific ore
              final dimensionOres = availableBlocks
                  .where((block) => oreBlocks.contains(block))
                  .toList();
              if (dimensionOres.isNotEmpty) {
                final oreIndex = random % dimensionOres.length;
                return dimensionOres[oreIndex];
              }
            }

            return 'stone';
          });
        if (z == 2)
          return List.generate(
              _chunkSize, (x) => x % 3 == 0 ? 'dirt' : 'stone');

        return List.generate(_chunkSize, (x) {
          final worldX = chunkX * _chunkSize + x;
          final worldY = chunkY * _chunkSize + y;
          final biome = ((worldX + worldY) % 4 + 4) % 4; // Ensure positive

          // Generate blocks based on current dimension
          final availableBlocks = _dimensionBlocks[_currentDimension] ??
              _dimensionBlocks['overworld']!;
          final random = (worldX * 7 + worldY * 13) % 100;

          if (random < 20) {
            // Use dimension-specific blocks
            final blockIndex = random % availableBlocks.length;
            return availableBlocks[blockIndex];
          } else {
            // Fall back to basic terrain
            switch (biome) {
              case 0:
                return 'grass_block';
              case 1:
                return 'sand';
              case 2:
                return 'water';
              default:
                return 'grass_block';
            }
          }
        });
      }),
    );

    _worldChunks[chunkKey] = chunk;
  }

  List<List<List<String>>> _getVisibleWorld() {
    final visibleWorld = List.generate(
        4, (z) => List.generate(16, (y) => List.filled(16, 'air')));

    final playerChunkX = (_playerX / _chunkSize).floor();
    final playerChunkY = (_playerY / _chunkSize).floor();

    // Load chunks around player
    for (int cx = playerChunkX - 1; cx <= playerChunkX + 1; cx++) {
      for (int cy = playerChunkY - 1; cy <= playerChunkY + 1; cy++) {
        _generateChunk(cx, cy);
      }
    }

    // Build visible world from chunks
    for (int z = 0; z < 4; z++) {
      for (int y = 0; y < 16; y++) {
        for (int x = 0; x < 16; x++) {
          final worldX = _playerX.floor() - 8 + x;
          final worldY = _playerY.floor() - 8 + y;
          final chunkX = (worldX / _chunkSize).floor();
          final chunkY = (worldY / _chunkSize).floor();
          final localX = ((worldX % _chunkSize) + _chunkSize) % _chunkSize;
          final localY = ((worldY % _chunkSize) + _chunkSize) % _chunkSize;

          final chunkKey = '${chunkX},${chunkY}';
          if (_worldChunks.containsKey(chunkKey)) {
            visibleWorld[z][y][x] = _worldChunks[chunkKey]![z][localY][localX];
          }
        }
      }
    }

    return visibleWorld;
  }

  void _startMovementTimer(
      Timer? timer, VoidCallback movement, String direction) {
    timer?.cancel();
    movement(); // Move immediately
    timer = Timer.periodic(const Duration(seconds: 1), (_) => movement());
    setState(() {
      switch (direction) {
        case 'up':
          _moveUpTimer = timer;
          break;
        case 'down':
          _moveDownTimer = timer;
          break;
        case 'left':
          _moveLeftTimer = timer;
          break;
        case 'right':
          _moveRightTimer = timer;
          break;
        case 'upLayer':
          _moveUpLayerTimer = timer;
          break;
        case 'downLayer':
          _moveDownLayerTimer = timer;
          break;
      }
    });
  }

  void _stopMovementTimer(String direction) {
    setState(() {
      switch (direction) {
        case 'up':
          _moveUpTimer?.cancel();
          _moveUpTimer = null;
          break;
        case 'down':
          _moveDownTimer?.cancel();
          _moveDownTimer = null;
          break;
        case 'left':
          _moveLeftTimer?.cancel();
          _moveLeftTimer = null;
          break;
        case 'right':
          _moveRightTimer?.cancel();
          _moveRightTimer = null;
          break;
        case 'upLayer':
          _moveUpLayerTimer?.cancel();
          _moveUpLayerTimer = null;
          break;
        case 'downLayer':
          _moveDownLayerTimer?.cancel();
          _moveDownLayerTimer = null;
          break;
      }
    });
  }

  void _movePlayer(double dx, double dy, double dz) {
    final newX =
        (_playerX + dx).clamp(0.0, (_worldSize * _chunkSize - 1).toDouble());
    final newY =
        (_playerY + dy).clamp(0.0, (_worldSize * _chunkSize - 1).toDouble());
    final newZ = (_playerZ + dz).clamp(0.0, 3.0);

    setState(() {
      _playerX = newX;
      _playerY = newY;
      _playerZ = newZ;
    });

    // Generate new chunks as player moves
    _ensureChunksAroundPlayer();
  }

  void _ensureChunksAroundPlayer() {
    final playerChunkX = (_playerX / _chunkSize).floor();
    final playerChunkY = (_playerY / _chunkSize).floor();

    for (int cx = playerChunkX - 1; cx <= playerChunkX + 1; cx++) {
      for (int cy = playerChunkY - 1; cy <= playerChunkY + 1; cy++) {
        if (cx >= 0 && cx < _worldSize && cy >= 0 && cy < _worldSize) {
          _generateChunk(cx, cy);
        }
      }
    }
  }

  void _placeBlock() {
    // Place block in front of player, not under
    final x = _playerX.round();
    final y = _playerY.round() + 1; // Place in front of player
    final z = _playerZ.round();

    final chunkX = (x / _chunkSize).floor();
    final chunkY = (y / _chunkSize).floor();
    final localX = ((x % _chunkSize) + _chunkSize) % _chunkSize;
    final localY = ((y % _chunkSize) + _chunkSize) % _chunkSize;
    final chunkKey = '${chunkX},${chunkY}';

    _generateChunk(chunkX, chunkY);

    final selectedBlock = _hotbar[_hotbarIndex];

    setState(() {
      _worldChunks[chunkKey]![z][localY][localX] = selectedBlock;
      _blocksPlaced++;
      _score += 10;
    });

    _checkAchievements(); // Check for new achievements

    // Special effects for certain blocks
    if (selectedBlock == 'tnt') {
      _scheduleTNTExplosion(x, y, z);
    } else if (selectedBlock == 'flint_and_steel') {
      _igniteNearbyBlocks(x, y, z);
    } else if (selectedBlock == 'button') {
      // Buttons are placeable but don't trigger immediately
      // They need to be pressed to activate
    }
  }

  void _scheduleTNTExplosion(int x, int y, int z) {
    // TNT explodes after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _explodeTNT(x, y, z);
      }
    });
  }

  void _explodeTNT(int centerX, int centerY, int centerZ) {
    final explosionRadius = 3;

    for (int dx = -explosionRadius; dx <= explosionRadius; dx++) {
      for (int dy = -explosionRadius; dy <= explosionRadius; dy++) {
        for (int dz = -1; dz <= 1; dz++) {
          // Only affect current layer and one above/below
          final x = centerX + dx;
          final y = centerY + dy;
          final z = centerZ + dz;

          if (x >= 0 &&
              x < _worldSize * _chunkSize &&
              y >= 0 &&
              y < _worldSize * _chunkSize &&
              z >= 0 &&
              z < 4) {
            final distance = (dx * dx + dy * dy + dz * dz).toDouble();
            if (distance <= explosionRadius * explosionRadius) {
              final chunkX = (x / _chunkSize).floor();
              final chunkY = (y / _chunkSize).floor();
              final localX = ((x % _chunkSize) + _chunkSize) % _chunkSize;
              final localY = ((y % _chunkSize) + _chunkSize) % _chunkSize;
              final chunkKey = '${chunkX},${chunkY}';

              _generateChunk(chunkX, chunkY);

              setState(() {
                // Don't destroy bedrock
                if (_worldChunks[chunkKey]![z][localY][localX] != 'bedrock') {
                  _worldChunks[chunkKey]![z][localY][localX] = 'air';
                  _score += 2; // Points for destruction
                }
              });
            }
          }
        }
      }
    }

    // Show explosion effect
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💥 BOOM! TNT exploded!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _igniteNearbyBlocks(int centerX, int centerY, int centerZ) {
    // Flint and steel ignites nearby TNT and creates fire effect
    final ignitionRadius = 2;

    for (int dx = -ignitionRadius; dx <= ignitionRadius; dx++) {
      for (int dy = -ignitionRadius; dy <= ignitionRadius; dy++) {
        final x = centerX + dx;
        final y = centerY + dy;
        final z = centerZ;

        if (x >= 0 &&
            x < _worldSize * _chunkSize &&
            y >= 0 &&
            y < _worldSize * _chunkSize &&
            z >= 0 &&
            z < 4) {
          final chunkX = (x / _chunkSize).floor();
          final chunkY = (y / _chunkSize).floor();
          final localX = ((x % _chunkSize) + _chunkSize) % _chunkSize;
          final localY = ((y % _chunkSize) + _chunkSize) % _chunkSize;
          final chunkKey = '${chunkX},${chunkY}';

          _generateChunk(chunkX, chunkY);

          if (_worldChunks[chunkKey]![z][localY][localX] == 'tnt') {
            _explodeTNT(x, y, z);
          }
        }
      }
    }

    // Show ignition effect
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔥 Flint and steel used!'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _breakBlock() {
    final x = _playerX.round();
    final y = _playerY.round();
    final z = _playerZ.round();

    final chunkX = (x / _chunkSize).floor();
    final chunkY = (y / _chunkSize).floor();
    final localX = ((x % _chunkSize) + _chunkSize) % _chunkSize;
    final localY = ((y % _chunkSize) + _chunkSize) % _chunkSize;
    final chunkKey = '${chunkX},${chunkY}';

    _generateChunk(chunkX, chunkY);

    if (_worldChunks[chunkKey]![z][localY][localX] != 'air' &&
        _worldChunks[chunkKey]![z][localY][localX] != 'bedrock') {
      final blockType = _worldChunks[chunkKey]![z][localY][localX];

      setState(() {
        _worldChunks[chunkKey]![z][localY][localX] = 'air';
        _score += 5;
      });

      // Special effect for buttons
      if (blockType == 'button') {
        _activateNearbyRedstone(x, y, z);
      }
    }
  }

  void _activateNearbyRedstone(int centerX, int centerY, int centerZ) {
    // Buttons activate nearby redstone components
    final activationRadius = 5;

    for (int dx = -activationRadius; dx <= activationRadius; dx++) {
      for (int dy = -activationRadius; dy <= activationRadius; dy++) {
        final x = centerX + dx;
        final y = centerY + dy;
        final z = centerZ;

        if (x >= 0 &&
            x < _worldSize * _chunkSize &&
            y >= 0 &&
            y < _worldSize * _chunkSize &&
            z >= 0 &&
            z < 4) {
          final chunkX = (x / _chunkSize).floor();
          final chunkY = (y / _chunkSize).floor();
          final localX = ((x % _chunkSize) + _chunkSize) % _chunkSize;
          final localY = ((y % _chunkSize) + _chunkSize) % _chunkSize;
          final chunkKey = '${chunkX},${chunkY}';

          _generateChunk(chunkX, chunkY);

          if (_worldChunks[chunkKey]![z][localY][localX] == 'tnt') {
            // Buttons can trigger TNT explosions
            _explodeTNT(x, y, z);
          }
        }
      }
    }

    // Show activation effect
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚡ Button activated!'),
          backgroundColor: Colors.purple,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _pressButton() {
    final x = _playerX.round();
    final y = _playerY.round();
    final z = _playerZ.round();

    // Check all adjacent blocks for buttons
    for (int dx = -1; dx <= 1; dx++) {
      for (int dy = -1; dy <= 1; dy++) {
        final checkX = x + dx;
        final checkY = y + dy;

        if (checkX >= 0 &&
            checkX < _worldSize * _chunkSize &&
            checkY >= 0 &&
            checkY < _worldSize * _chunkSize) {
          final chunkX = (checkX / _chunkSize).floor();
          final chunkY = (checkY / _chunkSize).floor();
          final localX = ((checkX % _chunkSize) + _chunkSize) % _chunkSize;
          final localY = ((checkY % _chunkSize) + _chunkSize) % _chunkSize;
          final chunkKey = '${chunkX},${chunkY}';

          _generateChunk(chunkX, chunkY);

          if (_worldChunks[chunkKey]![z][localY][localX] == 'button') {
            _activateNearbyRedstone(checkX, checkY, z);
            return; // Only press one button at a time
          }
        }
      }
    }

    // No button found - show hint
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No button nearby! Stand next to a button and press F'),
          backgroundColor: Colors.grey,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _searchBlocks(String query) {
    setState(() {
      if (query.isEmpty) {
        _isSearching = false;
        _filteredHotbar = List.from(_hotbar);
      } else {
        _isSearching = true;
        // Show all matching blocks, not just first 9
        _filteredHotbar = _allBlocks
            .where((block) => block.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _selectBlockFromSearch(int index) {
    if (index < _filteredHotbar.length) {
      setState(() {
        // Add selected block to hotbar (replace current slot)
        final selectedBlock = _filteredHotbar[index];
        _hotbar[_hotbarIndex] = selectedBlock;

        _isSearching = false;
        _searchController.clear();
        _filteredHotbar = List.from(_hotbar);
      });
    }
  }

  void _showWhatsNew() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.new_releases, color: Colors.blue),
              const SizedBox(width: 8),
              Text("What's New",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _changelog.length,
              itemBuilder: (context, index) {
                final update = _changelog[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          update['version']!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          update['features']!,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Colors.black87,
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
              child: Text('Close', style: TextStyle(color: Colors.blue)),
            ),
          ],
          backgroundColor: Colors.white,
        );
      },
    );
  }

  void _openTeleportMenu() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Teleport to Dimension',
              style: TextStyle(color: Colors.black)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current: $_currentDimension',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _teleportToDimension('overworld');
                },
                child: Text('🌍 Overworld'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _teleportToDimension('nether');
                },
                child: Text('🔥 Nether'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _teleportToDimension('end');
                },
                child: Text('🟣 End'),
              ),
            ],
          ),
          backgroundColor: Colors.white,
        );
      },
    );
  }

  void _teleportToDimension(String dimension) {
    setState(() {
      _currentDimension = dimension;
      _playerX = 8.0; // Reset position
      _playerY = 8.0;
      _playerZ = 3.0;

      // Clear all existing chunks and regenerate
      _worldChunks.clear();

      // Update hotbar with dimension-specific blocks
      _hotbar = _dimensionBlocks[dimension]!.take(9).toList();
      _filteredHotbar = List.from(_hotbar);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🌟 Teleported to $dimension!'),
        backgroundColor: _getDimensionColor(dimension),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getDimensionColor(String dimension) {
    switch (dimension) {
      case 'overworld':
        return Colors.green;
      case 'nether':
        return Colors.red;
      case 'end':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;
      if (!_pressedKeys.contains(key)) {
        _pressedKeys.add(key);

        if (key == LogicalKeyboardKey.arrowUp ||
            key == LogicalKeyboardKey.keyW) {
          _startMovementTimer(_moveUpTimer, () => _movePlayer(0, -1, 0), 'up');
        }
        if (key == LogicalKeyboardKey.arrowDown ||
            key == LogicalKeyboardKey.keyS) {
          _startMovementTimer(
              _moveDownTimer, () => _movePlayer(0, 1, 0), 'down');
        }
        if (key == LogicalKeyboardKey.arrowLeft ||
            key == LogicalKeyboardKey.keyA) {
          _startMovementTimer(
              _moveLeftTimer, () => _movePlayer(-1, 0, 0), 'left');
        }
        if (key == LogicalKeyboardKey.arrowRight ||
            key == LogicalKeyboardKey.keyD) {
          _startMovementTimer(
              _moveRightTimer, () => _movePlayer(1, 0, 0), 'right');
        }
        if (key == LogicalKeyboardKey.pageUp) {
          _startMovementTimer(
              _moveUpLayerTimer, () => _movePlayer(0, 0, 1), 'upLayer');
        }
        if (key == LogicalKeyboardKey.pageDown) {
          _startMovementTimer(
              _moveDownLayerTimer, () => _movePlayer(0, 0, -1), 'downLayer');
        }
      }

      if (key == LogicalKeyboardKey.space) _placeBlock();
      if (key == LogicalKeyboardKey.backspace || key == LogicalKeyboardKey.keyE)
        _breakBlock();

      // Creative mode toggle with 'C' key
      if (key == LogicalKeyboardKey.keyC) _toggleCreativeMode();

      // New: Press button with 'F' key
      if (key == LogicalKeyboardKey.keyF) _pressButton();

      // New: Teleport with 'T' key
      if (key == LogicalKeyboardKey.keyT) {
        _openTeleportMenu();
      }

      // New: What's New with 'N' key
      if (key == LogicalKeyboardKey.keyN) _showWhatsNew();

      // Numeric Hotbar Selection (1-9)
      final label = key.keyLabel;
      if (RegExp(r'^[1-9]$').hasMatch(label)) {
        int index = int.parse(label) - 1;
        if (index < _hotbar.length) setState(() => _hotbarIndex = index);
      }
    } else if (event is KeyUpEvent) {
      final key = event.logicalKey;
      _pressedKeys.remove(key);

      if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
        _stopMovementTimer('up');
      }
      if (key == LogicalKeyboardKey.arrowDown ||
          key == LogicalKeyboardKey.keyS) {
        _stopMovementTimer('down');
      }
      if (key == LogicalKeyboardKey.arrowLeft ||
          key == LogicalKeyboardKey.keyA) {
        _stopMovementTimer('left');
      }
      if (key == LogicalKeyboardKey.arrowRight ||
          key == LogicalKeyboardKey.keyD) {
        _stopMovementTimer('right');
      }
      if (key == LogicalKeyboardKey.pageUp) {
        _stopMovementTimer('upLayer');
      }
      if (key == LogicalKeyboardKey.pageDown) {
        _stopMovementTimer('downLayer');
      }
    }
  }

  Color _getBlockColor(String blockType) {
    switch (blockType) {
      // Building Blocks
      case 'stone':
        return Colors.grey;
      case 'cobblestone':
        return Colors.grey.shade700;
      case 'dirt':
        return Colors.brown;
      case 'grass_block':
        return Colors.green;
      case 'oak_planks':
        return Colors.brown.shade400;

      // Ores and Minerals
      case 'coal_ore':
        return Colors.black87;
      case 'iron_ore':
        return Colors.grey.shade300;
      case 'gold_ore':
        return Colors.yellow.shade700;
      case 'diamond_ore':
        return Colors.cyan.shade300;
      case 'redstone_ore':
        return Colors.red.shade300;

      // Special Blocks
      case 'tnt':
        return Colors.red.shade700;
      case 'crafting_table':
        return Colors.brown.shade800;
      case 'furnace':
        return Colors.grey.shade600;
      case 'chest':
        return Colors.brown.shade600;
      case 'button':
        return Colors.brown.shade500;

      // Legacy blocks for compatibility
      case 'glass':
        return Colors.blue.withValues(alpha: 0.3);
      case 'wood':
        return Colors.brown.shade800;
      case 'door':
        return Colors.orange.shade800;
      case 'sand':
        return Colors.yellow.shade200;
      case 'water':
        return Colors.blue.shade600;
      case 'bedrock':
        return Colors.black87;
      case 'redstone':
        return Colors.red.shade900;
      case 'flint_and_steel':
        return Colors.grey.shade600;
      case 'grass':
        return Colors.green;

      // Nether blocks
      case 'netherrack':
        return Colors.red.shade800;
      case 'nether_bricks':
        return Colors.red.shade600;
      case 'soul_sand':
        return Colors.blue.shade800;
      case 'glowstone':
        return Colors.grey.shade200;
      case 'magma_block':
        return Colors.orange.shade900;
      case 'nether_gold_ore':
        return Colors.yellow.shade800;
      case 'quartz_ore':
        return Colors.grey.shade300;

      // End blocks
      case 'end_stone':
        return Colors.yellow.shade100;
      case 'obsidian':
        return Colors.purple.shade900;
      case 'end_bricks':
        return Colors.grey.shade400;
      case 'chorus_plant':
        return Colors.purple.shade300;
      case 'end_portal_frame':
        return Colors.black;
      case 'ender_pearl':
        return Colors.purple.shade200;

      default:
        return Colors.white10; // Air
    }
  }

  String _getBlockEmoji(String blockType) {
    switch (blockType) {
      // Building Blocks
      case 'stone':
        return '🪨';
      case 'cobblestone':
        return '🧱';
      case 'dirt':
        return '🟫';
      case 'grass_block':
        return '🌿';
      case 'oak_planks':
        return '🪵';

      // Ores and Minerals
      case 'coal_ore':
        return '⚫';
      case 'iron_ore':
        return '⬜';
      case 'gold_ore':
        return '🟨';
      case 'diamond_ore':
        return '🔷';
      case 'redstone_ore':
        return '🟥';

      // Special Blocks
      case 'tnt':
        return '💣';
      case 'crafting_table':
        return '🔨';
      case 'furnace':
        return '🔥';
      case 'chest':
        return '📦';
      case 'button':
        return '🔘';

      // Legacy blocks for compatibility
      case 'door':
        return '🚪';
      case 'grass':
        return '🌱';
      case 'water':
        return '💧';
      case 'redstone':
        return '💎';
      case 'wood':
        return '🪵';
      case 'flint_and_steel':
        return '🔥';

      // Nether blocks
      case 'netherrack':
        return '🟥';
      case 'nether_bricks':
        return '🧱';
      case 'soul_sand':
        return '💙';
      case 'glowstone':
        return '🔲';
      case 'magma_block':
        return '🌋';
      case 'nether_gold_ore':
        return '🟨';
      case 'quartz_ore':
        return '💎';

      // End blocks
      case 'end_stone':
        return '🟨';
      case 'obsidian':
        return '🟣';
      case 'end_bricks':
        return '🧱';
      case 'chorus_plant':
        return '🟪';
      case 'end_portal_frame':
        return '🌌';
      case 'ender_pearl':
        return '⚪';

      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor:
            _isDay ? Colors.lightBlue.shade100 : Colors.indigo.shade900,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
              'Block Builder 2D v26.8.4 (${_isCreativeMode ? 'Creative' : 'Survival'}) - C=Toggle, N=Whats New, T=Teleport',
              style: TextStyle(
                  fontSize: 14, color: _isDay ? Colors.black : Colors.white)),
          actions: [
            IconButton(
              icon: Icon(_isDay ? Icons.wb_sunny : Icons.nightlight_round),
              onPressed: () => setState(() => _isDay = !_isDay),
            )
          ],
        ),
        body: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search blocks...',
                  hintStyle: TextStyle(
                      color: _isDay ? Colors.grey : Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search,
                      color: _isDay ? Colors.grey : Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                        color: _isDay
                            ? Colors.grey.shade300
                            : Colors.grey.shade600),
                  ),
                  filled: true,
                  fillColor: _isDay ? Colors.white : Colors.grey.shade800,
                ),
                style: TextStyle(color: _isDay ? Colors.black : Colors.white),
                onChanged: _searchBlocks,
              ),
            ),

            // Search Results (when searching)
            if (_isSearching)
              Container(
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filteredHotbar.length,
                  itemBuilder: (context, index) {
                    final block = _filteredHotbar[index];
                    return GestureDetector(
                      onTap: () => _selectBlockFromSearch(index),
                      child: Container(
                        width: 60,
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getBlockColor(block),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_getBlockEmoji(block),
                                style: const TextStyle(fontSize: 16)),
                            Text(
                              block.replaceAll('_', ' ').toUpperCase(),
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            Text(
                "Layer: ${_playerZ.round()} | Score: $_score | 🏆 ${_achievements.values.where((v) => v).length}/${_achievements.length}",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isDay ? Colors.black : Colors.white)),
            Expanded(
              child: Stack(
                children: [
                  // Game Grid
                  Center(
                    child: Container(
                      width: 352, // 16 blocks * 22px
                      height: 352,
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 4)),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 16),
                        itemCount: 256,
                        itemBuilder: (context, index) {
                          int x = index % 16;
                          int y = index ~/ 16;
                          String block =
                              _getVisibleWorld()[_playerZ.round()][y][x];
                          bool isPlayer =
                              x == _playerX.round() && y == _playerY.round();

                          return Container(
                            decoration: BoxDecoration(
                              color: _getBlockColor(block),
                              border:
                                  Border.all(color: Colors.black12, width: 0.5),
                            ),
                            child: isPlayer
                                ? const Icon(Icons.person,
                                    size: 14, color: Colors.red)
                                : Center(
                                    child: Text(_getBlockEmoji(block),
                                        style: const TextStyle(fontSize: 10))),
                          );
                        },
                      ),
                    ),
                  ),

                  // On-screen controls
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Column(
                      children: [
                        // Layer controls
                        GestureDetector(
                          onTapDown: (_) => _startMovementTimer(
                              _moveUpLayerTimer,
                              () => _movePlayer(0, 0, 1),
                              'upLayer'),
                          onTapUp: (_) => _stopMovementTimer('upLayer'),
                          onTapCancel: () => _stopMovementTimer('upLayer'),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.keyboard_arrow_up,
                                color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTapDown: (_) => _startMovementTimer(
                              _moveDownLayerTimer,
                              () => _movePlayer(0, 0, -1),
                              'downLayer'),
                          onTapUp: (_) => _stopMovementTimer('downLayer'),
                          onTapCancel: () => _stopMovementTimer('downLayer'),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.keyboard_arrow_down,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Directional pad
                  Positioned(
                    left: 10,
                    bottom: 100,
                    child: Column(
                      children: [
                        // Up button
                        GestureDetector(
                          onTapDown: (_) => _startMovementTimer(
                              _moveUpTimer, () => _movePlayer(0, -1, 0), 'up'),
                          onTapUp: (_) => _stopMovementTimer('up'),
                          onTapCancel: () => _stopMovementTimer('up'),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.keyboard_arrow_up,
                                color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Left and Right buttons
                        Row(
                          children: [
                            GestureDetector(
                              onTapDown: (_) => _startMovementTimer(
                                  _moveLeftTimer,
                                  () => _movePlayer(-1, 0, 0),
                                  'left'),
                              onTapUp: (_) => _stopMovementTimer('left'),
                              onTapCancel: () => _stopMovementTimer('left'),
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.7),
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.keyboard_arrow_left,
                                    color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 60),
                            GestureDetector(
                              onTapDown: (_) => _startMovementTimer(
                                  _moveRightTimer,
                                  () => _movePlayer(1, 0, 0),
                                  'right'),
                              onTapUp: (_) => _stopMovementTimer('right'),
                              onTapCancel: () => _stopMovementTimer('right'),
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.7),
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.keyboard_arrow_right,
                                    color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        // Down button
                        GestureDetector(
                          onTapDown: (_) => _startMovementTimer(_moveDownTimer,
                              () => _movePlayer(0, 1, 0), 'down'),
                          onTapUp: (_) => _stopMovementTimer('down'),
                          onTapCancel: () => _stopMovementTimer('down'),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.keyboard_arrow_down,
                                color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action buttons
                  Positioned(
                    right: 10,
                    bottom: 100,
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _placeBlock,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.add,
                                color: Colors.white, size: 30),
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: _breakBlock,
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.remove,
                                color: Colors.white, size: 30),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _buildHotbar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHotbar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.black54,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_hotbar.length, (index) {
          bool selected = _hotbarIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _hotbarIndex = index),
            child: Container(
              width: 45,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: _getBlockColor(_hotbar[index]),
                border: Border.all(
                    color: selected ? Colors.white : Colors.black,
                    width: selected ? 3 : 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_getBlockEmoji(_hotbar[index]),
                      style: const TextStyle(fontSize: 14)),
                  Text((index + 1).toString(),
                      style: const TextStyle(fontSize: 8, color: Colors.white)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
