import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet.dart';
import '../services/sound_service.dart';

class GameProvider extends ChangeNotifier {
  Pet? _pet;
  bool _soundEnabled = true;
  bool _darkModeEnabled = false;
  bool _liteModeEnabled = false;
  Timer? _gameTimer;
  Timer? _petPlayTimeTimer;
  Timer? _sessionTimer;
  final SoundService _soundService = SoundService();
  static const String _currentVersion = '26.8.6';

  // Comprehensive Stats System
  Map<String, dynamic> _globalStats = {
    'totalPlayTime': 0, // in minutes
    'totalScore': 0,
    'gamesPlayed': 0,
    'achievementsUnlocked': 0,
    'blockBuilderStats': {
      'blocksPlaced': 0,
      'blocksBroken': 0,
      'deaths': 0,
      'highestScore': 0,
      'worldsCreated': 0,
    },
    'petStats': {
      'petsOwned': 0,
      'petsEvolved': 0,
      'totalFed': 0,
      'totalPlayed': 0,
      'happinessLevel': 0,
    },
    'miniGamesStats': {
      'puzzleGamesWon': 0,
      'arcadeGamesPlayed': 0,
      'timeAttackBest': 0,
      'enduranceModeTime': 0,
    },
    'sessionStats': {
      'currentSessionTime': 0,
      'lastPlayDate': '',
      'consecutiveDays': 0,
    }
  };

  // New Mini-Games Data
  List<Map<String, dynamic>> _availableGames = [
    {
      'id': 'block_builder',
      'name': 'Block Builder 2D',
      'icon': '🎮',
      'color': Colors.green,
      'description': 'Build and explore in 2D',
      'highScore': 0,
      'playCount': 0,
      'unlocked': true,
    },
    {
      'id': 'puzzle_master',
      'name': 'Puzzle Master',
      'icon': '🧩',
      'color': Colors.purple,
      'description': 'Solve challenging puzzles',
      'highScore': 0,
      'playCount': 0,
      'unlocked': true,
    },
    {
      'id': 'space_shooter',
      'name': 'Space Shooter',
      'icon': '🚀',
      'color': Colors.blue,
      'description': 'Defend Earth from aliens',
      'highScore': 0,
      'playCount': 0,
      'unlocked': true,
    },
    {
      'id': 'racing_fever',
      'name': 'Racing Fever',
      'icon': '🏎️',
      'color': Colors.red,
      'description': 'High-speed racing action',
      'highScore': 0,
      'playCount': 0,
      'unlocked': false,
      'unlockRequirement': 'Complete 10 games',
    },
    {
      'id': 'word_crush',
      'name': 'Word Crush',
      'icon': '📝',
      'color': Colors.orange,
      'description': 'Word puzzle challenge',
      'highScore': 0,
      'playCount': 0,
      'unlocked': true,
    },
    {
      'id': 'memory_cards',
      'name': 'Memory Cards',
      'icon': '🃏',
      'color': Colors.cyan,
      'description': 'Test your memory',
      'highScore': 0,
      'playCount': 0,
      'unlocked': true,
    },
  ];

  Pet? get pet => _pet;
  bool get soundEnabled => _soundEnabled;
  bool get darkModeEnabled => _darkModeEnabled;
  bool get liteModeEnabled => _liteModeEnabled;
  bool get hasPet => _pet != null;
  Map<String, dynamic> get globalStats => _globalStats;
  List<Map<String, dynamic>> get availableGames => _availableGames;

  Future<void> loadGame() async {
    final prefs = await SharedPreferences.getInstance();

    // Load sound setting
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
    _soundService.setSoundEnabled(_soundEnabled);
    _darkModeEnabled = prefs.getBool('darkModeEnabled') ?? false;
    _liteModeEnabled = prefs.getBool('liteModeEnabled') ?? false;

    // Load comprehensive stats
    final statsJson = prefs.getString('globalStats');
    if (statsJson != null) {
      try {
        _globalStats = Map<String, dynamic>.from(jsonDecode(statsJson));
      } catch (_) {
        await prefs.remove('globalStats');
      }
    }

    // Load games data
    final gamesJson = prefs.getString('availableGames');
    if (gamesJson != null) {
      try {
        _mergeSavedGames(jsonDecode(gamesJson));
      } catch (_) {
        await prefs.remove('availableGames');
      }
    }

    // Check if this is a new version for returning users
    final lastVersion = prefs.getString('lastVersion');
    final bool shouldShowWhatsNew =
        lastVersion != null && lastVersion != _currentVersion;

    // Save current version
    await prefs.setString('lastVersion', _currentVersion);

    // Load pet
    final petJson = prefs.getString('pet');
    if (petJson != null) {
      _pet = Pet.fromJson(jsonDecode(petJson));
      _startGameLoop();
    }

    // Start session tracking
    _startSessionTracking();

    notifyListeners();

    // Return version info for UI to handle
    if (shouldShowWhatsNew) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showWhatsNewDialog();
      });
    }
  }

  void _startSessionTracking() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _globalStats['totalPlayTime'] =
          (_globalStats['totalPlayTime'] as int) + 1;
      _globalStats['sessionStats']['currentSessionTime'] =
          (_globalStats['sessionStats']['currentSessionTime'] as int) + 1;
      _saveStats();
    });
  }

  Future<void> _saveStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('globalStats', jsonEncode(_globalStats));
      await prefs.setString('availableGames', jsonEncode(_gamesForStorage()));
    } catch (_) {
      // Stats are nice-to-have; gameplay should never red-screen over a save.
    }
  }

  List<Map<String, dynamic>> _gamesForStorage() {
    return _availableGames.map((game) {
      final stored = Map<String, dynamic>.from(game);
      stored.removeWhere((_, value) => value is Color);
      return stored;
    }).toList();
  }

  void _mergeSavedGames(dynamic savedGames) {
    if (savedGames is! List) return;

    final savedById = <String, Map<String, dynamic>>{};
    for (final savedGame in savedGames) {
      if (savedGame is! Map) continue;
      final game = Map<String, dynamic>.from(savedGame);
      final id = game['id']?.toString();
      if (id == null || id.isEmpty) continue;
      savedById[id] = game;
    }

    _availableGames = _availableGames.map((defaultGame) {
      final id = defaultGame['id']?.toString();
      final savedGame = id == null ? null : savedById[id];
      if (savedGame == null) return defaultGame;

      final mergedGame = <String, dynamic>{
        ...defaultGame,
        ...savedGame,
      };
      mergedGame['color'] = defaultGame['color'];
      return mergedGame;
    }).toList();
  }

  void updateGameStats(String gameId, int score, bool won) {
    final game = _availableGames.firstWhere((g) => g['id'] == gameId);

    // Update game-specific stats
    game['playCount'] = (game['playCount'] as int) + 1;
    if (score > (game['highScore'] as int)) {
      game['highScore'] = score;
    }

    // Update global stats
    _globalStats['totalScore'] = (_globalStats['totalScore'] as int) + score;
    _globalStats['gamesPlayed'] = (_globalStats['gamesPlayed'] as int) + 1;

    // Update mini-games stats
    if (gameId == 'puzzle_master' && won) {
      _globalStats['miniGamesStats']['puzzleGamesWon'] =
          (_globalStats['miniGamesStats']['puzzleGamesWon'] as int) + 1;
    }
    if (gameId == 'space_shooter') {
      _globalStats['miniGamesStats']['arcadeGamesPlayed'] =
          (_globalStats['miniGamesStats']['arcadeGamesPlayed'] as int) + 1;
    }

    // Check for unlocks
    _checkGameUnlocks();

    _saveStats();
    notifyListeners();
  }

  void updateBlockBuilderStats(Map<String, dynamic> stats) {
    final blockBuilderStats =
        _globalStats['blockBuilderStats'] as Map<String, dynamic>;

    if (stats['blocksPlaced'] != null) {
      blockBuilderStats['blocksPlaced'] =
          (blockBuilderStats['blocksPlaced'] as int) +
              (stats['blocksPlaced'] as int);
    }
    if (stats['blocksBroken'] != null) {
      blockBuilderStats['blocksBroken'] =
          (blockBuilderStats['blocksBroken'] as int) +
              (stats['blocksBroken'] as int);
    }
    if (stats['score'] != null &&
        (stats['score'] as int) > (blockBuilderStats['highestScore'] as int)) {
      blockBuilderStats['highestScore'] = stats['score'];
    }
    if (stats['achievements'] != null) {
      _globalStats['achievementsUnlocked'] =
          (_globalStats['achievementsUnlocked'] as int) +
              (stats['achievements'] as int);
    }

    _saveStats();
    notifyListeners();
  }

  void updatePetStats(String action) {
    final petStats = _globalStats['petStats'] as Map<String, dynamic>;

    switch (action) {
      case 'fed':
        petStats['totalFed'] = (petStats['totalFed'] as int) + 1;
        break;
      case 'played':
        petStats['totalPlayed'] = (petStats['totalPlayed'] as int) + 1;
        break;
      case 'evolved':
        petStats['petsEvolved'] = (petStats['petsEvolved'] as int) + 1;
        break;
      case 'new_pet':
        petStats['petsOwned'] = (petStats['petsOwned'] as int) + 1;
        break;
    }

    _saveStats();
    notifyListeners();
  }

  void _checkGameUnlocks() {
    // Unlock Racing Fever after 10 games
    if (_globalStats['gamesPlayed'] >= 10) {
      final racingGame =
          _availableGames.firstWhere((g) => g['id'] == 'racing_fever');
      if (!racingGame['unlocked']) {
        racingGame['unlocked'] = true;
        _notifyGameUnlocked('Racing Fever');
      }
    }
  }

  void _notifyGameUnlocked(String gameName) {
    // This would show a notification that a new game is unlocked.
  }

  Map<String, dynamic> getGameStats(String gameId) {
    final game = _availableGames.firstWhere((g) => g['id'] == gameId);
    return {
      'highScore': game['highScore'],
      'playCount': game['playCount'],
      'unlocked': game['unlocked'],
    };
  }

  Future<void> saveGame() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('soundEnabled', _soundEnabled);
    await prefs.setBool('darkModeEnabled', _darkModeEnabled);
    await prefs.setBool('liteModeEnabled', _liteModeEnabled);

    if (_pet != null) {
      await prefs.setString('pet', jsonEncode(_pet!.toJson()));
    } else {
      await prefs.remove('pet');
    }
  }

  void _startGameLoop() {
    _gameTimer?.cancel();
    _petPlayTimeTimer?.cancel();

    // Stats decay every 30 seconds
    _gameTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _pet?.decayStats();
      saveGame();
      notifyListeners();
    });

    // Play time tracking every minute
    _petPlayTimeTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _pet?.playTimeMinutes++;
      saveGame();
      notifyListeners();
    });
  }

  void createPet(String name, PetType type) {
    _pet = Pet(name: name, type: type);
    _startGameLoop();
    saveGame();
    notifyListeners();
  }

  void setPet(Pet pet) {
    _pet = pet;
    _startGameLoop();
    saveGame();
    notifyListeners();
  }

  void renamePet(String newName) {
    if (_pet != null) {
      _pet!.name = newName;
      saveGame();
      notifyListeners();
    }
  }

  void feed() {
    if (_pet == null) return;
    _soundService.playSound('feed');
    int oldLevel = _pet!.level;
    _pet!.hunger = (_pet!.hunger - 25).clamp(0, 100); // Better hunger reduction
    _pet!.happiness = (_pet!.happiness + 10).clamp(0, 100); // Pets love food!
    _pet!.addXp(5);

    // Check if level up occurred and save immediately
    if (_pet!.level > oldLevel) {
      _soundService.playSound('level_up');
      saveGame(); // Save immediately after level up
    }

    saveGame(); // Always save after action
    notifyListeners();
  }

  void play() {
    if (_pet == null) return;
    _soundService.playSound('play');
    int oldLevel = _pet!.level;
    _pet!.happiness =
        (_pet!.happiness + 25).clamp(0, 100); // More happiness from play
    _pet!.energy = (_pet!.energy - 8).clamp(0, 100); // Less energy cost
    _pet!.social =
        (_pet!.social + 3).clamp(0, 100); // Play increases social skills
    _pet!.hunger = (_pet!.hunger + 3).clamp(0, 100); // Less hunger increase
    _pet!.addXp(12); // Good XP for playing

    // Check if level up occurred and save immediately
    if (_pet!.level > oldLevel) {
      _soundService.playSound('level_up');
      saveGame(); // Save immediately after level up
    }

    saveGame(); // Always save after action
    notifyListeners();
  }

  void clean() {
    if (_pet == null) return;
    _soundService.playSound('clean');
    int oldLevel = _pet!.level;
    _pet!.cleanliness = (_pet!.cleanliness + 30).clamp(0, 100);
    _pet!.happiness =
        (_pet!.happiness + 15).clamp(0, 100); // Shower makes pets happy!
    _pet!.addXp(5);

    // Check if level up occurred and save immediately
    if (_pet!.level > oldLevel) {
      _soundService.playSound('level_up');
      saveGame(); // Save immediately after level up
    }

    saveGame(); // Always save after action
    notifyListeners();
  }

  void sleep() {
    if (_pet == null) return;
    _soundService.playSound('sleep');
    int oldLevel = _pet!.level;
    _pet!.energy =
        (_pet!.energy + 50).clamp(0, 100); // Much better energy restoration
    _pet!.health = (_pet!.health + 15).clamp(0, 100); // Sleep improves health
    _pet!.hunger = (_pet!.hunger + 5).clamp(0, 100); // Less hunger increase
    _pet!.addXp(5);

    // Check if level up occurred and save immediately
    if (_pet!.level > oldLevel) {
      _soundService.playSound('level_up');
      saveGame(); // Save immediately after level up
    }

    saveGame(); // Always save after action
    notifyListeners();
  }

  void train() {
    if (_pet == null) return;
    _soundService.playSound('train');
    int oldLevel = _pet!.level;
    _pet!.energy = (_pet!.energy - 15).clamp(0, 100); // Less energy cost
    _pet!.happiness =
        (_pet!.happiness + 8).clamp(0, 100); // Pets enjoy training
    _pet!.intelligence =
        (_pet!.intelligence + 5).clamp(0, 100); // Training boosts intelligence
    _pet!.hunger = (_pet!.hunger + 10).clamp(0, 100); // Less hunger increase
    _pet!.addXp(15); // Good XP for training

    // Check if level up occurred and save immediately
    if (_pet!.level > oldLevel) {
      _soundService.playSound('level_up');
      saveGame(); // Save immediately after level up
    }

    saveGame(); // Always save after action
    notifyListeners();
  }

  void giveMedicine() {
    if (_pet == null) return;
    _soundService.playSound('medicine');
    int oldLevel = _pet!.level;
    _pet!.health = (_pet!.health + 30).clamp(0, 100);
    _pet!.addXp(5);

    // Check if level up occurred and save immediately
    if (_pet!.level > oldLevel) {
      _soundService.playSound('level_up');
      saveGame(); // Save immediately after level up
    }

    saveGame(); // Always save after action
    notifyListeners();
  }

  // New enhanced features
  void updatePetColor(Color color) {
    if (_pet == null) return;
    _soundService.playSound('click');
    _pet!.updateColor(color);
    saveGame();
    notifyListeners();
  }

  void toggleDarkMode() {
    _darkModeEnabled = !_darkModeEnabled;
    saveGame();
    notifyListeners();
  }

  void toggleLiteMode() {
    _liteModeEnabled = !_liteModeEnabled;
    saveGame();
    notifyListeners();
  }

  void addAccessory(String accessory) {
    if (_pet == null) return;
    _soundService.playSound('level_up');
    _pet!.addAccessory(accessory);
    saveGame();
    notifyListeners();
  }

  void wearAccessory(String accessory) {
    if (_pet == null) return;
    _soundService.playSound('click');
    _pet!.wearAccessory(accessory);
    saveGame();
    notifyListeners();
  }

  void addAchievement(String achievement) {
    if (_pet == null) return;
    _pet!.addAchievement(achievement);
    _soundService.playSound('level_up');
    saveGame();
    notifyListeners();
  }

  void levelUpSkill(String skill) {
    if (_pet == null) return;
    _soundService.playSound('train');
    _pet!.levelUpSkill(skill);
    saveGame();
    notifyListeners();
  }

  void addItem(String item) {
    if (_pet == null) return;
    _pet!.addItem(item);
    saveGame();
    notifyListeners();
  }

  void useItem(String item) {
    if (_pet == null) return;
    _soundService.playSound('feed');
    _pet!.useItem(item);
    saveGame();
    notifyListeners();
  }

  void increaseFriendship() {
    if (_pet == null) return;
    _pet!.increaseFriendship();
    _soundService.playSound('play');
    saveGame();
    notifyListeners();
  }

  void awardGameRewards(int xp, int gems, int coins) {
    if (_pet == null) return;
    int oldLevel = _pet!.level;
    _pet!.addXp(xp);
    _pet!.gems += gems;
    _pet!.coins += coins;

    // Check if level up occurred and save immediately
    if (_pet!.level > oldLevel) {
      _soundService.playSound('level_up');
      saveGame(); // Save immediately after level up
    }

    saveGame(); // Always save after rewards
    notifyListeners();
  }

  void toggleSleep() {
    if (_pet == null) return;
    _pet!.isAsleep = !_pet!.isAsleep;
    _soundService.playSound('sleep');
    saveGame();
    notifyListeners();
  }

  void buyItem(String item, int cost, {bool isGem = false}) {
    if (_pet == null) return;

    if (isGem && _pet!.gems >= cost) {
      _pet!.gems -= cost;
      _pet!.addItem(item);
      _soundService.playSound('level_up');
    } else if (!isGem && _pet!.coins >= cost) {
      _pet!.coins -= cost;
      _pet!.addItem(item);
      _soundService.playSound('level_up');
    }

    saveGame();
    notifyListeners();
  }

  void checkAchievements() {
    if (_pet == null) return;

    // Level achievements
    if (_pet!.level >= 10 && !_pet!.achievements.contains('Level 10')) {
      addAchievement('Level 10');
    }
    if (_pet!.level >= 25 && !_pet!.achievements.contains('Level 25')) {
      addAchievement('Level 25');
    }
    if (_pet!.level >= 50 && !_pet!.achievements.contains('Level 50')) {
      addAchievement('Level 50');
    }

    // Currency achievements
    if (_pet!.coins >= 1000 && !_pet!.achievements.contains('Rich Pet')) {
      addAchievement('Rich Pet');
    }
    if (_pet!.gems >= 50 && !_pet!.achievements.contains('Gem Collector')) {
      addAchievement('Gem Collector');
    }

    // Evolution achievements
    if (_pet!.evolutionStage.index >= 2 &&
        !_pet!.achievements.contains('Teenager')) {
      addAchievement('Teenager');
    }
    if (_pet!.evolutionStage.index >= 3 &&
        !_pet!.achievements.contains('Adult Pet')) {
      addAchievement('Adult Pet');
    }

    // Friendship achievements
    if (_pet!.friendshipLevel >= 50 &&
        !_pet!.achievements.contains('Best Friend')) {
      addAchievement('Best Friend');
    }
    if (_pet!.friendshipLevel >= 100 &&
        !_pet!.achievements.contains('Soulmate')) {
      addAchievement('Soulmate');
    }
  }

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
    _soundService.setSoundEnabled(_soundEnabled);
    _soundService.playSound('click');
    saveGame();
    notifyListeners();
  }

  void playClickSound() {
    _soundService.playSound('click');
  }

  void _showWhatsNewDialog() {
    // This will be called from the UI layer
    // We'll handle the dialog display in the main app
  }

  Future<void> resetGame() async {
    _gameTimer?.cancel();
    _petPlayTimeTimer?.cancel();
    _pet = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('pet');
    await prefs.remove('kittyCatCollection');
    await prefs.remove('selectedKittyCatIndex');

    notifyListeners();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _petPlayTimeTimer?.cancel();
    _sessionTimer?.cancel();
    _soundService.dispose();
    super.dispose();
  }
}
