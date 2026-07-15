import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/pet.dart';
import '../providers/game_provider.dart';
import '../services/update_service.dart';
import 'block_builder_game_screen.dart';
import 'docs_screen.dart';
import 'memory_match_screen.dart';
import 'obstacle_course_screen.dart';
import 'notifications_screen.dart';
import 'puzzle_game_screen.dart';
import 'puzzle_master_screen.dart';
import 'quiz_game_screen.dart';
import 'racing_game_screen.dart';
import 'rhythm_game_screen.dart';
import 'space_shooter_screen.dart';
import 'word_puzzle_screen.dart';

const String _realPetPortraitAsset =
    'assets/images/kitty_pet_real_cutout_26_9_1.png';
const String _realGardenBackgroundAsset =
    'assets/images/kitty_moon_garden_real_26_9_1.png';

String _petPortraitAssetForMood(PetMood mood) {
  return _realPetPortraitAsset;
}

class PetGameScreen extends StatefulWidget {
  const PetGameScreen({super.key});

  @override
  State<PetGameScreen> createState() => _PetGameScreenState();
}

class _PetGameScreenState extends State<PetGameScreen>
    with SingleTickerProviderStateMixin {
  static final Uri _downloadsUri =
      Uri.parse('https://kitty-adventure-zona.web.app/files/');

  late final AnimationController _motionController;

  Pet? _pet;
  final List<Pet> _cats = [];
  int _selectedCatIndex = 0;
  bool _initialized = false;
  bool _dailyQuestsLoaded = false;
  bool _dailyStreakLoaded = false;
  // ignore: unused_field
  int _dailyStreakCount = 0;
  // ignore: unused_field
  String _lastDailyStreakDate = '';
  bool _vibrationEnabled = true;
  bool _notificationsEnabled = true;
  final Map<String, int> _questProgress = {};
  final Set<String> _claimedQuestIds = {};
  final Set<String> _foundEasterEggIds = {};
  final Set<String> _redeemedSecretCodes = {};

  static const List<String> _favoriteFoods = [
    'Tuna Crunch',
    'Moon Milk',
    'Salmon Sprinkle',
    'Tiny Pancakes',
    'Cheese Pebbles',
    'Cloud Pudding',
    'Snack Confetti',
  ];

  static const List<String> _favoriteToys = [
    'Blue Bounce Ball',
    'Suspicious Ribbon',
    'Tiny Telescope',
    'Squeaky Cloud',
    'Royal Sock',
    'Puzzle Mouse',
    'Nap Blanket',
  ];

  static const List<String> _catBios = [
    'Professional nap critic with dramatic snack opinions.',
    'Runs the house like a tiny mayor with excellent eyeliner.',
    'Believes every button is a mystery and every mystery is edible.',
    'Quietly brave, loudly cute, and allergic to boring afternoons.',
    'Has a five-step plan for snacks and zero steps for taxes.',
    'Part-time explorer, full-time soft chaos consultant.',
    'Treat inspector with suspiciously convenient standards.',
  ];

  static final List<_DailyQuest> _dailyQuests = [
    _DailyQuest(
      id: 'feed_three',
      actionKey: 'feed',
      title: 'Snack Time',
      detail: 'Feed Kitty 3 times',
      target: 3,
      rewardCoins: 45,
      rewardGems: 1,
      rewardXp: 20,
      icon: Icons.restaurant,
      color: Color(0xFFFF8A4B),
    ),
    _DailyQuest(
      id: 'play_games',
      actionKey: 'mini_game',
      title: 'Game Break',
      detail: 'Play 2 mini-games',
      target: 2,
      rewardCoins: 70,
      rewardGems: 2,
      rewardXp: 30,
      icon: Icons.sports_esports,
      color: Color(0xFF7C8CFF),
    ),
    _DailyQuest(
      id: 'clean_once',
      actionKey: 'clean',
      title: 'Fresh Fur',
      detail: 'Clean Kitty once',
      target: 1,
      rewardCoins: 35,
      rewardGems: 1,
      rewardXp: 15,
      icon: Icons.bubble_chart,
      color: Color(0xFF52D6E7),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
  }

  @override
  void dispose() {
    _motionController.dispose();
    super.dispose();
  }

  static final List<_RoomDecorItem> _roomDecorItems = [
    _RoomDecorItem(
      id: 'flower_garden',
      name: 'Flower Garden',
      price: 0,
      icon: Icons.local_florist,
      color: Color(0xFF70C77D),
    ),
    _RoomDecorItem(
      id: 'cozy_bed',
      name: 'Cozy Bed',
      price: 140,
      icon: Icons.bed,
      color: Color(0xFF86A8FF),
    ),
    _RoomDecorItem(
      id: 'toy_basket',
      name: 'Toy Basket',
      price: 180,
      icon: Icons.toys,
      color: Color(0xFFFF9D6E),
    ),
    _RoomDecorItem(
      id: 'star_wallpaper',
      name: 'Star Wallpaper',
      price: 220,
      icon: Icons.auto_awesome,
      color: Color(0xFFFFC94A),
    ),
    _RoomDecorItem(
      id: 'party_balloons',
      name: 'Party Balloons',
      price: 260,
      icon: Icons.celebration,
      color: Color(0xFFFF76B7),
    ),
  ];

  static final List<_OutfitItem> _outfitItems = [
    _OutfitItem(
      id: '',
      name: 'No Outfit',
      emoji: '🐾',
      price: 0,
      color: Color(0xFF8CCB87),
    ),
    _OutfitItem(
      id: 'party_hat',
      name: 'Party Hat',
      emoji: '🎉',
      price: 120,
      color: Color(0xFFFF76B7),
    ),
    _OutfitItem(
      id: 'pink_bow',
      name: 'Pink Bow',
      emoji: '🎀',
      price: 150,
      color: Color(0xFFFF80AB),
    ),
    _OutfitItem(
      id: 'cool_shades',
      name: 'Cool Shades',
      emoji: '😎',
      price: 180,
      color: Color(0xFF70B8FF),
    ),
    _OutfitItem(
      id: 'star_collar',
      name: 'Star Collar',
      emoji: '⭐',
      price: 220,
      color: Color(0xFFFFC94A),
    ),
    _OutfitItem(
      id: 'sleepy_mask',
      name: 'Sleepy Mask',
      emoji: '😴',
      price: 160,
      color: Color(0xFF8EA7FF),
    ),
    _OutfitItem(
      id: 'explorer_bandana',
      name: 'Explorer Bandana',
      emoji: '🧭',
      price: 210,
      color: Color(0xFF66C58D),
    ),
    _OutfitItem(
      id: 'royal_crown',
      name: 'Royal Crown',
      emoji: '👑',
      price: 280,
      color: Color(0xFFFFB84D),
    ),
  ];

  static final List<_OutfitSet> _outfitSets = [
    _OutfitSet(
      id: 'party_set',
      name: 'Party Set',
      detail: '+12 Happy, +10 Social',
      requiredAccessories: ['party_hat', 'star_collar'],
      featuredAccessory: 'party_hat',
      color: Color(0xFFFF76B7),
      icon: Icons.celebration,
      happyBonus: 12,
      socialBonus: 10,
    ),
    _OutfitSet(
      id: 'sleep_set',
      name: 'Sleep Set',
      detail: '+18 Energy, +6 Health',
      requiredAccessories: ['sleepy_mask', 'pink_bow'],
      featuredAccessory: 'sleepy_mask',
      color: Color(0xFF8EA7FF),
      icon: Icons.bedtime,
      energyBonus: 18,
      healthBonus: 6,
    ),
    _OutfitSet(
      id: 'explorer_set',
      name: 'Explorer Set',
      detail: '+10 IQ, +75 Coins',
      requiredAccessories: ['explorer_bandana', 'cool_shades'],
      featuredAccessory: 'explorer_bandana',
      color: Color(0xFF66C58D),
      icon: Icons.explore,
      intelligenceBonus: 10,
      coinBonus: 75,
    ),
    _OutfitSet(
      id: 'royal_set',
      name: 'Royal Set',
      detail: '+15 Bond, +4 Gems',
      requiredAccessories: ['royal_crown', 'star_collar'],
      featuredAccessory: 'royal_crown',
      color: Color(0xFFFFB84D),
      icon: Icons.workspace_premium,
      bondBonus: 15,
      gemBonus: 4,
    ),
  ];

  static final List<_CatJob> _catJobs = [
    _CatJob(
      id: 'snack_scout',
      name: 'Snack Scout',
      detail: 'Finds coins and lowers hunger.',
      icon: Icons.search,
      color: Color(0xFFFF8A4B),
      duration: Duration(seconds: 45),
      coinReward: 80,
      hungerReduction: 12,
    ),
    _CatJob(
      id: 'nap_expert',
      name: 'Nap Expert',
      detail: 'Returns rested and healthier.',
      icon: Icons.hotel,
      color: Color(0xFF8EA7FF),
      duration: Duration(seconds: 60),
      energyReward: 24,
      healthReward: 8,
    ),
    _CatJob(
      id: 'toy_tester',
      name: 'Toy Tester',
      detail: 'Tests toys for happiness and XP.',
      icon: Icons.toys,
      color: Color(0xFFFF76B7),
      duration: Duration(seconds: 75),
      happyReward: 18,
      xpReward: 25,
    ),
    _CatJob(
      id: 'coin_scout',
      name: 'Coin Scout',
      detail: 'Comes back with shiny treasure.',
      icon: Icons.attach_money,
      color: Color(0xFFFFC94A),
      duration: Duration(seconds: 90),
      coinReward: 160,
      gemReward: 1,
    ),
  ];

  static final List<_SecretCode> _secretCodes = [
    _SecretCode(
      code: 'MEOW2026',
      title: 'Future Meow Fund',
      detail: '+250 coins and +3 gems',
      coins: 250,
      gems: 3,
    ),
    _SecretCode(
      code: 'NAPKING',
      title: 'Nap Royalty',
      detail: 'Unlocks Cozy Bed and restores energy',
      energy: 35,
      unlockRoom: 'cozy_bed',
    ),
    _SecretCode(
      code: 'ANNIVERSARY3',
      title: 'Third Anniversary Gift',
      detail: 'Unlocks Party Balloons and bonus coins',
      coins: 300,
      unlockRoom: 'party_balloons',
    ),
    _SecretCode(
      code: 'EGGHUNT',
      title: 'Secret Hunter',
      detail: '+1 gem and a hint to tap everything',
      gems: 1,
      happiness: 20,
    ),
    _SecretCode(
      code: 'DARKKITTY',
      title: 'Night Mode Snacks',
      detail: '+180 coins, +2 gems, and a cozy happy boost',
      coins: 180,
      gems: 2,
      happiness: 18,
    ),
    _SecretCode(
      code: 'COMBOREADY',
      title: 'Build Combo Fuel',
      detail: '+420 coins, +3 gems, and Star Wallpaper',
      coins: 420,
      gems: 3,
      unlockRoom: 'star_wallpaper',
    ),
    _SecretCode(
      code: 'RELEASEDAY',
      title: 'Release Day Treats',
      detail: '+300 coins, energy, and happiness',
      coins: 300,
      energy: 25,
      happiness: 25,
    ),
  ];

  // ignore: unused_field
  static final List<_AchievementBadge> _achievementBadges = [
    _AchievementBadge(
      id: 'first_adoption',
      title: 'First Adoption',
      detail: 'Have 2 cats in the family.',
      icon: Icons.pets,
      color: Color(0xFFFF76B7),
    ),
    _AchievementBadge(
      id: 'seven_cats',
      title: '7 Cat Household',
      detail: 'Collect 7 cats.',
      icon: Icons.groups,
      color: Color(0xFF70B8FF),
    ),
    _AchievementBadge(
      id: 'egg_hunter',
      title: 'Egg Hunter',
      detail: 'Find 3 easter eggs.',
      icon: Icons.emoji_events,
      color: Color(0xFFFFB84D),
    ),
    _AchievementBadge(
      id: 'secret_keeper',
      title: 'Secret Keeper',
      detail: 'Redeem 3 secret codes.',
      icon: Icons.key,
      color: Color(0xFF8EA7FF),
    ),
    _AchievementBadge(
      id: 'room_stylist',
      title: 'Room Stylist',
      detail: 'Own 3 room decorations.',
      icon: Icons.chair,
      color: Color(0xFF66C58D),
    ),
    _AchievementBadge(
      id: 'outfit_collector',
      title: 'Outfit Collector',
      detail: 'Own 3 outfit pieces.',
      icon: Icons.checkroom,
      color: Color(0xFFD77BFF),
    ),
    _AchievementBadge(
      id: 'night_owl',
      title: 'Night Owl',
      detail: 'Turn on Dark Mode.',
      icon: Icons.dark_mode,
      color: Color(0xFF9A8CFF),
    ),
    _AchievementBadge(
      id: 'lite_legend',
      title: 'Lite Legend',
      detail: 'Turn on Lite Mode.',
      icon: Icons.speed,
      color: Color(0xFF66D0C4),
    ),
    _AchievementBadge(
      id: 'streak_starter',
      title: 'Streak Starter',
      detail: 'Reach a 2 day streak.',
      icon: Icons.local_fire_department,
      color: Color(0xFFFF8A4B),
    ),
  ];

  // ignore: unused_field
  static final List<_ReleaseChecklistItem> _releaseChecklist = [
    _ReleaseChecklistItem(
      title: 'Version locked',
      detail: 'Keep player-facing version text on v26.8.4 unless we bump it.',
      icon: Icons.verified,
      color: Color(0xFF66C58D),
    ),
    _ReleaseChecklistItem(
      title: 'Docs and changelog',
      detail: 'README and What\'s New mention the new release features.',
      icon: Icons.article,
      color: Color(0xFFFFB84D),
    ),
    _ReleaseChecklistItem(
      title: 'Web sanity test',
      detail: 'Open localhost, force reload, and poke the new settings.',
      icon: Icons.public,
      color: Color(0xFF70B8FF),
    ),
    _ReleaseChecklistItem(
      title: 'Build combo',
      detail: 'Run ./combo.sh after final testing.',
      icon: Icons.build_circle,
      color: Color(0xFFD77BFF),
    ),
    _ReleaseChecklistItem(
      title: 'Sideload package',
      detail: 'Confirm the IPA lands in build/combo for Sideloadly.',
      icon: Icons.phone_iphone,
      color: Color(0xFF8EA7FF),
    ),
  ];

  static final List<_EasterEggSpot> _easterEggs = [
    _EasterEggSpot(
      id: 'anniversary',
      title: 'Anniversary Banner',
      trigger: 'Tap the 3rd Anniversary banner.',
      actionLabel: '3RD',
      messages: [
        '3 years in and Kitty still has not paid rent.',
        'Anniversary mode: emotionally loud, financially suspicious.',
        'The cake is imaginary. The crumbs are legally real.',
      ],
    ),
    _EasterEggSpot(
      id: 'mood',
      title: 'Mood Scanner',
      trigger: 'Long-press the mood card.',
      actionLabel: 'MOOD',
      messages: [
        'Mood scan complete: 82% cute, 18% plotting snack logistics.',
        'Kitty has entered tiny CEO mode. Meetings are cancelled.',
        'Current vibe: professionally adorable with mild chaos.',
      ],
    ),
    _EasterEggSpot(
      id: 'sun',
      title: 'Opinionated Sun',
      trigger: 'Tap the sun.',
      actionLabel: 'SUN',
      messages: [
        'The sun says: I am not a button, but I respect the curiosity.',
        'Solar report: bright, round, deeply invested in Kitty lore.',
        'You tapped daylight. Daylight tapped back spiritually.',
      ],
    ),
    _EasterEggSpot(
      id: 'cat',
      title: 'Cat Inspection',
      trigger: 'Double-tap or long-press your cat.',
      actionLabel: 'CAT',
      messages: [
        'Double-tap detected. Kitty now believes this is a formal handshake.',
        'Kitty has accepted your tap and filed it under compliments.',
        'Secret cat inspection passed. The tail committee approves.',
      ],
    ),
    _EasterEggSpot(
      id: 'coins',
      title: 'Coin Accountant',
      trigger: 'Long-press the top stats bar.',
      actionLabel: 'COINS',
      messages: [
        'Financial report: coins are shiny, math is dramatic.',
        'Kitty checked the budget and bought one imaginary yacht.',
        'Coin counter says: please stop staring, I am doing my best.',
      ],
    ),
    _EasterEggSpot(
      id: 'manager',
      title: 'Manager Memo',
      trigger: 'Long-press Manage or Adopt.',
      actionLabel: 'MANAGE',
      messages: [
        'Cat Manager has entered clipboard mode. Very official. Extremely tiny.',
        'Management note: all cats requested snacks as a team-building exercise.',
        'This center is 40% organization and 60% adorable paperwork.',
      ],
    ),
    _EasterEggSpot(
      id: 'cloud',
      title: 'Cloud Forecast',
      trigger: 'Tap either cloud.',
      actionLabel: 'CLOUD',
      messages: [
        'Cloud status: fluffy, suspiciously unemployed, emotionally supportive.',
        'You poked a cloud. Forecast: mild silliness with scattered snacks.',
        'Cloud has no pockets, yet somehow misplaced three rain checks.',
      ],
    ),
    _EasterEggSpot(
      id: 'house',
      title: 'Tiny House Report',
      trigger: 'Tap the house.',
      actionLabel: 'HOUSE',
      messages: [
        'House report: rent is paid in purrs and questionable dance moves.',
        'The tiny house has a tiny mortgage and enormous confidence.',
        'Doorbell unavailable. Please meow into the welcome mat.',
      ],
    ),
    _EasterEggSpot(
      id: 'flower',
      title: 'Flower Gossip',
      trigger: 'Tap flowers or bushes.',
      actionLabel: 'FLOWER',
      messages: [
        'Flower gossip says Kitty is the main character. No objections found.',
        'Petal committee meeting result: more snacks, fewer responsibilities.',
        'The flowers practiced jazz paws. Botanically confusing, spiritually right.',
      ],
    ),
    _EasterEggSpot(
      id: 'tree',
      title: 'Tree Wisdom',
      trigger: 'Double-tap the tree.',
      actionLabel: 'TREE',
      messages: [
        'Tree wisdom: hydrate, stretch, and never trust a silent treat jar.',
        'This tree has seen 3 years of drama and remains leaf-level calm.',
        'Branch office memo: Kitty is promoted to Chief Nap Officer.',
      ],
    ),
    _EasterEggSpot(
      id: 'settings',
      title: 'Gear Nonsense',
      trigger: 'Long-press Settings.',
      actionLabel: 'GEAR',
      messages: [
        'Settings gear spun once and immediately demanded a title card.',
        'Secret setting found: make everything 12% more ridiculous.',
        'Gear says: I control options, not consequences.',
      ],
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final gameProvider = context.read<GameProvider>();
    _pet = gameProvider.pet ?? _createDefaultPet();

    if (!gameProvider.hasPet && _pet != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<GameProvider>().setPet(_pet!);
        }
      });
    }

    _initialized = true;
    _loadCatCollection(_pet!);
    _loadDailyQuests();
    _loadEasterEggJournal();
    _loadSecretCodes();
  }

  Pet _createDefaultPet({String name = 'Kitty'}) {
    return Pet(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      type: PetType.cat,
    )
      ..level = 1
      ..health = 100
      ..hunger = 30
      ..happiness = 80
      ..energy = 90
      ..cleanliness = 90
      ..coins = 1250
      ..roomDecorations = ['flower_garden']
      ..currentRoomDecor = 'flower_garden';
  }

  void _ensureCatDefaults(Pet cat) {
    if (cat.id.isEmpty) {
      cat.id = DateTime.now().microsecondsSinceEpoch.toString();
    }
    if (cat.name.trim().isEmpty || cat.name == 'Unknown Pet') {
      cat.name = _nextCatName();
    }
    if (cat.roomDecorations.isEmpty) {
      cat.roomDecorations.add('flower_garden');
    }
    if (cat.currentRoomDecor.isEmpty) {
      cat.currentRoomDecor = cat.roomDecorations.first;
    }
    if (cat.favoriteFood.trim().isEmpty) {
      cat.favoriteFood = _profilePick(_favoriteFoods, cat.id + cat.name);
    }
    if (cat.favoriteToy.trim().isEmpty) {
      cat.favoriteToy = _profilePick(_favoriteToys, cat.name + cat.id);
    }
    if (cat.bio.trim().isEmpty) {
      cat.bio = _profilePick(_catBios, '${cat.id}:${cat.name}');
    }
  }

  String _profilePick(List<String> values, String seed) {
    final hash = seed.codeUnits.fold<int>(0, (sum, code) => sum + code);
    return values[hash % values.length];
  }

  bool get _isDarkMode => Theme.of(context).brightness == Brightness.dark;

  Color get _pageBackgroundColor =>
      _isDarkMode ? const Color(0xFF101624) : const Color(0xFFDCEFF7);

  Color get _panelColor => _isDarkMode
      ? const Color(0xFF1B2436).withValues(alpha: 0.94)
      : const Color(0xFFF7FBFF).withValues(alpha: 0.86);

  Color get _solidPanelColor =>
      _isDarkMode ? const Color(0xFF1B2436) : const Color(0xFFF7FBFF);

  Color get _dialogColor =>
      _isDarkMode ? const Color(0xFF151B2B) : const Color(0xFFF7FBFF);

  Color get _primaryTextColor =>
      _isDarkMode ? const Color(0xFFEAF6FF) : const Color(0xFF334052);

  Color get _secondaryTextColor =>
      _isDarkMode ? const Color(0xFFAEC8E8) : const Color(0xFF60728A);

  Color get _borderColor =>
      _isDarkMode ? const Color(0xFF81D4FA) : const Color(0xFF86BBD8);

  Color get _strongBorderColor =>
      _isDarkMode ? const Color(0xFFB9A7FF) : const Color(0xFF6377C6);

  Color get _trackColor =>
      _isDarkMode ? const Color(0xFF2C364D) : const Color(0xFFE3EDF7);

  List<Color> get _topBarColors => _isDarkMode
      ? const [Color(0xFF26324F), Color(0xFF151B2B)]
      : const [Color(0xFFB9DFFF), Color(0xFF7EA7E3)];

  List<Color> get _settingsButtonColors => _isDarkMode
      ? const [Color(0xFF68D8C5), Color(0xFF29516B)]
      : const [Color(0xFFC9F2EA), Color(0xFF76B7D3)];

  String _personalityLabel(PetPersonality personality) {
    switch (personality) {
      case PetPersonality.playful:
        return 'Playful';
      case PetPersonality.lazy:
        return 'Cozy';
      case PetPersonality.curious:
        return 'Curious';
      case PetPersonality.shy:
        return 'Shy';
      case PetPersonality.energetic:
        return 'Energetic';
      case PetPersonality.calm:
        return 'Calm';
    }
  }

  String _nextCatName() {
    const names = ['Kitty', 'Mochi', 'Bean', 'Luna', 'Nori', 'Sunny', 'Pip'];
    final usedNames = _cats.map((cat) => cat.name).toSet();
    for (final name in names) {
      if (!usedNames.contains(name)) return name;
    }
    return 'Kitty ${_cats.length + 1}';
  }

  Future<void> _loadCatCollection(Pet fallbackPet) async {
    final prefs = await SharedPreferences.getInstance();
    final catsJson = prefs.getString('kittyCatCollection');
    final savedIndex = prefs.getInt('selectedKittyCatIndex') ?? 0;
    final loadedCats = <Pet>[];

    if (catsJson != null) {
      final decoded = jsonDecode(catsJson);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            final cat = Pet.fromJson(Map<String, dynamic>.from(item));
            _ensureCatDefaults(cat);
            loadedCats.add(cat);
          }
        }
      }
    }

    if (loadedCats.isEmpty) {
      _ensureCatDefaults(fallbackPet);
      loadedCats.add(fallbackPet);
    }

    if (!mounted) return;

    setState(() {
      _cats
        ..clear()
        ..addAll(loadedCats);
      _selectedCatIndex = savedIndex.clamp(0, _cats.length - 1).toInt();
      _pet = _cats[_selectedCatIndex];
    });
    _syncPetToProvider();
    _loadDailyStreakReward();
  }

  Future<void> _saveCatCollection() async {
    if (_cats.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'kittyCatCollection',
      jsonEncode(_cats.map((cat) => cat.toJson()).toList()),
    );
    await prefs.setInt('selectedKittyCatIndex', _selectedCatIndex);
  }

  void _syncSelectedCat() {
    final pet = _pet;
    if (pet == null) return;

    if (_cats.isEmpty) {
      _cats.add(pet);
      _selectedCatIndex = 0;
      return;
    }

    _selectedCatIndex = _selectedCatIndex.clamp(0, _cats.length - 1).toInt();
    _cats[_selectedCatIndex] = pet;
  }

  Future<void> _syncPetToProvider() async {
    final pet = _pet;
    if (!mounted || pet == null) return;
    _syncSelectedCat();
    context.read<GameProvider>().setPet(pet);
    await _saveCatCollection();
  }

  void _createPet() {
    final newPet = _createDefaultPet();
    setState(() {
      _cats
        ..clear()
        ..add(newPet);
      _selectedCatIndex = 0;
      _pet = newPet;
    });
    _syncPetToProvider();
  }

  void _adoptCat() {
    final newCat = _createDefaultPet(name: _nextCatName())
      ..coins = 500
      ..happiness = 90
      ..energy = 90
      ..currentMood = PetMood.excited;

    setState(() {
      _syncSelectedCat();
      _cats.add(newCat);
      _selectedCatIndex = _cats.length - 1;
      _pet = newCat;
    });
    _syncPetToProvider();
    _showPetActionMessage('${newCat.name} joined the family');
  }

  void _selectCat(int index) {
    if (index < 0 || index >= _cats.length) return;

    setState(() {
      _syncSelectedCat();
      _selectedCatIndex = index;
      _pet = _cats[index];
      _refreshMood();
    });
    _syncPetToProvider();
  }

  String _todayQuestKey() {
    return _dateKey(DateTime.now());
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  _DailyStreakReward _streakRewardFor(int streak) {
    final cappedStreak = streak.clamp(1, 30);
    return _DailyStreakReward(
      day: streak,
      coins: 70 + cappedStreak * 15,
      gems: cappedStreak % 3 == 0 ? 2 : 1,
      xp: 12 + cappedStreak * 4,
    );
  }

  Future<void> _loadDailyStreakReward() async {
    if (_dailyStreakLoaded || _pet == null) return;

    final prefs = await SharedPreferences.getInstance();
    final today = _todayQuestKey();
    final yesterday = _dateKey(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final savedDate = prefs.getString('dailyStreakDate') ?? '';
    final savedStreak = prefs.getInt('dailyStreakCount') ?? 0;

    if (!mounted) return;

    if (savedDate == today) {
      setState(() {
        _dailyStreakLoaded = true;
        _lastDailyStreakDate = savedDate;
        _dailyStreakCount = savedStreak;
      });
      return;
    }

    final streak = savedDate == yesterday ? savedStreak + 1 : 1;
    final reward = _streakRewardFor(streak);

    setState(() {
      _dailyStreakLoaded = true;
      _lastDailyStreakDate = today;
      _dailyStreakCount = streak;
      _pet!.coins += reward.coins;
      _pet!.gems += reward.gems;
      _pet!.addXp(reward.xp);
      _refreshMood(PetMood.excited);
    });

    await prefs.setString('dailyStreakDate', today);
    await prefs.setInt('dailyStreakCount', streak);
    _syncPetToProvider();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showDailyStreakRewardDialog(reward);
    });
  }

  void _showDailyStreakRewardDialog(_DailyStreakReward reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _dialogColor,
        title: Text(
          'Day ${reward.day} Streak',
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department,
              color: const Color(0xFFFF8A4B),
              size: 58,
            ),
            const SizedBox(height: 12),
            Text(
              'You came back today. Kitty has prepared a very official pile of rewards.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _primaryTextColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            _buildRewardRow(Icons.attach_money, 'Coins', reward.coins),
            _buildRewardRow(Icons.diamond, 'Gems', reward.gems),
            _buildRewardRow(Icons.auto_awesome, 'XP', reward.xp),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Claimed'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadDailyQuests() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayQuestKey();
    final savedDate = prefs.getString('dailyQuestDate');

    if (!mounted) return;

    if (savedDate != today) {
      await prefs.setString('dailyQuestDate', today);
      await prefs.remove('dailyQuestProgress');
      await prefs.remove('claimedDailyQuests');
      setState(() {
        _questProgress.clear();
        _claimedQuestIds.clear();
        _dailyQuestsLoaded = true;
      });
      return;
    }

    final progressJson = prefs.getString('dailyQuestProgress');
    final claimedJson = prefs.getString('claimedDailyQuests');

    setState(() {
      _questProgress
        ..clear()
        ..addAll(
          progressJson == null
              ? {}
              : Map<String, int>.from(jsonDecode(progressJson)),
        );
      _claimedQuestIds
        ..clear()
        ..addAll(
          claimedJson == null
              ? <String>{}
              : Set<String>.from(jsonDecode(claimedJson) as List),
        );
      _dailyQuestsLoaded = true;
    });
  }

  Future<void> _saveDailyQuests() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dailyQuestDate', _todayQuestKey());
    await prefs.setString('dailyQuestProgress', jsonEncode(_questProgress));
    await prefs.setString(
      'claimedDailyQuests',
      jsonEncode(_claimedQuestIds.toList()),
    );
  }

  Future<void> _loadEasterEggJournal() async {
    final prefs = await SharedPreferences.getInstance();
    final eggsJson = prefs.getString('foundEasterEggs');
    if (!mounted || eggsJson == null) return;

    setState(() {
      _foundEasterEggIds
        ..clear()
        ..addAll(Set<String>.from(jsonDecode(eggsJson) as List));
    });
  }

  Future<void> _saveEasterEggJournal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'foundEasterEggs',
      jsonEncode(_foundEasterEggIds.toList()),
    );
  }

  Future<void> _loadSecretCodes() async {
    final prefs = await SharedPreferences.getInstance();
    final codesJson = prefs.getString('redeemedSecretCodes');
    if (!mounted || codesJson == null) return;

    setState(() {
      _redeemedSecretCodes
        ..clear()
        ..addAll(Set<String>.from(jsonDecode(codesJson) as List));
    });
  }

  Future<void> _saveSecretCodes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'redeemedSecretCodes',
      jsonEncode(_redeemedSecretCodes.toList()),
    );
  }

  void _completeQuestStep(String actionKey) {
    if (!_dailyQuestsLoaded) return;

    bool changed = false;
    setState(() {
      for (final quest in _dailyQuests.where((q) => q.actionKey == actionKey)) {
        if (_claimedQuestIds.contains(quest.id)) continue;
        final current = _questProgress[quest.id] ?? 0;
        if (current >= quest.target) continue;
        _questProgress[quest.id] = (current + 1).clamp(0, quest.target);
        changed = true;
      }
    });

    if (changed) {
      _saveDailyQuests();
    }
  }

  bool _isQuestReady(_DailyQuest quest) {
    return (_questProgress[quest.id] ?? 0) >= quest.target &&
        !_claimedQuestIds.contains(quest.id);
  }

  void _claimDailyQuest(_DailyQuest quest) {
    if (_pet == null || !_isQuestReady(quest)) return;

    setState(() {
      _claimedQuestIds.add(quest.id);
      _pet!.coins += quest.rewardCoins;
      _pet!.gems += quest.rewardGems;
      _pet!.addXp(quest.rewardXp);
      _refreshMood(PetMood.excited);
    });
    _saveDailyQuests();
    _syncPetToProvider();
    _showPetActionMessage(
      '${quest.title} claimed: +${quest.rewardCoins} coins, +${quest.rewardGems} gems',
    );
  }

  _EasterEggSpot _eggById(String id) {
    return _easterEggs.firstWhere(
      (egg) => egg.id == id,
      orElse: () => _easterEggs.first,
    );
  }

  _CatJob? _jobById(String id) {
    for (final job in _catJobs) {
      if (job.id == id) return job;
    }
    return null;
  }

  String _roomEffectDescription(String decorId) {
    switch (decorId) {
      case 'cozy_bed':
        return 'Sleep bonus: +10 energy, +5 health.';
      case 'toy_basket':
        return 'Play bonus: +8 happy, +3 IQ.';
      case 'star_wallpaper':
        return 'Train bonus: +5 IQ, +8 XP.';
      case 'party_balloons':
        return 'Bond bonus: +10 social, +5 bond.';
      case 'flower_garden':
      default:
        return 'Food bonus: +5 happy, +4 social.';
    }
  }

  String? _applyRoomBonus(Pet pet, String actionKey) {
    switch (pet.currentRoomDecor) {
      case 'cozy_bed':
        if (actionKey != 'sleep') return null;
        pet.energy = (pet.energy + 10).clamp(0, 100);
        pet.health = (pet.health + 5).clamp(0, 100);
        return 'Cozy Bed bonus';
      case 'toy_basket':
        if (actionKey != 'play') return null;
        pet.happiness = (pet.happiness + 8).clamp(0, 100);
        pet.intelligence = (pet.intelligence + 3).clamp(0, 100);
        return 'Toy Basket bonus';
      case 'star_wallpaper':
        if (actionKey != 'train') return null;
        pet.intelligence = (pet.intelligence + 5).clamp(0, 100);
        pet.addXp(8);
        return 'Star Wallpaper bonus';
      case 'party_balloons':
        if (actionKey != 'bond') return null;
        pet.social = (pet.social + 10).clamp(0, 100);
        pet.friendshipLevel = (pet.friendshipLevel + 5).clamp(0, 100);
        return 'Party Balloons bonus';
      case 'flower_garden':
      default:
        if (actionKey != 'feed') return null;
        pet.happiness = (pet.happiness + 5).clamp(0, 100);
        pet.social = (pet.social + 4).clamp(0, 100);
        return 'Flower Garden bonus';
    }
  }

  void _refreshMood([PetMood? preferredMood]) {
    final pet = _pet;
    if (pet == null) return;

    if (pet.health <= 20) {
      pet.currentMood = PetMood.sick;
    } else if (pet.hunger >= 80) {
      pet.currentMood = PetMood.hungry;
    } else if (pet.energy <= 20) {
      pet.currentMood = PetMood.sleepy;
    } else if (pet.happiness <= 20) {
      pet.currentMood = PetMood.sad;
    } else if (preferredMood != null) {
      pet.currentMood = preferredMood;
    } else if (pet.happiness >= 90 && pet.energy >= 80) {
      pet.currentMood = PetMood.excited;
    } else if (pet.friendshipLevel >= 50) {
      pet.currentMood = PetMood.loving;
    } else {
      pet.currentMood = PetMood.happy;
    }
  }

  void _feedPet() {
    if (_pet != null) {
      String? bonus;
      setState(() {
        _pet!.hunger = (_pet!.hunger - 25).clamp(0, 100);
        _pet!.happiness = (_pet!.happiness + 5).clamp(0, 100);
        _pet!.energy = (_pet!.energy + 5).clamp(0, 100);
        _pet!.coins = (_pet!.coins - 10).clamp(0, 9999);
        bonus = _applyRoomBonus(_pet!, 'feed');
        _refreshMood(PetMood.happy);
      });
      _syncPetToProvider();
      _completeQuestStep('feed');
      _showPetActionMessage(
          bonus == null ? 'Food served' : 'Food served • $bonus');
    }
  }

  void _playWithPet() {
    if (_pet == null) return;

    String? bonus;
    setState(() {
      _syncSelectedCat();
      for (final cat in _cats) {
        cat.happiness = (cat.happiness + 10).clamp(0, 100);
        cat.energy = (cat.energy - 6).clamp(0, 100);
        cat.hunger = (cat.hunger + 5).clamp(0, 100);
        if (cat == _cats[_selectedCatIndex]) {
          bonus = _applyRoomBonus(cat, 'play');
        }
        cat.currentMood = PetMood.playful;
      }
      _pet = _cats[_selectedCatIndex];
      _pet!.happiness = (_pet!.happiness + 5).clamp(0, 100);
      _refreshMood(PetMood.playful);
    });
    _syncPetToProvider();
    if (bonus != null) _showPetActionMessage('Play time • $bonus');
    _showPlayCutscene();
  }

  void _showPlayCutscene() {
    final cutsceneCats =
        _cats.isEmpty && _pet != null ? [_pet!] : List<Pet>.from(_cats);
    if (cutsceneCats.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => _PlayCutsceneDialog(cats: cutsceneCats),
    );
  }

  void _cleanPet() {
    if (_pet != null) {
      setState(() {
        _pet!.cleanliness = 100;
        _pet!.happiness = (_pet!.happiness + 8).clamp(0, 100);
        _pet!.health = (_pet!.health + 2).clamp(0, 100);
        _refreshMood(PetMood.happy);
      });
      _syncPetToProvider();
      _completeQuestStep('clean');
    }
  }

  void _sleepPet() {
    if (_pet == null) return;

    final oldLevel = _pet!.level;
    String? bonus;
    setState(() {
      _pet!.energy = (_pet!.energy + 50).clamp(0, 100);
      _pet!.health = (_pet!.health + 15).clamp(0, 100);
      _pet!.hunger = (_pet!.hunger + 5).clamp(0, 100);
      _pet!.currentMood = PetMood.sleepy;
      _pet!.addXp(5);
      bonus = _applyRoomBonus(_pet!, 'sleep');
    });
    _syncPetToProvider();
    _showPetActionMessage(
      _pet!.level > oldLevel
          ? 'Level up! Level ${_pet!.level}'
          : bonus == null
              ? 'Sleep done'
              : 'Sleep done • $bonus',
    );
  }

  void _trainPet() {
    if (_pet == null) return;

    String? bonus;
    setState(() {
      _pet!.energy = (_pet!.energy - 15).clamp(0, 100);
      _pet!.happiness = (_pet!.happiness + 8).clamp(0, 100);
      _pet!.intelligence = (_pet!.intelligence + 5).clamp(0, 100);
      _pet!.hunger = (_pet!.hunger + 10).clamp(0, 100);
      _pet!.addXp(15);
      bonus = _applyRoomBonus(_pet!, 'train');
      _refreshMood(PetMood.excited);
    });
    _syncPetToProvider();
    _showPetActionMessage(
      bonus == null ? 'Training complete' : 'Training complete • $bonus',
    );
  }

  void _bondWithPet() {
    if (_pet == null) return;

    final oldBond = _pet!.friendshipLevel;
    String? bonus;
    setState(() {
      _pet!.friendshipLevel = (_pet!.friendshipLevel + 8).clamp(0, 100);
      _pet!.loyalty = (_pet!.loyalty + 10).clamp(0, 100);
      _pet!.social = (_pet!.social + 8).clamp(0, 100);
      _pet!.happiness = (_pet!.happiness + 12).clamp(0, 100);
      bonus = _applyRoomBonus(_pet!, 'bond');
      _refreshMood(PetMood.loving);
    });
    _syncPetToProvider();
    final scene = _friendshipSceneFor(oldBond, _pet!.friendshipLevel);
    if (scene != null) {
      _showFriendshipCutscene(scene);
    } else {
      _showPetActionMessage(
        bonus == null ? 'Bond increased' : 'Bond increased • $bonus',
      );
    }
  }

  void _giveMedicine() {
    if (_pet == null) return;

    setState(() {
      _pet!.health = (_pet!.health + 30).clamp(0, 100);
      _pet!.happiness = (_pet!.happiness + 4).clamp(0, 100);
      _refreshMood(PetMood.happy);
    });
    _syncPetToProvider();
    _showPetActionMessage('Medicine given');
  }

  void _vaccinatePet() {
    if (_pet == null) return;

    setState(() {
      _pet!.health = (_pet!.health + 20).clamp(0, 100);
      _pet!.loyalty = (_pet!.loyalty + 4).clamp(0, 100);
      _pet!.social = (_pet!.social + 3).clamp(0, 100);
      _refreshMood(PetMood.happy);
    });
    _syncPetToProvider();
    _showPetActionMessage('Vaccine done');
  }

  _FriendshipScene? _friendshipSceneFor(int before, int after) {
    if (before < 100 && after >= 100) {
      return _FriendshipScene(
        title: 'Forever Friends',
        message:
            '${_pet?.name ?? 'Kitty'} brought out imaginary fireworks and declared you best humans.',
        icon: Icons.favorite,
        color: const Color(0xFFFF76B7),
      );
    }
    if (before < 75 && after >= 75) {
      return _FriendshipScene(
        title: 'Secret Handshake',
        message:
            '${_pet?.name ?? 'Kitty'} invented a handshake. It is mostly blinking and one dramatic paw.',
        icon: Icons.front_hand,
        color: const Color(0xFFFFB84D),
      );
    }
    if (before < 50 && after >= 50) {
      return _FriendshipScene(
        title: 'Bestie Moment',
        message:
            '${_pet?.name ?? 'Kitty'} saved you a seat in the very official snack club.',
        icon: Icons.groups,
        color: const Color(0xFF66C58D),
      );
    }
    if (before < 25 && after >= 25) {
      return _FriendshipScene(
        title: 'First Trust Scene',
        message:
            '${_pet?.name ?? 'Kitty'} leaned in close and trusted you with a tiny dramatic secret.',
        icon: Icons.auto_awesome,
        color: const Color(0xFF8EA7FF),
      );
    }
    return null;
  }

  void _showFriendshipCutscene(_FriendshipScene scene) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF7D6),
        title: Text(scene.title, textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scene.color.withValues(alpha: 0.18),
                border: Border.all(color: scene.color, width: 4),
              ),
              child: Icon(scene.icon, color: scene.color, size: 46),
            ),
            const SizedBox(height: 14),
            Text(
              scene.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF7A4B3B),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aww'),
          ),
        ],
      ),
    );
  }

  void _showPetActionMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(milliseconds: 900),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _showEasterEgg(String id) {
    if (!mounted) return;

    final egg = _eggById(id);
    final wasNew = _foundEasterEggIds.add(egg.id);
    if (wasNew) {
      _saveEasterEggJournal();
    }

    final message = egg
        .messages[DateTime.now().microsecondsSinceEpoch % egg.messages.length];
    final journalLine = wasNew
        ? '\nFound ${_foundEasterEggIds.length}/${_easterEggs.length}: ${egg.title}'
        : '';

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$message$journalLine'),
          duration: const Duration(milliseconds: 2300),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: egg.actionLabel,
            onPressed: () {},
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final liteMode = context.watch<GameProvider>().liteModeEnabled;

    if (_pet == null) {
      return Scaffold(
        backgroundColor:
            _isDarkMode ? const Color(0xFF151827) : const Color(0xFF87CEEB),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _pageBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(_pet!),
            _buildCatSelector(),
            _buildStatsPanel(_pet!),
            Expanded(
              child: Stack(
                children: [
                  _buildBackground(_pet!, liteMode),
                  Positioned(
                    top: 10,
                    left: 12,
                    right: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _buildMoodPanel(_pet!),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildAnniversaryBanner(),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 18,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: _buildPetCharacter(_pet!, liteMode),
                    ),
                  ),
                ],
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(Pet pet) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 5),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onLongPress: () => _showEasterEgg('coins'),
              child: Container(
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: _topBarColors,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _strongBorderColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF314467).withValues(alpha: 0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildCounterSegment(
                      icon: Icons.attach_money,
                      iconColor: const Color(0xFFFFD34E),
                      value: '${pet.coins}',
                    ),
                    const SizedBox(width: 6),
                    _buildCounterSegment(
                      icon: Icons.star,
                      iconColor: const Color(0xFFFFC940),
                      value: 'LV ${pet.level}',
                    ),
                    const SizedBox(width: 6),
                    _buildCounterSegment(
                      icon: Icons.favorite,
                      iconColor: const Color(0xFFFF5D86),
                      value: '${(pet.happiness / 20).floor()}',
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showSettings(context),
            onLongPress: () => _showEasterEgg('settings'),
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: _settingsButtonColors,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _strongBorderColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF314467).withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.settings,
                color: Colors.white,
                size: 30,
                shadows: [
                  Shadow(
                    color: Color(0x66557D96),
                    offset: Offset(0, 2),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatSelector() {
    final cats = _cats.isEmpty && _pet != null ? [_pet!] : _cats;

    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
        children: [
          _buildManageCatsChip(),
          _buildDownloadsChip(),
          for (int i = 0; i < cats.length; i++)
            _buildCatChip(cats[i], i, i == _selectedCatIndex),
          _buildAdoptCatChip(),
        ],
      ),
    );
  }

  Widget _buildDownloadsChip() {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: 'Download Kitty Adventure',
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _openDownloads,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? const Color(0xFF273A55)
                  : const Color(0xFFD7F0FF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF5AA9E6), width: 2),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.download_for_offline,
                  color: Color(0xFF2676B8),
                  size: 20,
                ),
                SizedBox(width: 6),
                Text(
                  'Downloads',
                  style: TextStyle(
                    color: Color(0xFF2676B8),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openDownloads() async {
    final reachable = await _canReachDownloadsPage();
    if (!reachable) {
      if (!mounted) return;
      _showDownloadsNetworkError();
      return;
    }

    final opened = await launchUrl(
      _downloadsUri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the downloads page.')),
      );
    }
  }

  Future<bool> _canReachDownloadsPage() async {
    if (kIsWeb) {
      return true;
    }

    try {
      final response =
          await http.get(_downloadsUri).timeout(const Duration(seconds: 6));
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (_) {
      return false;
    }
  }

  void _showDownloadsNetworkError() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: _dialogColor,
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Color(0xFFFF76B7)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Downloads Unavailable',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        content: const Text(
          'This downloads page is not reachable from this device right now.\n\n'
          'If you are on a different network, connect this device to the same WiFi or try again when internet access is available.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildCatChip(Pet cat, int index, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => _selectCat(index),
        onLongPress: _showCatManager,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? (_isDarkMode
                    ? const Color(0xFF3A315D)
                    : const Color(0xFFFFF087))
                : _panelColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? _strongBorderColor : _borderColor,
              width: selected ? 3 : 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(cat.moodEmoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Text(
                cat.name,
                style: TextStyle(
                  color: _primaryTextColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'LV ${cat.level}',
                style: TextStyle(
                  color: _secondaryTextColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManageCatsChip() {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: _showCatManager,
        onLongPress: () => _showEasterEgg('manager'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _dialogColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _strongBorderColor, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pets, color: _primaryTextColor, size: 18),
              const SizedBox(width: 5),
              Text(
                'Manage',
                style: TextStyle(
                  color: _primaryTextColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdoptCatChip() {
    return GestureDetector(
      onTap: _adoptCat,
      onLongPress: () => _showEasterEgg('manager'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFBDEBFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF6DB5E9), width: 2),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Color(0xFF3F7DB2), size: 18),
            SizedBox(width: 5),
            Text(
              'Adopt',
              style: TextStyle(
                color: Color(0xFF3F7DB2),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCatManager() {
    if (_cats.isEmpty && _pet != null) {
      _syncSelectedCat();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _dialogColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, modalSetState) {
          final cats = _cats.isEmpty && _pet != null ? [_pet!] : _cats;

          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.82,
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF087),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.pets,
                            color: Color(0xFF7A4B3B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cat Manager Center',
                                style: TextStyle(
                                  color: _primaryTextColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                '${cats.length} cats in your family',
                                style: TextStyle(
                                  color: _secondaryTextColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _adoptCat();
                              modalSetState(() {});
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Adopt Cat'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF70B8FF),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: cats.isEmpty
                                ? null
                                : () {
                                    Navigator.pop(sheetContext);
                                    _playWithPet();
                                  },
                            icon: const Icon(Icons.sports_baseball),
                            label: const Text('Play All'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF76B7),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: cats.length,
                      itemBuilder: (context, index) {
                        return _buildCatManagerCard(
                          cats[index],
                          index,
                          index == _selectedCatIndex,
                          modalSetState,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCatManagerCard(
    Pet cat,
    int index,
    bool selected,
    StateSetter modalSetState,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected
            ? (_isDarkMode
                ? const Color(0xFF3A315D)
                : const Color(0xFFFFF087).withValues(alpha: 0.58))
            : _solidPanelColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? _strongBorderColor : _borderColor,
          width: selected ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8A4B2A).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE5AE),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFB96A31), width: 2),
            ),
            child: Center(
              child: Text(cat.moodEmoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        cat.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _primaryTextColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (selected) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF76B7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  'LV ${cat.level} • ${cat.status} • ${cat.coins} coins',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _secondaryTextColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_personalityLabel(cat.personality)} • ${cat.favoriteFood} • ${cat.favoriteToy}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _primaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  cat.bio,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildTinyStatBar(
                        cat.happiness,
                        const Color(0xFFFF76B7),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: _buildTinyStatBar(
                        cat.energy,
                        const Color(0xFFFFC940),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: _buildTinyStatBar(
                        cat.health,
                        const Color(0xFFFF6E77),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 92,
                child: ElevatedButton(
                  onPressed: selected
                      ? null
                      : () {
                          _selectCat(index);
                          modalSetState(() {});
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF70B8FF),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Select'),
                ),
              ),
              SizedBox(
                width: 92,
                child: TextButton(
                  onPressed: () => _renameCat(index, modalSetState),
                  child: const Text('Rename'),
                ),
              ),
              SizedBox(
                width: 92,
                child: TextButton(
                  onPressed: () => _editCatProfile(index, modalSetState),
                  child: const Text('Profile'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTinyStatBar(int value, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        minHeight: 7,
        value: value.clamp(0, 100) / 100,
        backgroundColor: _trackColor,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }

  Future<void> _renameCat(int index, StateSetter modalSetState) async {
    if (index < 0 || index >= _cats.length) return;

    final controller = TextEditingController(text: _cats[index].name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _dialogColor,
        title: const Text('Rename Cat'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 18,
          decoration: const InputDecoration(labelText: 'Cat name'),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (newName == null || newName.isEmpty) return;

    setState(() {
      _cats[index].name = newName;
      if (index == _selectedCatIndex) {
        _pet = _cats[index];
      }
    });
    modalSetState(() {});
    _syncPetToProvider();
  }

  Future<void> _editCatProfile(int index, StateSetter _) async {
    if (index < 0 || index >= _cats.length) return;

    final cat = _cats[index];
    var selectedPersonality = cat.personality;
    var selectedFood = cat.favoriteFood.trim().isEmpty
        ? _favoriteFoods.first
        : cat.favoriteFood;
    var selectedToy =
        cat.favoriteToy.trim().isEmpty ? _favoriteToys.first : cat.favoriteToy;
    if (!_favoriteFoods.contains(selectedFood)) {
      selectedFood = _favoriteFoods.first;
    }
    if (!_favoriteToys.contains(selectedToy)) {
      selectedToy = _favoriteToys.first;
    }
    final bioController = TextEditingController(text: cat.bio);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, dialogSetState) => AlertDialog(
          backgroundColor: _dialogColor,
          title: Text('Edit ${cat.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<PetPersonality>(
                  initialValue: selectedPersonality,
                  decoration: const InputDecoration(
                    labelText: 'Personality',
                    prefixIcon: Icon(Icons.psychology),
                  ),
                  items: PetPersonality.values
                      .map(
                        (personality) => DropdownMenuItem(
                          value: personality,
                          child: Text(_personalityLabel(personality)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      dialogSetState(() => selectedPersonality = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _favoriteFoods.contains(selectedFood)
                      ? selectedFood
                      : _favoriteFoods.first,
                  decoration: const InputDecoration(
                    labelText: 'Favorite food',
                    prefixIcon: Icon(Icons.restaurant),
                  ),
                  items: _favoriteFoods
                      .map(
                        (food) => DropdownMenuItem(
                          value: food,
                          child: Text(food),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      dialogSetState(() => selectedFood = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _favoriteToys.contains(selectedToy)
                      ? selectedToy
                      : _favoriteToys.first,
                  decoration: const InputDecoration(
                    labelText: 'Favorite toy',
                    prefixIcon: Icon(Icons.toys),
                  ),
                  items: _favoriteToys
                      .map(
                        (toy) => DropdownMenuItem(
                          value: toy,
                          child: Text(toy),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      dialogSetState(() => selectedToy = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bioController,
                  maxLength: 90,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    prefixIcon: Icon(Icons.badge),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) {
      bioController.dispose();
      return;
    }

    if (!mounted) {
      bioController.dispose();
      return;
    }

    final updatedBio = bioController.text.trim().isEmpty
        ? _profilePick(_catBios, '${cat.id}:${cat.name}:edit')
        : bioController.text.trim();
    bioController.dispose();

    cat.personality = selectedPersonality;
    cat.favoriteFood = selectedFood;
    cat.favoriteToy = selectedToy;
    cat.bio = updatedBio;
    if (index == _selectedCatIndex) {
      _pet = cat;
    }
    _saveCatCollection();
  }

  Widget _buildCounterSegment({
    required IconData icon,
    required Color iconColor,
    required String value,
  }) {
    return Expanded(
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: (_isDarkMode ? Colors.white : const Color(0xFF1E3657))
              .withValues(alpha: _isDarkMode ? 0.08 : 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 31,
              height: 31,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor,
                border: Border.all(color: _strongBorderColor, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: Color(0x99445672),
                        offset: Offset(0, 3),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsPanel(Pet pet) {
    return Container(
      height: 80,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 5),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: _panelColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 2.5),
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                _buildStatChip(
                  icon: Icons.restaurant,
                  label: 'HUNGER',
                  value: pet.hunger,
                  color: const Color(0xFFFFA33C),
                ),
                _buildStatChip(
                  icon: Icons.favorite,
                  label: 'HAPPY',
                  value: pet.happiness,
                  color: const Color(0xFFFF5D86),
                ),
                _buildStatChip(
                  icon: Icons.bolt,
                  label: 'ENERGY',
                  value: pet.energy,
                  color: const Color(0xFFFFC940),
                ),
                _buildStatChip(
                  icon: Icons.auto_awesome,
                  label: 'CLEAN',
                  value: pet.cleanliness,
                  color: const Color(0xFF51CFE2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 24,
            child: Row(
              children: [
                _buildStatBadge(
                  icon: Icons.health_and_safety,
                  label: 'HEALTH',
                  value: pet.health,
                  color: const Color(0xFFFF6E77),
                ),
                _buildStatBadge(
                  icon: Icons.psychology,
                  label: 'IQ',
                  value: pet.intelligence,
                  color: const Color(0xFF8D8BFF),
                ),
                _buildStatBadge(
                  icon: Icons.groups,
                  label: 'SOC',
                  value: pet.social,
                  color: const Color(0xFF65CFA7),
                ),
                _buildStatBadge(
                  icon: Icons.volunteer_activism,
                  label: 'BOND',
                  value: pet.friendshipLevel,
                  color: const Color(0xFFFF80AB),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    final statValue = value.clamp(0, 100);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 3),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$label $statValue',
                      maxLines: 1,
                      style: TextStyle(
                        color: _primaryTextColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: statValue / 100,
                minHeight: 7,
                backgroundColor: _trackColor,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    final statValue = value.clamp(0, 100);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: color.withValues(alpha: 0.55), width: 1.6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 13),
              const SizedBox(width: 3),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$label $statValue',
                    maxLines: 1,
                    style: TextStyle(
                      color: _primaryTextColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodPanel(Pet pet) {
    return GestureDetector(
      onLongPress: () => _showEasterEgg('mood'),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 142),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: _isDarkMode
              ? const Color(0xFF24283B).withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _borderColor, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8A4B2A).withValues(alpha: 0.14),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(pet.moodEmoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 7),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _moodTitle(pet.currentMood),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _primaryTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    pet.status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _secondaryTextColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
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

  Widget _buildAnniversaryBanner() {
    return GestureDetector(
      onTap: () => _showEasterEgg('anniversary'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF087), Color(0xFFFF76B7)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFB96A31), width: 2.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8A4B2A).withValues(alpha: 0.16),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Text(
          '3rd Anniversary',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            shadows: [
              Shadow(
                color: Color(0x884A2A1E),
                offset: Offset(0, 1),
                blurRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _moodTitle(PetMood mood) {
    switch (mood) {
      case PetMood.happy:
        return 'Happy';
      case PetMood.excited:
        return 'Excited';
      case PetMood.sleepy:
        return 'Sleepy';
      case PetMood.hungry:
        return 'Hungry';
      case PetMood.sad:
        return 'Sad';
      case PetMood.sick:
        return 'Needs Care';
      case PetMood.playful:
        return 'Playful';
      case PetMood.loving:
        return 'Loving';
    }
  }

  String _petPortraitAsset(PetMood mood) {
    return _realPetPortraitAsset;
  }

  Color _petPortraitBorderColor(PetMood mood) {
    switch (mood) {
      case PetMood.happy:
        return const Color(0xFF7AA6D9);
      case PetMood.excited:
      case PetMood.playful:
        return const Color(0xFF9A8CFF);
      case PetMood.sleepy:
        return const Color(0xFF748FC4);
      case PetMood.hungry:
        return const Color(0xFF65CFA7);
      case PetMood.sad:
        return const Color(0xFF6E8BE8);
      case PetMood.sick:
        return const Color(0xFF78B9AE);
      case PetMood.loving:
        return const Color(0xFFFF76B7);
    }
  }

  Widget _buildBackground(Pet pet, bool liteMode) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final starRoom = pet.currentRoomDecor == 'star_wallpaper';

        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                _realGardenBackgroundAsset,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
              ),
            ),
            if (_isDarkMode || starRoom)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        if (_isDarkMode)
                          const Color(0xFF09101E).withValues(alpha: 0.44)
                        else
                          const Color(0xFF8EA7FF).withValues(alpha: 0.12),
                        if (_isDarkMode)
                          const Color(0xFF10213A).withValues(alpha: 0.32)
                        else
                          const Color(0xFFE9F8FF).withValues(alpha: 0.08),
                      ],
                    ),
                  ),
                ),
              ),
            if (!liteMode) _buildSceneMotionLayer(width, height, starRoom),
            if (starRoom && !liteMode) ...[
              const Positioned(
                top: 74,
                left: 48,
                child: Text('✨', style: TextStyle(fontSize: 24)),
              ),
              const Positioned(
                top: 128,
                right: 92,
                child: Text('⭐', style: TextStyle(fontSize: 20)),
              ),
              const Positioned(
                top: 172,
                left: 118,
                child: Text('✦', style: TextStyle(fontSize: 20)),
              ),
            ],
            if (!liteMode) ...[
              _buildBackgroundEggZone(
                id: 'house',
                left: width * 0.38,
                top: height * 0.17,
                width: width * 0.26,
                height: height * 0.33,
              ),
              _buildBackgroundEggZone(
                id: 'sun',
                left: width * 0.05,
                top: height * 0.04,
                width: 94,
                height: 84,
              ),
              _buildBackgroundEggZone(
                id: 'cloud',
                left: width * 0.26,
                top: height * 0.02,
                width: width * 0.34,
                height: height * 0.18,
              ),
              _buildBackgroundEggZone(
                id: 'tree',
                left: width * 0.02,
                top: 0,
                width: width * 0.18,
                height: height * 0.45,
                useDoubleTap: true,
              ),
              _buildBackgroundEggZone(
                id: 'flower',
                left: 0,
                top: height * 0.48,
                width: width * 0.24,
                height: height * 0.42,
              ),
              Positioned(
                bottom: 18,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 150,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF274C58).withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSceneMotionLayer(double width, double height, bool starRoom) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _motionController,
        builder: (context, child) {
          final time = _motionController.value * math.pi * 2;
          final isNight = _isDarkMode || starRoom;

          return Stack(
            children: [
              _buildFloatingPuff(
                left: width * 0.08,
                top: height * 0.18,
                size: 42,
                drift: Offset(
                  math.sin(time * 0.72) * 12,
                  math.cos(time * 0.54) * 6,
                ),
                color: isNight
                    ? const Color(0xFF99D8FF).withValues(alpha: 0.16)
                    : Colors.white.withValues(alpha: 0.18),
              ),
              _buildFloatingPuff(
                left: width * 0.78,
                top: height * 0.28,
                size: 34,
                drift: Offset(
                  math.cos(time * 0.62) * 10,
                  math.sin(time * 0.82) * 5,
                ),
                color: isNight
                    ? const Color(0xFFE1D3FF).withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.16),
              ),
              _buildFloatingSparkle(
                left: width * 0.16,
                top: height * 0.58,
                phase: 0.2,
                time: time,
                color: const Color(0xFFFFD45E),
              ),
              _buildFloatingSparkle(
                left: width * 0.74,
                top: height * 0.14,
                phase: 1.4,
                time: time,
                color:
                    isNight ? const Color(0xFFB9A7FF) : const Color(0xFF70B8FF),
              ),
              _buildFloatingSparkle(
                left: width * 0.88,
                top: height * 0.62,
                phase: 2.4,
                time: time,
                color: const Color(0xFFFF76B7),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFloatingPuff({
    required double left,
    required double top,
    required double size,
    required Offset drift,
    required Color color,
  }) {
    return Positioned(
      left: left + drift.dx,
      top: top + drift.dy,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: 18,
              spreadRadius: 10,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingSparkle({
    required double left,
    required double top,
    required double phase,
    required double time,
    required Color color,
  }) {
    final pulse = (math.sin(time * 1.4 + phase) + 1) / 2;

    return Positioned(
      left: left + math.sin(time * 0.7 + phase) * 10,
      top: top + math.cos(time * 0.9 + phase) * 7,
      child: Opacity(
        opacity: 0.34 + pulse * 0.46,
        child: Transform.rotate(
          angle: time * 0.2 + phase,
          child: Icon(
            Icons.auto_awesome,
            color: color,
            size: 14 + pulse * 8,
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundEggZone({
    required String id,
    required double left,
    required double top,
    required double width,
    required double height,
    bool useDoubleTap = false,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: useDoubleTap ? null : () => _showEasterEgg(id),
        onDoubleTap: useDoubleTap ? () => _showEasterEgg(id) : null,
        child: const SizedBox.expand(),
      ),
    );
  }

  List<Widget> _buildRoomDecor(String decorId, double width, double height) {
    switch (decorId) {
      case 'cozy_bed':
        return [
          Positioned(
            right: width * 0.04,
            bottom: height * 0.11,
            child: _buildCozyBedDecor(),
          ),
        ];
      case 'toy_basket':
        return [
          Positioned(
            left: width * 0.04,
            bottom: height * 0.10,
            child: _buildToyBasketDecor(),
          ),
        ];
      case 'party_balloons':
        return [
          Positioned(
            top: 76,
            left: 18,
            child: _buildBalloonCluster(
              const [Color(0xFFFF76B7), Color(0xFFFFD45E), Color(0xFF70B8FF)],
            ),
          ),
          Positioned(
            top: 82,
            right: 22,
            child: _buildBalloonCluster(
              const [Color(0xFF9A8CFF), Color(0xFF66D0C4)],
            ),
          ),
        ];
      case 'star_wallpaper':
        return [
          Positioned(top: 94, left: width * 0.08, child: _buildStarAccent(34)),
          Positioned(
              top: 126, right: width * 0.16, child: _buildStarAccent(28)),
          Positioned(
            right: width * 0.06,
            bottom: height * 0.16,
            child: _buildStarAccent(42),
          ),
        ];
      case 'flower_garden':
      default:
        return [
          Positioned(
            bottom: 70,
            left: 44,
            child: _buildFlowerPatch(),
          ),
        ];
    }
  }

  Widget _buildCozyBedDecor() {
    return SizedBox(
      width: 166,
      height: 92,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            left: 8,
            right: 8,
            height: 58,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9FC0FF), Color(0xFF6B8FFF)],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFF5D6EA2), width: 4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5D6EA2).withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 18,
            width: 82,
            height: 44,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7D6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF5D6EA2), width: 3),
              ),
            ),
          ),
          Positioned(
            right: 24,
            bottom: 20,
            child: Icon(
              Icons.bedtime,
              color: Colors.white.withValues(alpha: 0.9),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToyBasketDecor() {
    return SizedBox(
      width: 150,
      height: 102,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            top: 6,
            left: 18,
            child: _buildToyBall(const Color(0xFFFF76B7), 36),
          ),
          Positioned(
            top: 0,
            right: 22,
            child: _buildToyBall(const Color(0xFF70B8FF), 42),
          ),
          Positioned(
            top: 24,
            left: 58,
            child: _buildToyBall(const Color(0xFFFFD45E), 34),
          ),
          Positioned(
            bottom: 0,
            left: 12,
            right: 12,
            height: 62,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFB9DFFF),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                  top: Radius.circular(16),
                ),
                border: Border.all(color: const Color(0xFF6377C6), width: 4),
              ),
              child: Icon(
                Icons.toys,
                color: Colors.white.withValues(alpha: 0.86),
                size: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToyBall(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF6377C6), width: 3),
      ),
    );
  }

  Widget _buildBalloonCluster(List<Color> colors) {
    return SizedBox(
      width: 112,
      height: 142,
      child: Stack(
        children: [
          for (int i = 0; i < colors.length; i++)
            Positioned(
              left: 12.0 + (i * 26),
              top: i.isEven ? 0 : 18,
              child: Column(
                children: [
                  Container(
                    width: 42,
                    height: 54,
                    decoration: BoxDecoration(
                      color: colors[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF6377C6),
                        width: 3,
                      ),
                    ),
                    child: Align(
                      alignment: const Alignment(-0.36, -0.42),
                      child: Container(
                        width: 10,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.46),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  Container(
                      width: 2, height: 78, color: const Color(0xFF60728A)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStarAccent(double size) {
    return Icon(
      Icons.star_rounded,
      color: const Color(0xFFFFD45E),
      size: size,
      shadows: const [
        Shadow(
          color: Color(0x669F6834),
          offset: Offset(0, 2),
          blurRadius: 2,
        ),
      ],
    );
  }

  Widget _buildFlowerPatch() {
    return SizedBox(
      width: 156,
      height: 84,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: 140,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF65CFA7).withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),
          const Positioned(
            bottom: 24,
            left: 8,
            child:
                Icon(Icons.local_florist, color: Color(0xFFFF76B7), size: 42),
          ),
          const Positioned(
            bottom: 18,
            left: 56,
            child:
                Icon(Icons.local_florist, color: Color(0xFFFFD45E), size: 50),
          ),
          const Positioned(
            bottom: 20,
            right: 4,
            child:
                Icon(Icons.local_florist, color: Color(0xFF70B8FF), size: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildSun() {
    return GestureDetector(
      onTap: () => _showEasterEgg('sun'),
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF2B8),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF8AA7D6), width: 4),
        ),
        child: const Center(
          child: Text(
            '• ᴗ •',
            style: TextStyle(
              color: Color(0xFF60728A),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCloud(double width, double height) {
    return GestureDetector(
      onTap: () => _showEasterEgg('cloud'),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            Positioned(
              left: width * 0.08,
              bottom: 0,
              child: Container(
                width: width * 0.78,
                height: height * 0.54,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(height),
                  border: Border.all(color: const Color(0xFFB9D4E6), width: 3),
                ),
              ),
            ),
            Positioned(
              left: 0,
              bottom: height * 0.08,
              child: Container(
                width: width * 0.44,
                height: height * 0.54,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: width * 0.32,
              bottom: height * 0.18,
              child: Container(
                width: width * 0.42,
                height: height * 0.62,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHouse() {
    return GestureDetector(
      onTap: () => _showEasterEgg('house'),
      child: AspectRatio(
        aspectRatio: 1.08,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              left: 18,
              right: 18,
              bottom: 0,
              top: 44,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8F4FF), Color(0xFFC9D8FF)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF6377C6), width: 4),
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 0,
              right: 0,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF8FA7D8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF6377C6), width: 4),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                width: 46,
                height: 78,
                decoration: BoxDecoration(
                  color: const Color(0xFFB9D4FF),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: const Color(0xFF6377C6), width: 3),
                ),
              ),
            ),
            Positioned(
              bottom: 94,
              child: Container(
                width: 48,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1FCFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF6377C6), width: 3),
                ),
                child: const Icon(Icons.window, color: Color(0xFF6EA8C8)),
              ),
            ),
            Positioned(
              right: 28,
              bottom: 66,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1FCFF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF6377C6), width: 3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTree() {
    return GestureDetector(
      onDoubleTap: () => _showEasterEgg('tree'),
      child: SizedBox(
        width: 100,
        height: 128,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: 28,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFF7A6F8D),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Positioned(
              top: 0,
              child: Container(
                width: 98,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFF9DD8B5),
                  borderRadius: BorderRadius.circular(46),
                  border: Border.all(color: const Color(0xFF5AAE8E), width: 4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBush() {
    return GestureDetector(
      onTap: () => _showEasterEgg('flower'),
      child: Container(
        width: 118,
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFF8FCDB1),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFF5AAE8E), width: 3),
        ),
      ),
    );
  }

  Widget _buildFlower() {
    return GestureDetector(
      onTap: () => _showEasterEgg('flower'),
      child: const Text('🌼 🌸', style: TextStyle(fontSize: 34)),
    );
  }

  Widget _buildPetCharacter(Pet pet, bool liteMode) {
    final petWidth = (MediaQuery.sizeOf(context).width * 0.32)
        .clamp(180.0, 260.0)
        .toDouble();
    final portraitHeight = petWidth * 1.06;
    final portraitAsset = _petPortraitAsset(pet.currentMood);
    final portraitBorder = _petPortraitBorderColor(pet.currentMood);

    return AnimatedBuilder(
      animation: _motionController,
      child: SizedBox(
        width: petWidth,
        height: portraitHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (!liteMode)
              Positioned(
                left: petWidth * 0.16,
                right: petWidth * 0.16,
                bottom: 2,
                height: 28,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF23404C).withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: portraitBorder.withValues(alpha: 0.14),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              ),
            GestureDetector(
              onDoubleTap: () => _showEasterEgg('cat'),
              onLongPress: () => _showEasterEgg('cat'),
              child: Image.asset(
                portraitAsset,
                width: petWidth,
                height: portraitHeight,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            ),
            if (pet.currentAccessory.isNotEmpty)
              _buildOutfitBadge(pet.currentAccessory),
            if (!liteMode)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.86),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFFF5C3C8), width: 2),
                  ),
                  child:
                      Text(pet.moodEmoji, style: const TextStyle(fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
      builder: (context, child) {
        if (liteMode) return child!;

        final time = _motionController.value * math.pi * 2;
        final bob = math.sin(time) * 5;
        final sway = math.sin(time * 0.55) * 0.018;
        final breathe = 1 + math.sin(time + math.pi / 2) * 0.012;

        return Transform.translate(
          offset: Offset(0, bob),
          child: Transform.rotate(
            angle: sway,
            child: Transform.scale(
              scale: breathe,
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _buildOutfitBadge(String outfitId) {
    final emoji = _outfitEmojiById(outfitId);
    if (emoji.isEmpty) return const SizedBox.shrink();

    return Positioned(
      left: 8,
      top: 10,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFFFD6E8), width: 2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8A4B2A).withValues(alpha: 0.12),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  String _outfitEmojiById(String id) {
    for (final item in _outfitItems) {
      if (item.id == id) return item.emoji;
    }
    return '';
  }

  // Full overlays are kept for shop previews; the home screen uses compact badges.
  // ignore: unused_element
  Widget _buildOutfitOverlay(String outfitId, double petWidth) {
    switch (outfitId) {
      case 'party_hat':
        return Positioned(
          top: petWidth * -0.01,
          left: petWidth * 0.37,
          child: Transform.rotate(
            angle: -0.12,
            child: SizedBox(
              width: petWidth * 0.24,
              height: petWidth * 0.26,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  ClipPath(
                    clipper: _TriangleClipper(),
                    child: Container(
                      width: petWidth * 0.20,
                      height: petWidth * 0.22,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFF76B7), Color(0xFFFFD45E)],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: petWidth * 0.25,
                    height: petWidth * 0.045,
                    decoration: BoxDecoration(
                      color: const Color(0xFF70B8FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF8A4B2A),
                        width: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      case 'pink_bow':
        return Positioned(
          top: petWidth * 0.12,
          left: petWidth * 0.28,
          child: SizedBox(
            width: petWidth * 0.22,
            height: petWidth * 0.13,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 0,
                  child: _buildBowLoop(petWidth * 0.095),
                ),
                Positioned(
                  right: 0,
                  child: _buildBowLoop(petWidth * 0.095),
                ),
                Container(
                  width: petWidth * 0.065,
                  height: petWidth * 0.065,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF76B7),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFFB94878), width: 2),
                  ),
                ),
              ],
            ),
          ),
        );
      case 'cool_shades':
        return Positioned(
          top: petWidth * 0.34,
          left: petWidth * 0.285,
          child: SizedBox(
            width: petWidth * 0.44,
            height: petWidth * 0.115,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 5,
                  width: petWidth * 0.13,
                  color: const Color(0xFF3D2A2A),
                ),
                Positioned(left: 0, child: _buildShadeLens(petWidth * 0.17)),
                Positioned(right: 0, child: _buildShadeLens(petWidth * 0.17)),
              ],
            ),
          ),
        );
      case 'star_collar':
        return Positioned(
          top: petWidth * 0.59,
          left: petWidth * 0.25,
          child: Container(
            width: petWidth * 0.48,
            height: petWidth * 0.08,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF76B7), Color(0xFF9A8CFF)],
              ),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: const Color(0xFF8A4B2A), width: 3),
            ),
            child: const Center(
              child:
                  Icon(Icons.star_rounded, color: Color(0xFFFFD45E), size: 24),
            ),
          ),
        );
      case 'sleepy_mask':
        return Positioned(
          top: petWidth * 0.32,
          left: petWidth * 0.31,
          child: Container(
            width: petWidth * 0.38,
            height: petWidth * 0.10,
            decoration: BoxDecoration(
              color: const Color(0xFF8EA7FF).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: const Color(0xFF5D6EA2), width: 3),
            ),
            child: const Center(
              child: Icon(Icons.bedtime, color: Colors.white, size: 20),
            ),
          ),
        );
      case 'explorer_bandana':
        return Positioned(
          top: petWidth * 0.18,
          left: petWidth * 0.25,
          child: Transform.rotate(
            angle: -0.08,
            child: Container(
              width: petWidth * 0.48,
              height: petWidth * 0.085,
              decoration: BoxDecoration(
                color: const Color(0xFF66C58D),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: const Color(0xFF3E7F5C), width: 3),
              ),
              child: const Icon(Icons.explore, color: Colors.white, size: 20),
            ),
          ),
        );
      case 'royal_crown':
        return Positioned(
          top: petWidth * 0.02,
          left: petWidth * 0.36,
          child: Icon(
            Icons.workspace_premium,
            color: const Color(0xFFFFB84D),
            size: petWidth * 0.20,
            shadows: const [
              Shadow(
                color: Color(0xFF8A4B2A),
                offset: Offset(0, 2),
                blurRadius: 1,
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBowLoop(double size) {
    return Transform.rotate(
      angle: 0.78,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFFF80AB),
          borderRadius: BorderRadius.circular(size * 0.32),
          border: Border.all(color: const Color(0xFFB94878), width: 2),
        ),
      ),
    );
  }

  Widget _buildShadeLens(double size) {
    return Container(
      width: size,
      height: size * 0.64,
      decoration: BoxDecoration(
        color: const Color(0xFF1F2028).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(size * 0.24),
        border: Border.all(color: const Color(0xFF3D2A2A), width: 3),
      ),
      child: Align(
        alignment: const Alignment(-0.45, -0.45),
        child: Container(
          width: size * 0.20,
          height: size * 0.12,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      height: 124,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 7),
      child: Column(
        children: [
          SizedBox(
            height: 34,
            child: Row(
              children: [
                _buildMiniActionButton(
                  icon: Icons.bedtime,
                  label: 'SLEEP',
                  color: const Color(0xFF6F9EFF),
                  onTap: _sleepPet,
                ),
                _buildMiniActionButton(
                  icon: Icons.fitness_center,
                  label: 'TRAIN',
                  color: const Color(0xFF9BB3FF),
                  onTap: _trainPet,
                ),
                _buildMiniActionButton(
                  icon: Icons.favorite,
                  label: 'BOND',
                  color: const Color(0xFFFF82B2),
                  onTap: _bondWithPet,
                ),
                _buildMiniActionButton(
                  icon: Icons.local_hospital,
                  label: 'MEDICINE',
                  color: const Color(0xFF5CD8C8),
                  onTap: _giveMedicine,
                ),
                _buildMiniActionButton(
                  icon: Icons.vaccines,
                  label: 'VACCINE',
                  color: const Color(0xFFB08CFF),
                  onTap: _vaccinatePet,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              children: [
                _buildActionButton(
                  icon: Icons.set_meal,
                  label: 'FOOD',
                  color: const Color(0xFFF0839C),
                  shadowColor: const Color(0xFFA64768),
                  onTap: () => _feedPet(),
                ),
                _buildActionButton(
                  icon: Icons.sports_baseball,
                  label: 'TOY',
                  color: const Color(0xFF83D7F7),
                  shadowColor: const Color(0xFF4D8FB8),
                  onTap: () => _playWithPet(),
                ),
                _buildActionButton(
                  icon: Icons.bubble_chart,
                  label: 'CLEAN',
                  color: const Color(0xFF73E0D4),
                  shadowColor: const Color(0xFF3DA89F),
                  onTap: () => _cleanPet(),
                ),
                _buildActionButton(
                  icon: Icons.shopping_bag,
                  label: 'SHOP',
                  color: const Color(0xFFB88CFF),
                  shadowColor: const Color(0xFF7461C9),
                  onTap: () => _showMiniGames(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: const Color(0xFF334052).withValues(alpha: 0.24),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.28),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 15),
                const SizedBox(width: 3),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            color: Color(0x664A2A1E),
                            offset: Offset(0, 1),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color shadowColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withValues(alpha: 0.76), color],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: shadowColor.withValues(alpha: 0.75), width: 3),
              boxShadow: [
                BoxShadow(
                  color: shadowColor.withValues(alpha: 0.22),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.28),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5), width: 2),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        shadows: [
                          Shadow(
                            color: Color(0x994F4F5E),
                            offset: Offset(0, 2),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _buyOrEquipRoomDecor(_RoomDecorItem item) {
    final pet = _pet;
    if (pet == null) return;

    final owned = pet.roomDecorations.contains(item.id);
    if (!owned && pet.coins < item.price) {
      _showPetActionMessage('Need ${item.price} coins for ${item.name}');
      return;
    }

    setState(() {
      if (!owned) {
        pet.coins -= item.price;
        pet.addRoomDecoration(item.id);
      }
      pet.useRoomDecoration(item.id);
      _refreshMood(PetMood.happy);
    });
    _syncPetToProvider();
    _showPetActionMessage('${item.name} is in the room');
  }

  void _buyOrEquipOutfit(_OutfitItem item) {
    final pet = _pet;
    if (pet == null) return;

    if (item.id.isEmpty) {
      setState(() {
        pet.currentAccessory = '';
        _refreshMood(PetMood.happy);
      });
      _syncPetToProvider();
      _showPetActionMessage('Outfit removed');
      return;
    }

    final owned = pet.accessories.contains(item.id);
    if (!owned && pet.coins < item.price) {
      _showPetActionMessage('Need ${item.price} coins for ${item.name}');
      return;
    }

    setState(() {
      if (!owned) {
        pet.coins -= item.price;
        pet.addAccessory(item.id);
      }
      pet.wearAccessory(item.id);
      _refreshMood(PetMood.excited);
    });
    _syncPetToProvider();
    _showPetActionMessage('${item.name} equipped');
  }

  void _activateOutfitSet(_OutfitSet set) {
    final pet = _pet;
    if (pet == null) return;

    final missing = set.requiredAccessories
        .where((id) => !pet.accessories.contains(id))
        .map(_outfitNameById)
        .join(', ');
    if (missing.isNotEmpty) {
      _showPetActionMessage('Need: $missing');
      return;
    }

    setState(() {
      pet.currentAccessory = set.featuredAccessory;
      pet.happiness = (pet.happiness + set.happyBonus).clamp(0, 100);
      pet.energy = (pet.energy + set.energyBonus).clamp(0, 100);
      pet.health = (pet.health + set.healthBonus).clamp(0, 100);
      pet.social = (pet.social + set.socialBonus).clamp(0, 100);
      pet.intelligence =
          (pet.intelligence + set.intelligenceBonus).clamp(0, 100);
      pet.friendshipLevel = (pet.friendshipLevel + set.bondBonus).clamp(0, 100);
      pet.coins += set.coinBonus;
      pet.gems += set.gemBonus;
      _refreshMood(PetMood.excited);
    });
    _syncPetToProvider();
    _showPetActionMessage('${set.name} bonus activated');
  }

  String _outfitNameById(String id) {
    for (final item in _outfitItems) {
      if (item.id == id) return item.name;
    }
    return id;
  }

  void _startCatJob(_CatJob job) {
    final pet = _pet;
    if (pet == null) return;
    if (pet.activeJobId.isNotEmpty) {
      _showPetActionMessage('${pet.name} is already working');
      return;
    }

    setState(() {
      pet.activeJobId = job.id;
      pet.activeJobStartedAt = DateTime.now();
      pet.currentMood = PetMood.excited;
    });
    _syncPetToProvider();
    _showPetActionMessage('${pet.name} started ${job.name}');
  }

  bool _isJobReady(Pet pet, _CatJob job) {
    final started = pet.activeJobStartedAt;
    if (started == null) return false;
    return DateTime.now().difference(started) >= job.duration;
  }

  String _jobTimeLeft(Pet pet, _CatJob job) {
    final started = pet.activeJobStartedAt;
    if (started == null) return 'Ready soon';
    final remaining = job.duration - DateTime.now().difference(started);
    if (remaining.isNegative) return 'Ready';
    final seconds = remaining.inSeconds.clamp(0, 999);
    return '${seconds}s left';
  }

  void _finishCatJob(_CatJob job) {
    final pet = _pet;
    if (pet == null) return;
    if (!_isJobReady(pet, job)) {
      _showPetActionMessage('${job.name}: ${_jobTimeLeft(pet, job)}');
      return;
    }

    setState(() {
      pet.coins += job.coinReward;
      pet.gems += job.gemReward;
      pet.hunger = (pet.hunger - job.hungerReduction).clamp(0, 100);
      pet.energy = (pet.energy + job.energyReward).clamp(0, 100);
      pet.health = (pet.health + job.healthReward).clamp(0, 100);
      pet.happiness = (pet.happiness + job.happyReward).clamp(0, 100);
      pet.addXp(job.xpReward);
      pet.activeJobId = '';
      pet.activeJobStartedAt = null;
      _refreshMood(PetMood.happy);
    });
    _syncPetToProvider();
    _showPetActionMessage('${job.name} complete');
  }

  void _redeemSecretCode(String rawCode) {
    final pet = _pet;
    if (pet == null) return;

    final normalized = rawCode.trim().toUpperCase();
    if (normalized.isEmpty) {
      _showPetActionMessage('Enter a code');
      return;
    }

    final code = _secretCodes.cast<_SecretCode?>().firstWhere(
          (item) => item?.code == normalized,
          orElse: () => null,
        );
    if (code == null) {
      _showPetActionMessage('Code not found');
      return;
    }
    if (_redeemedSecretCodes.contains(code.code)) {
      _showPetActionMessage('${code.code} already redeemed');
      return;
    }

    setState(() {
      _redeemedSecretCodes.add(code.code);
      pet.coins += code.coins;
      pet.gems += code.gems;
      pet.energy = (pet.energy + code.energy).clamp(0, 100);
      pet.happiness = (pet.happiness + code.happiness).clamp(0, 100);
      if (code.unlockRoom.isNotEmpty) {
        pet.addRoomDecoration(code.unlockRoom);
        pet.currentRoomDecor = code.unlockRoom;
      }
      _refreshMood(PetMood.excited);
    });
    _saveSecretCodes();
    _syncPetToProvider();
    _showPetActionMessage('${code.title} redeemed');
  }

  Future<void> _openMiniGame(_MiniGameEntry game) async {
    final navigator = Navigator.of(context);
    final provider = context.read<GameProvider>();
    final before =
        provider.pet == null ? null : _PetRewardSnapshot.fromPet(provider.pet!);

    navigator.pop();
    await navigator.push(MaterialPageRoute(builder: (_) => game.screen));

    if (!mounted) return;

    final updatedPet = provider.pet;
    if (updatedPet == null) return;

    setState(() {
      _pet = updatedPet;
      _refreshMood(PetMood.playful);
    });
    await _syncPetToProvider();
    _completeQuestStep('mini_game');

    var after = _PetRewardSnapshot.fromPet(updatedPet);
    var coins = before == null ? 0 : after.coins - before.coins;
    var gems = before == null ? 0 : after.gems - before.gems;
    var xp = before == null ? 0 : before.xpGainedTo(after);
    var levelGain = before == null ? 0 : after.level - before.level;

    if (coins <= 0 && gems <= 0 && xp <= 0 && levelGain <= 0) {
      provider.awardGameRewards(10, 0, 5);
      final rewardedPet = provider.pet;
      if (rewardedPet != null) {
        setState(() {
          _pet = rewardedPet;
        });
        await _syncPetToProvider();
        after = _PetRewardSnapshot.fromPet(rewardedPet);
        coins = before == null ? 5 : after.coins - before.coins;
        gems = before == null ? 0 : after.gems - before.gems;
        xp = before == null ? 10 : before.xpGainedTo(after);
        levelGain = before == null ? 0 : after.level - before.level;
      }
    }

    if (coins > 0 || gems > 0 || xp > 0 || levelGain > 0) {
      _showMiniGameRewardDialog(
        title: game.title,
        coins: coins,
        gems: gems,
        xp: xp,
        levelGain: levelGain,
      );
    }
  }

  void _showMiniGameRewardDialog({
    required String title,
    required int coins,
    required int gems,
    required int xp,
    required int levelGain,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF7D6),
        title: Text('$title Rewards', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRewardRow(Icons.attach_money, 'Coins', coins),
            _buildRewardRow(Icons.diamond, 'Gems', gems),
            _buildRewardRow(Icons.auto_awesome, 'XP', xp),
            if (levelGain > 0) _buildRewardRow(Icons.star, 'Levels', levelGain),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nice'),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardRow(IconData icon, String label, int amount) {
    if (amount <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFB96A31)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            '+$amount',
            style: const TextStyle(
              color: Color(0xFF7A4B3B),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    final rootContext = context;

    showDialog(
      context: rootContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, settingsSetState) {
          final gameProvider = dialogContext.watch<GameProvider>();
          final soundEnabled = gameProvider.soundEnabled;
          final darkModeEnabled = gameProvider.darkModeEnabled;

          return AlertDialog(
            backgroundColor: _dialogColor,
            title: const Text('Settings', textAlign: TextAlign.center),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 420,
                maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.68,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      value: darkModeEnabled,
                      onChanged: (_) {
                        dialogContext.read<GameProvider>().toggleDarkMode();
                        settingsSetState(() {});
                      },
                      dense: true,
                      secondary: Icon(
                        darkModeEnabled
                            ? Icons.dark_mode
                            : Icons.light_mode_outlined,
                        color: const Color(0xFFFF76B7),
                      ),
                      title: Text(darkModeEnabled ? 'Dark Mode' : 'Light Mode'),
                      subtitle: const Text('Switch the whole game theme'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.music_note,
                          color: Color(0xFF667EEA)),
                      title: const Text('Sound'),
                      trailing: Switch(
                        value: soundEnabled,
                        onChanged: (_) {
                          rootContext.read<GameProvider>().toggleSound();
                          settingsSetState(() {});
                        },
                      ),
                    ),
                    ListTile(
                      leading:
                          const Icon(Icons.vibration, color: Color(0xFF667EEA)),
                      title: const Text('Vibration'),
                      trailing: Switch(
                        value: _vibrationEnabled,
                        onChanged: (value) {
                          setState(() => _vibrationEnabled = value);
                          settingsSetState(() {});
                        },
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.notifications,
                        color: Color(0xFF667EEA),
                      ),
                      title: const Text('Notifications'),
                      subtitle: Text(_notificationsEnabled ? 'On' : 'Off'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        Navigator.push(
                          rootContext,
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        );
                      },
                    ),
                    SwitchListTile(
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                        settingsSetState(() {});
                      },
                      dense: true,
                      secondary: const Icon(
                        Icons.notifications_active,
                        color: Color(0xFF667EEA),
                      ),
                      title: const Text('Notification Alerts'),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.system_update_alt,
                        color: Color(0xFFFF76B7),
                      ),
                      title: Text(
                        'Check for Updates',
                      ),
                      subtitle: Text(
                        'Kitty Adventure v${UpdateService.currentVersion}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        Navigator.pop(dialogContext);
                        await UpdateService.checkForUpdates(
                          rootContext,
                          showNoUpdateSnack: true,
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.article,
                        color: Color(0xFF667EEA),
                      ),
                      title: const Text('Game Docs'),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        Navigator.push(
                          rootContext,
                          MaterialPageRoute(builder: (_) => const DocsScreen()),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading:
                          const Icon(Icons.restart_alt, color: Colors.orange),
                      title: const Text('Reset Pet'),
                      onTap: () {
                        Navigator.pop(dialogContext);
                        setState(() {
                          _pet = null;
                        });
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (mounted) _createPet();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showMiniGames(BuildContext context) {
    final games = [
      _MiniGameEntry(
        icon: '🧱',
        title: 'Block Builder 2D',
        color: Colors.green,
        screen: const BlockBuilderGameScreen(),
      ),
      _MiniGameEntry(
        icon: '🧩',
        title: 'Puzzle Game',
        color: Colors.orange,
        screen: const PuzzleGameScreen(),
      ),
      _MiniGameEntry(
        icon: '🔢',
        title: 'Puzzle Master',
        color: Colors.deepPurple,
        screen: const PuzzleMasterScreen(),
      ),
      _MiniGameEntry(
        icon: '📝',
        title: 'Quiz Game',
        color: Colors.green,
        screen: const QuizGameScreen(),
      ),
      _MiniGameEntry(
        icon: '🏎️',
        title: 'Racing Game',
        color: Colors.red,
        screen: const RacingGameScreen(),
      ),
      _MiniGameEntry(
        icon: '🎵',
        title: 'Rhythm Game',
        color: Colors.purple,
        screen: const RhythmGameScreen(),
      ),
      _MiniGameEntry(
        icon: '🃏',
        title: 'Memory Match',
        color: Colors.cyan,
        screen: const MemoryMatchScreen(),
      ),
      _MiniGameEntry(
        icon: '🔤',
        title: 'Word Puzzle',
        color: Colors.teal,
        screen: const WordPuzzleScreen(),
      ),
      _MiniGameEntry(
        icon: '🚀',
        title: 'Space Shooter',
        color: Colors.blue,
        screen: const SpaceShooterScreen(),
      ),
      _MiniGameEntry(
        icon: '🏃',
        title: 'Obstacle Course',
        color: Colors.brown,
        screen: const ObstacleCourseScreen(),
      ),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, modalSetState) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.82,
            ),
            child: DefaultTabController(
              length: 7,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                    child: Text(
                      'Kitty Hub',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TabBar(
                    isScrollable: true,
                    labelColor: const Color(0xFF7A4B3B),
                    unselectedLabelColor: Colors.grey.shade600,
                    indicatorColor: const Color(0xFFFF76B7),
                    tabs: const [
                      Tab(icon: Icon(Icons.task_alt), text: 'Quests'),
                      Tab(icon: Icon(Icons.work), text: 'Jobs'),
                      Tab(icon: Icon(Icons.chair), text: 'Room'),
                      Tab(icon: Icon(Icons.checkroom), text: 'Outfits'),
                      Tab(icon: Icon(Icons.emoji_events), text: 'Eggs'),
                      Tab(icon: Icon(Icons.key), text: 'Codes'),
                      Tab(icon: Icon(Icons.sports_esports), text: 'Games'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildQuestTab(modalSetState),
                        _buildJobsTab(modalSetState),
                        _buildDecorTab(modalSetState),
                        _buildOutfitTab(modalSetState),
                        _buildEasterEggJournalTab(),
                        _buildSecretCodesTab(modalSetState),
                        _buildGamesTab(games),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestTab(StateSetter modalSetState) {
    if (!_dailyQuestsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Daily quests reset each day. Finish them for coins, gems, and XP.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF7A4B3B), fontSize: 13),
        ),
        const SizedBox(height: 12),
        ..._dailyQuests.map(
          (quest) {
            final progress = (_questProgress[quest.id] ?? 0).clamp(
              0,
              quest.target,
            );
            final claimed = _claimedQuestIds.contains(quest.id);
            final ready = _isQuestReady(quest);

            return _buildHubCard(
              icon: quest.icon,
              color: quest.color,
              title: quest.title,
              subtitle:
                  '${quest.detail} • $progress/${quest.target} • +${quest.rewardCoins} coins +${quest.rewardGems} gems',
              trailing: ElevatedButton(
                onPressed: ready
                    ? () {
                        _claimDailyQuest(quest);
                        modalSetState(() {});
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ready ? quest.color : Colors.grey.shade300,
                  foregroundColor: Colors.white,
                ),
                child: Text(claimed ? 'Done' : 'Claim'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildJobsTab(StateSetter modalSetState) {
    final pet = _pet;
    if (pet == null) return const SizedBox.shrink();

    final activeJob = _jobById(pet.activeJobId);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          activeJob == null
              ? '${pet.name} can do one tiny job at a time.'
              : '${pet.name} is doing ${activeJob.name}: ${_jobTimeLeft(pet, activeJob)}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF7A4B3B), fontSize: 13),
        ),
        const SizedBox(height: 12),
        ..._catJobs.map(
          (job) {
            final isActive = pet.activeJobId == job.id;
            final busyElsewhere = pet.activeJobId.isNotEmpty && !isActive;
            final ready = isActive && _isJobReady(pet, job);
            final buttonText = isActive
                ? ready
                    ? 'Finish'
                    : _jobTimeLeft(pet, job)
                : 'Start';

            return _buildHubCard(
              icon: job.icon,
              color: job.color,
              title: job.name,
              subtitle:
                  '${job.detail} • ${job.duration.inSeconds}s • ${job.rewardSummary}',
              trailing: ElevatedButton(
                onPressed: busyElsewhere
                    ? null
                    : () {
                        if (isActive) {
                          _finishCatJob(job);
                        } else {
                          _startCatJob(job);
                        }
                        modalSetState(() {});
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: job.color,
                  foregroundColor: Colors.white,
                ),
                child: Text(buttonText),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDecorTab(StateSetter modalSetState) {
    final pet = _pet;
    if (pet == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Buy room looks, then equip one for the yard.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF7A4B3B), fontSize: 13),
        ),
        const SizedBox(height: 12),
        ..._roomDecorItems.map(
          (item) {
            final owned = pet.roomDecorations.contains(item.id);
            final equipped = pet.currentRoomDecor == item.id;
            return _buildHubCard(
              icon: item.icon,
              color: item.color,
              title: item.name,
              subtitle: equipped
                  ? 'Equipped • ${_roomEffectDescription(item.id)}'
                  : owned
                      ? 'Owned • ${_roomEffectDescription(item.id)}'
                      : '${item.price} coins • ${_roomEffectDescription(item.id)}',
              trailing: ElevatedButton(
                onPressed: equipped
                    ? null
                    : () {
                        _buyOrEquipRoomDecor(item);
                        modalSetState(() {});
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: item.color,
                  foregroundColor: Colors.white,
                ),
                child: Text(owned ? 'Equip' : 'Buy'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOutfitTab(StateSetter modalSetState) {
    final pet = _pet;
    if (pet == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Buy outfit pieces, then activate full sets for bonuses.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF7A4B3B), fontSize: 13),
        ),
        const SizedBox(height: 12),
        ..._outfitSets.map(
          (set) {
            final ownedAll =
                set.requiredAccessories.every(pet.accessories.contains);
            return _buildHubCard(
              icon: set.icon,
              color: set.color,
              title: set.name,
              subtitle: ownedAll
                  ? 'Ready • ${set.detail}'
                  : 'Need ${set.requiredAccessories.map(_outfitNameById).join(', ')} • ${set.detail}',
              trailing: ElevatedButton(
                onPressed: ownedAll
                    ? () {
                        _activateOutfitSet(set);
                        modalSetState(() {});
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: set.color,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Bonus'),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        ..._outfitItems.map(
          (item) {
            final owned = item.id.isEmpty || pet.accessories.contains(item.id);
            final equipped = pet.currentAccessory == item.id;
            return _buildHubCard(
              leadingText: item.emoji,
              color: item.color,
              title: item.name,
              subtitle: equipped
                  ? 'Equipped'
                  : owned
                      ? 'Owned'
                      : '${item.price} coins',
              trailing: ElevatedButton(
                onPressed: equipped
                    ? null
                    : () {
                        _buyOrEquipOutfit(item);
                        modalSetState(() {});
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: item.color,
                  foregroundColor: Colors.white,
                ),
                child: Text(owned ? 'Wear' : 'Buy'),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEasterEggJournalTab() {
    final found = _foundEasterEggIds.length;
    final total = _easterEggs.length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Found $found/$total secrets. The journal fills when you discover them in the game.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF7A4B3B), fontSize: 13),
        ),
        const SizedBox(height: 12),
        ..._easterEggs.map(
          (egg) {
            final unlocked = _foundEasterEggIds.contains(egg.id);
            return _buildHubCard(
              icon: unlocked ? Icons.emoji_events : Icons.lock,
              color: unlocked ? const Color(0xFFFFB84D) : Colors.grey,
              title: unlocked ? egg.title : 'Secret ???',
              subtitle: unlocked ? egg.trigger : 'Hint hidden until found',
              trailing: Text(
                unlocked ? 'FOUND' : 'LOCKED',
                style: TextStyle(
                  color: unlocked ? const Color(0xFF7A4B3B) : Colors.grey,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSecretCodesTab(StateSetter modalSetState) {
    final controller = TextEditingController();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Enter secret codes for bonus rewards. Each code works once.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF7A4B3B), fontSize: 13),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            labelText: 'Secret code',
            hintText: 'MEOW2026',
            prefixIcon: const Icon(Icons.key),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onSubmitted: (value) {
            _redeemSecretCode(value);
            modalSetState(() {});
            controller.clear();
          },
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () {
            _redeemSecretCode(controller.text);
            modalSetState(() {});
            controller.clear();
          },
          icon: const Icon(Icons.lock_open),
          label: const Text('Redeem'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF76B7),
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        ..._secretCodes.map(
          (code) => _buildHubCard(
            icon: _redeemedSecretCodes.contains(code.code)
                ? Icons.check_circle
                : Icons.key,
            color: _redeemedSecretCodes.contains(code.code)
                ? const Color(0xFF66C58D)
                : const Color(0xFF8EA7FF),
            title: code.code,
            subtitle: _redeemedSecretCodes.contains(code.code)
                ? 'Redeemed • ${code.title}'
                : code.detail,
            trailing: Text(
              _redeemedSecretCodes.contains(code.code) ? 'DONE' : 'ONCE',
              style: const TextStyle(
                color: Color(0xFF7A4B3B),
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGamesTab(List<_MiniGameEntry> games) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Rewards pop up when you return from a game.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF7A4B3B), fontSize: 13),
        ),
        const SizedBox(height: 12),
        ...games.map(
          (game) => _buildGameTile(
            icon: game.icon,
            title: game.title,
            color: game.color,
            onTap: () => _openMiniGame(game),
          ),
        ),
      ],
    );
  }

  Widget _buildHubCard({
    IconData? icon,
    String? leadingText,
    required Color color,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.24), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: leadingText == null
                  ? Icon(icon, color: color)
                  : Text(leadingText, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF7A4B3B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }

  Widget _buildGameTile({
    required String icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: color.withValues(alpha: 0.1),
        leading: Text(icon, style: const TextStyle(fontSize: 28)),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: color, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class _MiniGameEntry {
  final String icon;
  final String title;
  final Color color;
  final Widget screen;

  const _MiniGameEntry({
    required this.icon,
    required this.title,
    required this.color,
    required this.screen,
  });
}

class _DailyQuest {
  final String id;
  final String actionKey;
  final String title;
  final String detail;
  final int target;
  final int rewardCoins;
  final int rewardGems;
  final int rewardXp;
  final IconData icon;
  final Color color;

  const _DailyQuest({
    required this.id,
    required this.actionKey,
    required this.title,
    required this.detail,
    required this.target,
    required this.rewardCoins,
    required this.rewardGems,
    required this.rewardXp,
    required this.icon,
    required this.color,
  });
}

class _RoomDecorItem {
  final String id;
  final String name;
  final int price;
  final IconData icon;
  final Color color;

  const _RoomDecorItem({
    required this.id,
    required this.name,
    required this.price,
    required this.icon,
    required this.color,
  });
}

class _OutfitItem {
  final String id;
  final String name;
  final String emoji;
  final int price;
  final Color color;

  const _OutfitItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.price,
    required this.color,
  });
}

class _OutfitSet {
  final String id;
  final String name;
  final String detail;
  final List<String> requiredAccessories;
  final String featuredAccessory;
  final Color color;
  final IconData icon;
  final int happyBonus;
  final int energyBonus;
  final int healthBonus;
  final int socialBonus;
  final int intelligenceBonus;
  final int bondBonus;
  final int coinBonus;
  final int gemBonus;

  const _OutfitSet({
    required this.id,
    required this.name,
    required this.detail,
    required this.requiredAccessories,
    required this.featuredAccessory,
    required this.color,
    required this.icon,
    this.happyBonus = 0,
    this.energyBonus = 0,
    this.healthBonus = 0,
    this.socialBonus = 0,
    this.intelligenceBonus = 0,
    this.bondBonus = 0,
    this.coinBonus = 0,
    this.gemBonus = 0,
  });
}

class _CatJob {
  final String id;
  final String name;
  final String detail;
  final IconData icon;
  final Color color;
  final Duration duration;
  final int coinReward;
  final int gemReward;
  final int hungerReduction;
  final int energyReward;
  final int healthReward;
  final int happyReward;
  final int xpReward;

  const _CatJob({
    required this.id,
    required this.name,
    required this.detail,
    required this.icon,
    required this.color,
    required this.duration,
    this.coinReward = 0,
    this.gemReward = 0,
    this.hungerReduction = 0,
    this.energyReward = 0,
    this.healthReward = 0,
    this.happyReward = 0,
    this.xpReward = 0,
  });

  String get rewardSummary {
    final rewards = <String>[];
    if (coinReward > 0) rewards.add('+$coinReward coins');
    if (gemReward > 0) rewards.add('+$gemReward gems');
    if (hungerReduction > 0) rewards.add('-$hungerReduction hunger');
    if (energyReward > 0) rewards.add('+$energyReward energy');
    if (healthReward > 0) rewards.add('+$healthReward health');
    if (happyReward > 0) rewards.add('+$happyReward happy');
    if (xpReward > 0) rewards.add('+$xpReward XP');
    return rewards.join(', ');
  }
}

class _SecretCode {
  final String code;
  final String title;
  final String detail;
  final int coins;
  final int gems;
  final int energy;
  final int happiness;
  final String unlockRoom;

  const _SecretCode({
    required this.code,
    required this.title,
    required this.detail,
    this.coins = 0,
    this.gems = 0,
    this.energy = 0,
    this.happiness = 0,
    this.unlockRoom = '',
  });
}

class _AchievementBadge {
  final String id;
  final String title;
  final String detail;
  final IconData icon;
  final Color color;

  const _AchievementBadge({
    required this.id,
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
  });
}

class _ReleaseChecklistItem {
  final String title;
  final String detail;
  final IconData icon;
  final Color color;

  const _ReleaseChecklistItem({
    required this.title,
    required this.detail,
    required this.icon,
    required this.color,
  });
}

class _DailyStreakReward {
  final int day;
  final int coins;
  final int gems;
  final int xp;

  const _DailyStreakReward({
    required this.day,
    required this.coins,
    required this.gems,
    required this.xp,
  });
}

class _EasterEggSpot {
  final String id;
  final String title;
  final String trigger;
  final String actionLabel;
  final List<String> messages;

  const _EasterEggSpot({
    required this.id,
    required this.title,
    required this.trigger,
    required this.actionLabel,
    required this.messages,
  });
}

class _FriendshipScene {
  final String title;
  final String message;
  final IconData icon;
  final Color color;

  const _FriendshipScene({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });
}

class _PetRewardSnapshot {
  final int coins;
  final int gems;
  final int xp;
  final int level;
  final int xpToNextLevel;

  const _PetRewardSnapshot({
    required this.coins,
    required this.gems,
    required this.xp,
    required this.level,
    required this.xpToNextLevel,
  });

  factory _PetRewardSnapshot.fromPet(Pet pet) {
    return _PetRewardSnapshot(
      coins: pet.coins,
      gems: pet.gems,
      xp: pet.xp,
      level: pet.level,
      xpToNextLevel: pet.xpToNextLevel,
    );
  }

  int xpGainedTo(_PetRewardSnapshot after) {
    if (after.level == level) {
      return (after.xp - xp).clamp(0, 999999).toInt();
    }

    int gained = xpToNextLevel - xp;
    int simulatedLevel = level + 1;
    int nextLevelTarget = (xpToNextLevel * 1.5).round();

    while (simulatedLevel < after.level) {
      gained += nextLevelTarget;
      simulatedLevel++;
      nextLevelTarget = (nextLevelTarget * 1.5).round();
    }

    gained += after.xp;
    return gained.clamp(0, 999999).toInt();
  }
}

class _PlayCutsceneDialog extends StatefulWidget {
  final List<Pet> cats;

  const _PlayCutsceneDialog({required this.cats});

  @override
  State<_PlayCutsceneDialog> createState() => _PlayCutsceneDialogState();
}

class _PlayCutsceneDialogState extends State<_PlayCutsceneDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catCount = widget.cats.length;
    final catSize = _catSizeForCount(catCount);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(18),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 430),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFCFF3FF), Color(0xFFFFF0B6)],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Color(0xFFB96A31), width: 4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              catCount > 1 ? 'Play Time!' : '${widget.cats.first.name} Plays!',
              style: const TextStyle(
                color: Color(0xFF7A4B3B),
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: catCount > 8 ? 300 : 250,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final height = constraints.maxHeight;

                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final pulse = math.sin(_controller.value * math.pi * 2);

                      return Stack(
                        children: [
                          Positioned(
                            left: width * 0.38,
                            top: height * 0.44 + pulse * 8,
                            child: Transform.rotate(
                              angle: _controller.value * math.pi * 2,
                              child: _buildToyBall(),
                            ),
                          ),
                          for (int i = 0; i < widget.cats.length; i++)
                            Positioned(
                              left:
                                  _catPosition(i, catCount, width, height).dx -
                                      catSize / 2,
                              top: _catPosition(i, catCount, width, height).dy -
                                  catSize / 2 +
                                  math.sin((_controller.value * math.pi * 2) +
                                          i) *
                                      8,
                              child: _buildPlayingCat(
                                widget.cats[i],
                                flip: i.isOdd,
                                size: catSize,
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            Text(
              catCount > 1
                  ? '${widget.cats.map((cat) => cat.name).join(', ')} are playing together.'
                  : 'A toy session boosted happiness.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF7A4B3B),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF76B7),
                foregroundColor: Colors.white,
              ),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToyBall() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(-0.35, -0.35),
          colors: [Colors.white, Color(0xFF70B8FF), Color(0xFF3F7DB2)],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF3F7DB2), width: 4),
      ),
      child: const Icon(Icons.sports_baseball, color: Colors.white, size: 30),
    );
  }

  double _catSizeForCount(int count) {
    if (count <= 5) return 92;
    if (count <= 8) return 74;
    if (count <= 12) return 62;
    return 52;
  }

  Offset _catPosition(int index, int count, double width, double height) {
    if (count == 1) return Offset(width * 0.50, height * 0.42);
    if (count == 2) {
      return Offset(width * (index == 0 ? 0.28 : 0.72), height * 0.46);
    }

    final angle = (-math.pi / 2) + (math.pi * 2 * index / count);
    final radiusX = width * 0.34;
    final radiusY = height * (count <= 8 ? 0.31 : 0.35);

    return Offset(
      width * 0.50 + math.cos(angle) * radiusX,
      height * 0.48 + math.sin(angle) * radiusY,
    );
  }

  Widget _buildPlayingCat(Pet cat, {required bool flip, required double size}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(flip ? -1 : 1, 1, 1),
          child: Image.asset(
            _petPortraitAssetForMood(cat.currentMood),
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD6A262), width: 2),
          ),
          child: Text(
            cat.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF7A4B3B),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
