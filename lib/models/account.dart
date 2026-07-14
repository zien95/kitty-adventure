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
  });

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
    );
  }
}
