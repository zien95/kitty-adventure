import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'screens/pet_game_screen.dart';
import 'providers/account_provider.dart' as app_account;
import 'providers/game_provider.dart' as app_game;
import 'services/notification_service.dart' as app_notifications;
import 'widgets/app_wrapper.dart';

// ==================== CONSTANTS ====================

class EvolutionConstants {
  static const int BABY_TO_CHILD = 10;
  static const int CHILD_TO_TEEN = 20;
  static const int TEEN_TO_ADULT = 35;
  static const int ADULT_TO_ELDER = 50;
}

class DecayConstants {
  static const double HUNGER_DECAY = 2.0;
  static const double ENERGY_DECAY = 1.0;
  static const double CLEANLINESS_DECAY = 1.0;
  static const double HAPPINESS_DECAY = 1.0;
  static const double INTELLIGENCE_DECAY = 0.5;
  static const double SOCIAL_DECAY = 1.0;
  static const double LOYALTY_DECAY = 0.3;
}

class ActionConstants {
  static const int FEED_HUNGER_REDUCTION = 25;
  static const int FEED_HAPPINESS_BOOST = 10;
  static const int FEED_XP = 5;

  static const int PLAY_HAPPINESS_BOOST = 25;
  static const int PLAY_ENERGY_COST = 8;
  static const int PLAY_SOCIAL_BOOST = 3;
  static const int PLAY_HUNGER_COST = 3;
  static const int PLAY_XP = 12;

  static const int CLEAN_CLEANLINESS_BOOST = 30;
  static const int CLEAN_HAPPINESS_BOOST = 15;
  static const int CLEAN_XP = 5;

  static const int SLEEP_ENERGY_BOOST = 50;
  static const int SLEEP_HEALTH_BOOST = 15;
  static const int SLEEP_HUNGER_COST = 5;
  static const int SLEEP_XP = 5;

  static const int TRAIN_ENERGY_COST = 15;
  static const int TRAIN_HAPPINESS_BOOST = 8;
  static const int TRAIN_INTELLIGENCE_BOOST = 5;
  static const int TRAIN_HUNGER_COST = 10;
  static const int TRAIN_XP = 15;

  static const int MEDICINE_HEALTH_BOOST = 30;
  static const int MEDICINE_XP = 5;
}

// ==================== MODELS ====================

enum PetType { dog, cat, bunny, bird, dragon, phoenix, griffin, unicorn }

enum PetPersonality { playful, lazy, curious, shy, energetic, calm }

enum PetMood { happy, excited, sleepy, hungry, sad, sick, playful, loving }

enum EvolutionStage { baby, child, teen, adult, elder }

extension PetTypeExtension on PetType {
  String get emoji {
    switch (this) {
      case PetType.dog:
        return '🐶';
      case PetType.cat:
        return '🐱';
      case PetType.bunny:
        return '🐰';
      case PetType.bird:
        return '🐦';
      case PetType.dragon:
        return '🐉';
      case PetType.phoenix:
        return '🔥';
      case PetType.griffin:
        return '🦅';
      case PetType.unicorn:
        return '🦄';
    }
  }

  String get name {
    switch (this) {
      case PetType.dog:
        return 'Dog';
      case PetType.cat:
        return 'Cat';
      case PetType.bunny:
        return 'Bunny';
      case PetType.bird:
        return 'Bird';
      case PetType.dragon:
        return 'Dragon';
      case PetType.phoenix:
        return 'Phoenix';
      case PetType.griffin:
        return 'Griffin';
      case PetType.unicorn:
        return 'Unicorn';
    }
  }

  Color get color {
    switch (this) {
      case PetType.dog:
        return const Color(0xFF8D6E63);
      case PetType.cat:
        return const Color(0xFFFFA726);
      case PetType.bunny:
        return const Color(0xFFFCE4EC);
      case PetType.bird:
        return const Color(0xFF4FC3F7);
      case PetType.dragon:
        return const Color(0xFF66BB6A);
      case PetType.phoenix:
        return const Color(0xFFFF5722);
      case PetType.griffin:
        return const Color(0xFFCDDC39);
      case PetType.unicorn:
        return const Color(0xFFE040FB);
    }
  }

  bool get isPremium => false;
}

class Pet {
  String id;
  String name;
  PetType type;
  PetPersonality personality;
  PetMood currentMood;
  EvolutionStage evolutionStage;
  int level;
  int xp;
  int xpToNextLevel;
  int hunger;
  int energy;
  int cleanliness;
  int happiness;
  int health;
  int intelligence;
  int social;
  int loyalty;
  int coins;
  int gems;
  DateTime createdAt;
  int playTimeMinutes;
  List<String> accessories;
  List<String> achievements;
  Map<String, int> skills;
  List<String> inventory;
  int friendshipLevel;
  DateTime lastFed;
  DateTime lastPlayed;
  bool isAsleep;
  String currentAccessory;
  DateTime lastBackup;

  Pet({
    this.id = '',
    required this.name,
    required this.type,
    this.personality = PetPersonality.playful,
    this.currentMood = PetMood.happy,
    this.evolutionStage = EvolutionStage.baby,
    this.level = 1,
    this.xp = 0,
    this.xpToNextLevel = 100,
    this.hunger = 30,
    this.energy = 80,
    this.cleanliness = 70,
    this.happiness = 80,
    this.health = 100,
    this.intelligence = 10,
    this.social = 10,
    this.loyalty = 10,
    this.coins = 100,
    this.gems = 5,
    DateTime? createdAt,
    this.playTimeMinutes = 0,
    this.accessories = const [],
    this.achievements = const [],
    this.skills = const {},
    this.inventory = const [],
    this.friendshipLevel = 0,
    DateTime? lastFed,
    DateTime? lastPlayed,
    this.isAsleep = false,
    this.currentAccessory = '',
    DateTime? lastBackup,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastFed = lastFed ?? DateTime.now(),
        lastPlayed = lastPlayed ?? DateTime.now(),
        lastBackup = lastBackup ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'personality': personality.index,
      'currentMood': currentMood.index,
      'evolutionStage': evolutionStage.index,
      'level': level,
      'xp': xp,
      'xpToNextLevel': xpToNextLevel,
      'hunger': hunger,
      'energy': energy,
      'cleanliness': cleanliness,
      'happiness': happiness,
      'health': health,
      'intelligence': intelligence,
      'social': social,
      'loyalty': loyalty,
      'coins': coins,
      'gems': gems,
      'createdAt': createdAt.toIso8601String(),
      'playTimeMinutes': playTimeMinutes,
      'accessories': accessories,
      'achievements': achievements,
      'skills': skills,
      'inventory': inventory,
      'friendshipLevel': friendshipLevel,
      'lastFed': lastFed.toIso8601String(),
      'lastPlayed': lastPlayed.toIso8601String(),
      'isAsleep': isAsleep,
      'currentAccessory': currentAccessory,
      'lastBackup': lastBackup.toIso8601String(),
    };
  }

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] ?? 'Unknown Pet',
      type: PetType.values[json['type'] ?? 0],
      personality: PetPersonality.values[json['personality'] ?? 0],
      currentMood: PetMood.values[json['currentMood'] ?? 0],
      evolutionStage: EvolutionStage.values[json['evolutionStage'] ?? 0],
      level: json['level'] ?? 1,
      xp: json['xp'] ?? 0,
      xpToNextLevel: json['xpToNextLevel'] ?? 100,
      hunger: json['hunger'] ?? 30,
      energy: json['energy'] ?? 80,
      cleanliness: json['cleanliness'] ?? 70,
      happiness: json['happiness'] ?? 80,
      health: json['health'] ?? 100,
      intelligence: json['intelligence'] ?? 10,
      social: json['social'] ?? 10,
      loyalty: json['loyalty'] ?? 10,
      coins: json['coins'] ?? 100,
      gems: json['gems'] ?? 5,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      playTimeMinutes: json['playTimeMinutes'] ?? 0,
      accessories: List<String>.from(json['accessories'] ?? []),
      achievements: List<String>.from(json['achievements'] ?? []),
      skills: Map<String, int>.from(json['skills'] ?? {}),
      inventory: List<String>.from(json['inventory'] ?? []),
      friendshipLevel: json['friendshipLevel'] ?? 0,
      lastFed: json['lastFed'] != null
          ? DateTime.parse(json['lastFed'])
          : DateTime.now(),
      lastPlayed: json['lastPlayed'] != null
          ? DateTime.parse(json['lastPlayed'])
          : DateTime.now(),
      isAsleep: json['isAsleep'] ?? false,
      currentAccessory: json['currentAccessory'] ?? '',
      lastBackup: json['lastBackup'] != null
          ? DateTime.parse(json['lastBackup'])
          : DateTime.now(),
    );
  }

  String get status {
    if (health <= 20) return 'Critical';
    if (hunger >= 80) return 'Starving';
    if (energy <= 20) return 'Exhausted';
    if (cleanliness <= 20) return 'Dirty';
    if (happiness <= 20) return 'Sad';
    if (health >= 90 &&
        hunger <= 20 &&
        energy >= 90 &&
        cleanliness >= 90 &&
        happiness >= 90) return 'Perfect';
    if (health >= 80 &&
        hunger <= 30 &&
        energy >= 80 &&
        cleanliness >= 80 &&
        happiness >= 80) return 'Excellent';
    if (health >= 60 &&
        hunger <= 40 &&
        energy >= 60 &&
        cleanliness >= 60 &&
        happiness >= 60) return 'Happy';
    return 'Okay';
  }

  void addXp(int amount) {
    xp += amount;
    while (xp >= xpToNextLevel) {
      xp -= xpToNextLevel;
      level++;
      xpToNextLevel = (xpToNextLevel * 1.5).round();
      _checkEvolution();
    }
  }

  void decayStats() {
    hunger = (hunger + DecayConstants.HUNGER_DECAY).clamp(0, 100).toInt();
    energy = (energy - DecayConstants.ENERGY_DECAY).clamp(0, 100).toInt();
    cleanliness =
        (cleanliness - DecayConstants.CLEANLINESS_DECAY).clamp(0, 100).toInt();
    happiness =
        (happiness - DecayConstants.HAPPINESS_DECAY).clamp(0, 100).toInt();
    intelligence = (intelligence - DecayConstants.INTELLIGENCE_DECAY)
        .clamp(0, 100)
        .toInt();
    social = (social - DecayConstants.SOCIAL_DECAY).clamp(0, 100).toInt();
    loyalty = (loyalty - DecayConstants.LOYALTY_DECAY).clamp(0, 100).toInt();

    if (hunger > 80 || energy < 30 || cleanliness < 30) {
      health = (health - 2).clamp(0, 100);
    } else if (hunger < 30 &&
        energy > 70 &&
        cleanliness > 70 &&
        happiness > 70) {
      health = (health + 1).clamp(0, 100);
    }

    _updateMood();
    _checkEvolution();
  }

  void _updateMood() {
    if (health <= 20) {
      currentMood = PetMood.sick;
    } else if (hunger >= 80) {
      currentMood = PetMood.hungry;
    } else if (energy <= 20) {
      currentMood = PetMood.sleepy;
    } else if (happiness <= 20) {
      currentMood = PetMood.sad;
    } else if (happiness >= 90 && energy >= 80) {
      currentMood = PetMood.excited;
    } else if (friendshipLevel >= 50) {
      currentMood = PetMood.loving;
    } else {
      currentMood = PetMood.happy;
    }
  }

  void _checkEvolution() {
    EvolutionStage newStage = evolutionStage;

    if (level >= EvolutionConstants.BABY_TO_CHILD &&
        evolutionStage == EvolutionStage.baby) {
      newStage = EvolutionStage.child;
    } else if (level >= EvolutionConstants.CHILD_TO_TEEN &&
        evolutionStage == EvolutionStage.child) {
      newStage = EvolutionStage.teen;
    } else if (level >= EvolutionConstants.TEEN_TO_ADULT &&
        evolutionStage == EvolutionStage.teen) {
      newStage = EvolutionStage.adult;
    } else if (level >= EvolutionConstants.ADULT_TO_ELDER &&
        evolutionStage == EvolutionStage.adult) {
      newStage = EvolutionStage.elder;
    }

    if (newStage != evolutionStage) {
      evolutionStage = newStage;
      health = (health + 20).clamp(0, 100);
      intelligence = (intelligence + 10).clamp(0, 100);
    }
  }

  String get evolutionEmoji {
    switch (evolutionStage) {
      case EvolutionStage.baby:
        return '👶';
      case EvolutionStage.child:
        return '🧒';
      case EvolutionStage.teen:
        return '🧑';
      case EvolutionStage.adult:
        return '👨';
      case EvolutionStage.elder:
        return '👴';
    }
  }

  String get moodEmoji {
    switch (currentMood) {
      case PetMood.happy:
        return '😊';
      case PetMood.excited:
        return '🤗';
      case PetMood.sleepy:
        return '😴';
      case PetMood.hungry:
        return '🍽️';
      case PetMood.sad:
        return '😢';
      case PetMood.sick:
        return '🤒';
      case PetMood.playful:
        return '🎮';
      case PetMood.loving:
        return '❤️';
    }
  }
}

class Account {
  final String id;
  final String username;
  final String email;
  final DateTime createdAt;
  int totalPlayTime;
  int achievementsUnlocked;
  int petsOwned;
  int coins;
  int gems;
  bool isPremium;
  final List<String> unlockedFeatures;
  final Map<String, dynamic> preferences;
  DateTime lastPremiumCheck;

  Account({
    required this.id,
    required this.username,
    required this.email,
    required this.createdAt,
    this.totalPlayTime = 0,
    this.achievementsUnlocked = 0,
    this.petsOwned = 1,
    this.coins = 100,
    this.gems = 50,
    this.isPremium = true,
    this.unlockedFeatures = const [],
    this.preferences = const {},
    DateTime? lastPremiumCheck,
  }) : lastPremiumCheck = lastPremiumCheck ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'totalPlayTime': totalPlayTime,
      'achievementsUnlocked': achievementsUnlocked,
      'petsOwned': petsOwned,
      'coins': coins,
      'gems': gems,
      'isPremium': isPremium,
      'unlockedFeatures': unlockedFeatures,
      'preferences': preferences,
      'lastPremiumCheck': lastPremiumCheck.toIso8601String(),
    };
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      totalPlayTime: json['totalPlayTime'] ?? 0,
      achievementsUnlocked: json['achievementsUnlocked'] ?? 0,
      petsOwned: json['petsOwned'] ?? 1,
      coins: json['coins'] ?? 100,
      gems: json['gems'] ?? 50,
      isPremium: json['isPremium'] ?? true,
      unlockedFeatures: List<String>.from(json['unlockedFeatures'] ?? []),
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      lastPremiumCheck: json['lastPremiumCheck'] != null
          ? DateTime.parse(json['lastPremiumCheck'])
          : DateTime.now(),
    );
  }
}

// ==================== SERVICES ====================

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool _soundEnabled = true;

  bool get soundEnabled => _soundEnabled;

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  Future<void> playSound(String soundName) async {
    if (!_soundEnabled) return;

    try {
      await SystemSound.play(SystemSoundType.click);
      await _triggerHapticFeedback(soundName);
    } catch (e) {
      try {
        await _triggerHapticFeedback(soundName);
      } catch (e2) {
        // Silent fallback
      }
    }
  }

  Future<void> _triggerHapticFeedback(String soundName) async {
    try {
      bool? hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        switch (soundName) {
          case 'feed':
          case 'play':
          case 'clean':
          case 'sleep':
          case 'train':
          case 'medicine':
            await Vibration.vibrate(duration: 50, amplitude: 100);
            break;
          case 'level_up':
            await Vibration.vibrate(pattern: [0, 100, 50, 100]);
            break;
          case 'notification':
            await Vibration.vibrate(duration: 200, amplitude: 150);
            break;
          case 'click':
          default:
            await Vibration.vibrate(duration: 25);
            break;
        }
      }
    } catch (e) {
      // Silently handle vibration errors
    }
  }

  void dispose() {
    // Nothing to dispose
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<GameNotification> _notifications = [];
  final StreamController<GameNotification> _notificationController =
      StreamController<GameNotification>.broadcast();

  Stream<GameNotification> get notificationStream =>
      _notificationController.stream;
  List<GameNotification> get notifications => List.unmodifiable(_notifications);

  void addNotification(GameNotification notification) {
    _notifications.insert(0, notification);
    _notificationController.add(notification);

    if (_notifications.length > 50) {
      _notifications.removeRange(50, _notifications.length);
    }
  }

  void showDailyRewardNotification() {
    addNotification(
      GameNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Daily Reward Available!',
        message: 'Claim your daily reward now!',
        type: NotificationType.reward,
        icon: Icons.card_giftcard,
        color: Colors.amber,
      ),
    );
  }

  void showSystemNotification(String title, String message) {
    addNotification(
      GameNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        type: NotificationType.system,
        icon: Icons.info,
        color: Colors.grey,
      ),
    );
  }
}

class GameNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final IconData icon;
  final Color color;
  bool isRead;

  GameNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.icon,
    required this.color,
    this.isRead = false,
  }) : timestamp = DateTime.now();
}

enum NotificationType {
  system,
  reward,
  achievement,
  petCare,
  levelUp,
  challenge,
  social,
  update,
}

// ==================== BACKUP SERVICE ====================

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  Future<File?> backupPet(Pet pet) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final fileName =
          'pet_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${backupDir.path}/$fileName');

      await file.writeAsString(jsonEncode(pet.toJson()));
      return file;
    } catch (e) {
      return null;
    }
  }

  Future<Pet?> restorePetFromFile(File file) async {
    try {
      final content = await file.readAsString();
      final json = jsonDecode(content);
      return Pet.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  Future<List<File>> listBackups() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/backups');
      if (!await backupDir.exists()) {
        return [];
      }
      return backupDir.listSync().whereType<File>().toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> exportToUSB() async {
    try {
      PermissionStatus status = await Permission.storage.request();
      if (status.isGranted) {
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          final prefs = await SharedPreferences.getInstance();
          final petJson = prefs.getString('pet');
          final accountJson = prefs.getString('user_account');

          if (petJson != null && accountJson != null) {
            final exportFile = File(
              '${directory.path}/pup_export_${DateTime.now().millisecondsSinceEpoch}.json',
            );
            final exportData = {
              'pet': jsonDecode(petJson),
              'account': jsonDecode(accountJson),
              'exportDate': DateTime.now().toIso8601String(),
              'version': '26.8.6',
            };
            await exportFile.writeAsString(jsonEncode(exportData));
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> importFromUSB() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final data = jsonDecode(content);

        if (data['pet'] != null && data['account'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('pet', jsonEncode(data['pet']));
          await prefs.setString('user_account', jsonEncode(data['account']));
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> shareBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final petJson = prefs.getString('pet');
      if (petJson != null) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/pup_share.json');
        await tempFile.writeAsString(petJson);
        await Share.shareXFiles([
          XFile(tempFile.path),
        ], text: 'My Pup Pet Backup');
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

// ==================== PATREON SERVICE ====================

class SupportUnlockService {
  static final SupportUnlockService _instance =
      SupportUnlockService._internal();
  factory SupportUnlockService() => _instance;
  SupportUnlockService._internal();

  // support campaign and tier information
  static const String supportUrl = 'https://www.support.com/join/yourcampaign';
  static const String creatorUrl = 'https://www.support.com/yourcreator';

  // Premium tiers
  static const Map<String, Map<String, dynamic>> premiumTiers = {
    'bronze': {
      'name': 'Bronze Supporter',
      'price': '\$3/month',
      'benefits': [
        'Unlock Phoenix pet',
        'Ad-free experience',
        'Bonus daily rewards',
      ],
      'color': Colors.brown,
    },
    'silver': {
      'name': 'Silver Supporter',
      'price': '\$5/month',
      'benefits': [
        'Unlock Phoenix & Griffin',
        'All Bronze benefits',
        'Exclusive accessories',
        '2x XP boost',
      ],
      'color': Colors.grey,
    },
    'gold': {
      'name': 'Gold Supporter',
      'price': '\$10/month',
      'benefits': [
        'Unlock all premium pets',
        'All Silver benefits',
        'Golden accessories',
        '3x XP boost',
        'Priority support',
      ],
      'color': Colors.amber,
    },
  };

  Future<bool> launchsupportPage() async => true;

  Future<bool> launchCreatorPage() async => true;

  Future<bool> validatesupportSupporter(String email) async {
    return _updatePremiumStatus('free');
  }

  Future<bool> _updatePremiumStatus(String tier) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('support_tier', tier);
      await prefs.setBool('is_premium', true);
      await prefs.setString(
        'premium_expires',
        DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getCurrentTier() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('support_tier') ?? 'free';
    } catch (e) {
      return null;
    }
  }

  Future<bool> isPremiumActive() async {
    try {
      await _updatePremiumStatus('free');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<DateTime?> getPremiumExpiry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiresString = prefs.getString('premium_expires');
      return expiresString != null ? DateTime.parse(expiresString) : null;
    } catch (e) {
      return null;
    }
  }

  Future<void> clearPremiumStatus() async {
    try {
      await _updatePremiumStatus('free');
    } catch (e) {
      // Handle error silently
    }
  }
}

// ==================== PROVIDERS ====================

class GameProvider extends ChangeNotifier {
  Pet? _pet;
  bool _soundEnabled = true;
  Timer? _gameTimer;
  Timer? _playTimeTimer;
  Timer? _autoBackupTimer;
  final SoundService _soundService = SoundService();
  final BackupService _backupService = BackupService();

  Map<String, dynamic> _globalStats = {
    'totalPlayTime': 0,
    'totalScore': 0,
    'gamesPlayed': 0,
    'achievementsUnlocked': 0,
  };

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
      'id': 'memory_match',
      'name': 'Memory Match',
      'icon': '🧠',
      'color': Colors.blue,
      'description': 'Test your memory',
      'highScore': 0,
      'playCount': 0,
      'unlocked': true,
    },
  ];

  Pet? get pet => _pet;
  bool get soundEnabled => _soundEnabled;
  bool get hasPet => _pet != null;
  Map<String, dynamic> get globalStats => _globalStats;
  List<Map<String, dynamic>> get availableGames => _availableGames;

  Future<void> loadGame() async {
    final prefs = await SharedPreferences.getInstance();
    _soundEnabled = prefs.getBool('soundEnabled') ?? true;
    _soundService.setSoundEnabled(_soundEnabled);

    final statsJson = prefs.getString('globalStats');
    if (statsJson != null) {
      _globalStats = Map<String, dynamic>.from(jsonDecode(statsJson));
    }

    final petJson = prefs.getString('pet');
    if (petJson != null) {
      _pet = Pet.fromJson(jsonDecode(petJson));
      _startGameLoop();
    }

    _startAutoBackup();
    notifyListeners();
  }

  void _startAutoBackup() {
    _autoBackupTimer?.cancel();
    _autoBackupTimer = Timer.periodic(const Duration(hours: 24), (_) async {
      if (_pet != null) {
        await _backupService.backupPet(_pet!);
        _globalStats['lastBackup'] = DateTime.now().toIso8601String();
        await _saveStats();
      }
    });
  }

  Future<void> _saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('globalStats', jsonEncode(_globalStats));
  }

  Future<void> saveGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', _soundEnabled);

    if (_pet != null) {
      await prefs.setString('pet', jsonEncode(_pet!.toJson()));
    } else {
      await prefs.remove('pet');
    }
  }

  void _startGameLoop() {
    _gameTimer?.cancel();
    _playTimeTimer?.cancel();

    _gameTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _pet?.decayStats();
      saveGame();
      notifyListeners();
    });

    _playTimeTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_pet != null) {
        _pet!.playTimeMinutes++;
        _globalStats['totalPlayTime'] =
            (_globalStats['totalPlayTime'] as int) + 1;
        saveGame();
        _saveStats();
        notifyListeners();
      }
    });
  }

  void createPet(String name, PetType type) {
    _pet = Pet(name: name, type: type);
    _startGameLoop();
    saveGame();
    notifyListeners();
  }

  void feed() {
    if (_pet == null) return;
    _soundService.playSound('feed');
    int oldLevel = _pet!.level;
    _pet!.hunger = (_pet!.hunger - ActionConstants.FEED_HUNGER_REDUCTION).clamp(
      0,
      100,
    );
    _pet!.happiness =
        (_pet!.happiness + ActionConstants.FEED_HAPPINESS_BOOST).clamp(0, 100);
    _pet!.addXp(ActionConstants.FEED_XP);

    if (_pet!.level > oldLevel) {
      _soundService.playSound('level_up');
      saveGame();
    }

    saveGame();
    notifyListeners();
  }

  void play() {
    if (_pet == null) return;
    _soundService.playSound('play');
    int oldLevel = _pet!.level;
    _pet!.happiness =
        (_pet!.happiness + ActionConstants.PLAY_HAPPINESS_BOOST).clamp(0, 100);
    _pet!.energy = (_pet!.energy - ActionConstants.PLAY_ENERGY_COST).clamp(
      0,
      100,
    );
    _pet!.social = (_pet!.social + ActionConstants.PLAY_SOCIAL_BOOST).clamp(
      0,
      100,
    );
    _pet!.hunger = (_pet!.hunger + ActionConstants.PLAY_HUNGER_COST).clamp(
      0,
      100,
    );
    _pet!.addXp(ActionConstants.PLAY_XP);

    if (_pet!.level > oldLevel) {
      _soundService.playSound('level_up');
      saveGame();
    }

    saveGame();
    notifyListeners();
  }

  void clean() {
    if (_pet == null) return;
    _soundService.playSound('clean');
    int oldLevel = _pet!.level;
    _pet!.cleanliness =
        (_pet!.cleanliness + ActionConstants.CLEAN_CLEANLINESS_BOOST).clamp(
      0,
      100,
    );
    _pet!.happiness =
        (_pet!.happiness + ActionConstants.CLEAN_HAPPINESS_BOOST).clamp(0, 100);
    _pet!.addXp(ActionConstants.CLEAN_XP);

    if (_pet!.level > oldLevel) {
      _soundService.playSound('level_up');
      saveGame();
    }

    saveGame();
    notifyListeners();
  }

  void sleep() {
    if (_pet == null) return;
    _soundService.playSound('sleep');
    int oldLevel = _pet!.level;
    _pet!.energy = (_pet!.energy + ActionConstants.SLEEP_ENERGY_BOOST).clamp(
      0,
      100,
    );
    _pet!.health = (_pet!.health + ActionConstants.SLEEP_HEALTH_BOOST).clamp(
      0,
      100,
    );
    _pet!.hunger = (_pet!.hunger + ActionConstants.SLEEP_HUNGER_COST).clamp(
      0,
      100,
    );
    _pet!.addXp(ActionConstants.SLEEP_XP);

    if (_pet!.level > oldLevel) {
      _soundService.playSound('level_up');
      saveGame();
    }

    saveGame();
    notifyListeners();
  }

  void train() {
    if (_pet == null) return;
    _soundService.playSound('train');
    int oldLevel = _pet!.level;
    _pet!.energy = (_pet!.energy - ActionConstants.TRAIN_ENERGY_COST).clamp(
      0,
      100,
    );
    _pet!.happiness =
        (_pet!.happiness + ActionConstants.TRAIN_HAPPINESS_BOOST).clamp(0, 100);
    _pet!.intelligence =
        (_pet!.intelligence + ActionConstants.TRAIN_INTELLIGENCE_BOOST).clamp(
      0,
      100,
    );
    _pet!.hunger = (_pet!.hunger + ActionConstants.TRAIN_HUNGER_COST).clamp(
      0,
      100,
    );
    _pet!.addXp(ActionConstants.TRAIN_XP);

    if (_pet!.level > oldLevel) {
      _soundService.playSound('level_up');
      saveGame();
    }

    saveGame();
    notifyListeners();
  }

  void giveMedicine() {
    if (_pet == null) return;
    _soundService.playSound('medicine');
    int oldLevel = _pet!.level;
    _pet!.health = (_pet!.health + ActionConstants.MEDICINE_HEALTH_BOOST).clamp(
      0,
      100,
    );
    _pet!.addXp(ActionConstants.MEDICINE_XP);

    if (_pet!.level > oldLevel) {
      _soundService.playSound('level_up');
      saveGame();
    }

    saveGame();
    notifyListeners();
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

  Future<bool> backupPet() async {
    if (_pet == null) return false;
    final file = await _backupService.backupPet(_pet!);
    return file != null;
  }

  Future<bool> restoreFromBackup(File file) async {
    final restoredPet = await _backupService.restorePetFromFile(file);
    if (restoredPet != null) {
      _pet = restoredPet;
      saveGame();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<List<File>> listBackups() async {
    return await _backupService.listBackups();
  }

  Future<bool> exportToUSB() async {
    return await _backupService.exportToUSB();
  }

  Future<bool> importFromUSB() async {
    final success = await _backupService.importFromUSB();
    if (success) {
      await loadGame();
      notifyListeners();
    }
    return success;
  }

  Future<bool> shareBackup() async {
    return await _backupService.shareBackup();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _playTimeTimer?.cancel();
    _autoBackupTimer?.cancel();
    _soundService.dispose();
    super.dispose();
  }
}

class AccountProvider extends ChangeNotifier {
  Account? _account;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  final SupportUnlockService _supportService = SupportUnlockService();

  Account? get account {
    if (_account != null && !_account!.isPremium) {
      _account!.isPremium = true;
    }
    return _account;
  }

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  bool get isPremium => true;

  AccountProvider() {
    _loadAccount();
    _checksupportStatus();
  }

  Future<void> _loadAccount() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final accountJson = prefs.getString('user_account');

    if (accountJson != null) {
      _account = Account.fromJson(json.decode(accountJson));
      _account!.isPremium = true;
      _isLoggedIn = true;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String username, String email) async {
    _isLoading = true;
    notifyListeners();

    final newAccount = Account(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: username,
      email: email,
      createdAt: DateTime.now(),
      isPremium: true,
    );

    _account = newAccount;
    _isLoggedIn = true;

    await _saveAccount();

    await _supportService.validatesupportSupporter(email);
    await _checksupportStatus();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveAccount() async {
    if (_account == null) return;

    _account!.isPremium = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_account', json.encode(_account!.toJson()));
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_account');

    _account = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<void> _checksupportStatus() async {
    final isPremiumActive = await _supportService.isPremiumActive();
    final currentTier = await _supportService.getCurrentTier();
    final premiumExpiry = await _supportService.getPremiumExpiry();

    if (isPremiumActive && _account != null) {
      updatePremium(true);

      _account = Account(
        id: _account!.id,
        username: _account!.username,
        email: _account!.email,
        createdAt: _account!.createdAt,
        totalPlayTime: _account!.totalPlayTime,
        achievementsUnlocked: _account!.achievementsUnlocked,
        petsOwned: _account!.petsOwned,
        coins: _account!.coins,
        gems: _account!.gems,
        isPremium: true,
        unlockedFeatures: [
          ..._account!.unlockedFeatures,
          'free_${currentTier}',
        ],
        preferences: {
          ..._account!.preferences,
          'support_tier': currentTier,
          'premium_expires': premiumExpiry?.toIso8601String(),
        },
        lastPremiumCheck: DateTime.now(),
      );
      _saveAccount();
      notifyListeners();
    }
  }

  void updatePremium(bool isPremium) {
    if (_account != null) {
      _account = Account(
        id: _account!.id,
        username: _account!.username,
        email: _account!.email,
        createdAt: _account!.createdAt,
        totalPlayTime: _account!.totalPlayTime,
        achievementsUnlocked: _account!.achievementsUnlocked,
        petsOwned: _account!.petsOwned,
        coins: _account!.coins,
        gems: _account!.gems,
        isPremium: true,
        unlockedFeatures: _account!.unlockedFeatures,
        preferences: _account!.preferences,
        lastPremiumCheck: DateTime.now(),
      );
      _saveAccount();
      notifyListeners();
    }
  }

  Future<bool> connectsupport(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supportService.validatesupportSupporter(email);
      await _checksupportStatus();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> launchsupportPage() async {
    await _supportService.launchsupportPage();
  }

  Future<String?> getsupportTier() async {
    return await _supportService.getCurrentTier();
  }

  Future<DateTime?> getsupportExpiry() async {
    return await _supportService.getPremiumExpiry();
  }
}

// ==================== WIDGETS ====================

class StatBar extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const StatBar({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(value),
              ),
              minHeight: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 36,
          child: Text(
            '$value%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(int value) {
    if (value <= 20) return Colors.red;
    if (value <= 40) return Colors.orange;
    if (value <= 60) return Colors.yellow;
    return color;
  }
}

// ==================== SCREENS ====================

class PetSelectionScreen extends StatelessWidget {
  const PetSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isPremium = context.mounted;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7B1FA2), Color(0xFFE91E63)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Pick Your Pet',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.pets,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 32,
                  ),
                ],
              ),
              if (!isPremium)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '⭐ Premium pets: Phoenix, Griffin, Unicorn ⭐',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              const SizedBox(height: 40),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: PetType.values.map((type) {
                    final isPremiumPet = type.isPremium;
                    return _PetOption(
                      type: type,
                      isLocked: isPremiumPet && !isPremium,
                      onTap: () =>
                          _selectPet(context, type, isPremiumPet && !isPremium),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectPet(BuildContext context, PetType type, bool isLocked) {
    if (isLocked) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('All pets are free now!')));
      return;
    }
    context.read<GameProvider>().playClickSound();
    showDialog(
      context: context,
      builder: (context) => _NamePetDialog(type: type),
    );
  }
}

class _PetOption extends StatelessWidget {
  final PetType type;
  final VoidCallback onTap;
  final bool isLocked;

  const _PetOption({
    required this.type,
    required this.onTap,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isLocked ? Colors.grey.withValues(alpha: 0.5) : Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(type.emoji, style: const TextStyle(fontSize: 50)),
            const SizedBox(height: 8),
            Text(
              type.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isLocked ? Colors.grey : const Color(0xFF7B1FA2),
              ),
            ),
            if (isLocked) const Icon(Icons.lock, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

class _NamePetDialog extends StatefulWidget {
  final PetType type;

  const _NamePetDialog({required this.type});

  @override
  State<_NamePetDialog> createState() => _NamePetDialogState();
}

class _NamePetDialogState extends State<_NamePetDialog> {
  final _controller = TextEditingController(text: 'Buddy');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2D2D3A),
      title: const Text(
        'Name Your Pet',
        style: TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
      content: TextField(
        controller: _controller,
        style: const TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFF1E1E2C),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintText: 'Enter pet name',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
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
            final name = _controller.text.trim();
            if (name.isNotEmpty) {
              context.read<GameProvider>().createPet(name, widget.type);
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
    );
  }
}

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
                }
              }
              return KeyEventResult.ignored;
            },
            child: SafeArea(
              child: Column(
                children: [
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
                              onPressed: () => _showBackupDialog(context),
                              icon: const Icon(
                                Icons.backup,
                                color: Colors.white,
                              ),
                            ),
                            IconButton(
                              onPressed: () => _showSettingsDialog(context),
                              icon: const Icon(
                                Icons.settings,
                                color: Colors.white,
                              ),
                            ),
                            IconButton(
                              onPressed: () => _showHelpDialog(context),
                              icon: const Icon(Icons.help, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: pet.type.color.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: pet.type.color,
                                    width: 3,
                                  ),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Text(
                                      pet.type.emoji,
                                      style: const TextStyle(fontSize: 50),
                                    ),
                                    if (pet.currentAccessory.isNotEmpty)
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Text(
                                          _getAccessoryEmoji(
                                            pet.currentAccessory,
                                          ),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildCompactStatBar(
                                      'Health',
                                      pet.health,
                                      Colors.red,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildCompactStatBar(
                                      'Hunger',
                                      pet.hunger,
                                      Colors.orange,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildCompactStatBar(
                                      'Happiness',
                                      pet.happiness,
                                      Colors.yellow,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildCompactStatBar(
                                      'Energy',
                                      pet.energy,
                                      Colors.blue,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: GridView.count(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              children: [
                                _buildCompactActionItem(
                                  icon: Icons.restaurant,
                                  label: 'Feed\n(F)',
                                  color: Colors.orange,
                                  onTap: () =>
                                      _performAction(gameProvider, 'feed'),
                                ),
                                _buildCompactActionItem(
                                  icon: Icons.toys,
                                  label: 'Play\n(P)',
                                  color: Colors.purple,
                                  onTap: () =>
                                      _performAction(gameProvider, 'play'),
                                ),
                                _buildCompactActionItem(
                                  icon: Icons.bed,
                                  label: 'Sleep\n(S)',
                                  color: Colors.blue,
                                  onTap: () =>
                                      _performAction(gameProvider, 'sleep'),
                                ),
                                _buildCompactActionItem(
                                  icon: Icons.shower,
                                  label: 'Clean\n(C)',
                                  color: Colors.cyan,
                                  onTap: () =>
                                      _performAction(gameProvider, 'clean'),
                                ),
                                _buildCompactActionItem(
                                  icon: Icons.school,
                                  label: 'Train\n(T)',
                                  color: Colors.green,
                                  onTap: () =>
                                      _performAction(gameProvider, 'train'),
                                ),
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
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _showGamesDialog(context),
                                  icon: const Icon(Icons.games),
                                  label: const Text('Games (G)'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _showStatsDialog(context, pet),
                                  icon: const Icon(Icons.analytics),
                                  label: const Text('Stats'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
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

  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup & Restore'),
        content: const Text('Choose an option:'),
        actions: [
          TextButton(
            onPressed: () async {
              final success = await context.read<GameProvider>().backupPet();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Backup created!' : 'Backup failed',
                    ),
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Backup Now'),
          ),
          TextButton(
            onPressed: () async {
              final backups = await context.read<GameProvider>().listBackups();
              if (backups.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No backups found')),
                );
                Navigator.pop(context);
                return;
              }
              // Show backup list
              Navigator.pop(context);
              _showBackupListDialog(context, backups);
            },
            child: const Text('Restore'),
          ),
          TextButton(
            onPressed: () async {
              final success = await context.read<GameProvider>().exportToUSB();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Exported to storage!' : 'Export failed',
                    ),
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Export to USB'),
          ),
          TextButton(
            onPressed: () async {
              final success =
                  await context.read<GameProvider>().importFromUSB();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Imported from USB!' : 'Import failed',
                    ),
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Import from USB'),
          ),
          TextButton(
            onPressed: () async {
              final success = await context.read<GameProvider>().shareBackup();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Backup shared!' : 'Share failed'),
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Share Backup'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showBackupListDialog(BuildContext context, List<File> backups) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Backup'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: backups.length,
            itemBuilder: (context, index) {
              final file = backups[index];
              return ListTile(
                title: Text(file.path.split('/').last),
                onTap: () async {
                  final success = await context
                      .read<GameProvider>()
                      .restoreFromBackup(file);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Restored!' : 'Restore failed'),
                      ),
                    );
                    Navigator.pop(context);
                    Navigator.pop(context);
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help'),
        content: const Text(
          'Keyboard Shortcuts:\n'
          'F - Feed\n'
          'P - Play\n'
          'C - Clean\n'
          'S - Sleep\n'
          'T - Train\n'
          'M - Medicine\n\n'
          'Keep your pet happy by managing hunger, energy, cleanliness, and health!\n'
          'Pet evolves at levels 10, 20, 35, and 50.\n'
          'Premium pets (Phoenix, Griffin, Unicorn) available with upgrade!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showGamesDialog(BuildContext context) {
    final games = context.read<GameProvider>().availableGames;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mini Games'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: games
                .map(
                  (game) => ListTile(
                    leading: Text(
                      game['icon'] as String,
                      style: const TextStyle(fontSize: 30),
                    ),
                    title: Text(game['name'] as String),
                    subtitle: Text(game['description'] as String),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${game['name']} coming soon!')),
                      );
                    },
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showStatsDialog(BuildContext context, Pet pet) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pet Stats'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('❤️ Health: ${pet.health}%'),
            Text('🍽️ Hunger: ${pet.hunger}%'),
            Text('⚡ Energy: ${pet.energy}%'),
            Text('🧼 Cleanliness: ${pet.cleanliness}%'),
            Text('😊 Happiness: ${pet.happiness}%'),
            Text('🧠 Intelligence: ${pet.intelligence}'),
            Text('👥 Social: ${pet.social}'),
            Text('🤝 Loyalty: ${pet.loyalty}'),
            Text('💰 Coins: ${pet.coins}'),
            Text('💎 Gems: ${pet.gems}'),
            Text('⭐ Level: ${pet.level}'),
            Text('📈 XP: ${pet.xp}/${pet.xpToNextLevel}'),
            Text('🎭 Mood: ${pet.moodEmoji} ${pet.currentMood}'),
            Text('🔄 Evolution: ${pet.evolutionEmoji} ${pet.evolutionStage}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
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
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$value%',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
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

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D2D3A),
      appBar: AppBar(
        title: const Text('⚙️ Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF7B1FA2),
        centerTitle: true,
      ),
      body: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          return Consumer<AccountProvider>(
            builder: (context, accountProvider, child) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2C),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.volume_up, color: Colors.white54),
                                SizedBox(width: 12),
                                Text(
                                  'Sound',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: gameProvider.soundEnabled,
                              onChanged: (value) => gameProvider.toggleSound(),
                              activeColor: const Color(0xFF7B1FA2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2C),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber),
                                SizedBox(width: 12),
                                Text(
                                  'Premium',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '✨ Premium is free and active! ✨',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2C),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.account_circle,
                                  color: Colors.white54,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Account',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (accountProvider.isLoggedIn &&
                                accountProvider.account != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Username: ${accountProvider.account!.username}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    'Email: ${accountProvider.account!.email}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () => accountProvider.logout(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: const Text('Logout'),
                                  ),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  const Text(
                                    'Not logged in',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () => _showLoginDialog(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF7B1FA2),
                                    ),
                                    child: const Text('Login'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E2C),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info, color: Colors.white54),
                                SizedBox(width: 12),
                                Text(
                                  'About',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Kitty Adventure',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const Text(
                              'Version 26.8.6',
                              style: TextStyle(color: Colors.white70),
                            ),
                            const Text(
                              'Build your virtual pet from baby to elder!',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    final usernameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (usernameController.text.isNotEmpty &&
                  emailController.text.isNotEmpty) {
                context.read<AccountProvider>().login(
                      usernameController.text,
                      emailController.text,
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}

// ==================== MAIN APP ====================

class KittyAdventureApp extends StatelessWidget {
  const KittyAdventureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<app_game.GameProvider>(
      builder: (context, gameProvider, child) {
        return MaterialApp(
          title: 'Kitty Adventure',
          debugShowCheckedModeBanner: false,
          themeMode:
              gameProvider.darkModeEnabled ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF76B7),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFFFF7D6),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF76B7),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF151827),
          ),
          home: const AppWrapper(child: PetGameScreen()),
        );
      },
    );
  }
}

Widget _buildLoadingErrorWidget(FlutterErrorDetails details) {
  return const Directionality(
    textDirection: TextDirection.ltr,
    child: Material(
      color: Color(0xFF151827),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: CircularProgressIndicator(
                strokeWidth: 5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF76B7)),
              ),
            ),
            SizedBox(height: 18),
            Text(
              'Loading...',
              style: TextStyle(
                color: Color(0xFFFFEAC2),
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'One sec while Kitty catches up.',
              style: TextStyle(
                color: Color(0xFFFFC98E),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = _buildLoadingErrorWidget;

  // Request permissions for storage (optional, don't block startup)
  try {
    await [Permission.storage, Permission.manageExternalStorage].request();
  } catch (e) {
    // Permissions failed, continue without them
  }

  final gameProvider = app_game.GameProvider();
  final accountProvider = app_account.AccountProvider();
  final notificationService = app_notifications.NotificationService();

  try {
    await gameProvider.loadGame();
  } catch (e) {
    // Continue even if game fails to load
  }

  try {
    notificationService.showDailyRewardNotification();
    notificationService.showSystemNotification(
      'Welcome Back!',
      'Your pet missed you!',
    );
  } catch (e) {
    // Continue even if notifications fail
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: gameProvider),
        ChangeNotifierProvider.value(value: accountProvider),
        Provider.value(value: notificationService),
      ],
      child: const KittyAdventureApp(),
    ),
  );
}
