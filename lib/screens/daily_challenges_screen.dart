import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/account_provider.dart';

class DailyChallengesScreen extends StatefulWidget {
  const DailyChallengesScreen({super.key});

  @override
  State<DailyChallengesScreen> createState() => _DailyChallengesScreenState();
}

class _DailyChallengesScreenState extends State<DailyChallengesScreen> {
  List<DailyChallenge> _challenges = [];
  int _completedToday = 0;
  int _totalRewardCoins = 0;
  int _totalRewardGems = 0;

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  void _loadChallenges() {
    _challenges = [
      DailyChallenge(
        id: 'feed_pet',
        title: 'Feed Your Pet',
        description: 'Feed your pet 3 times today',
        icon: Icons.restaurant,
        color: Colors.orange,
        target: 3,
        current: 0,
        rewardCoins: 50,
        rewardGems: 5,
        category: ChallengeCategory.daily,
      ),
      DailyChallenge(
        id: 'play_games',
        title: 'Game Master',
        description: 'Play 5 different mini-games',
        icon: Icons.videogame_asset,
        color: Colors.purple,
        target: 5,
        current: 0,
        rewardCoins: 100,
        rewardGems: 10,
        category: ChallengeCategory.daily,
      ),
      DailyChallenge(
        id: 'perfect_care',
        title: 'Perfect Care',
        description: 'Keep all pet stats above 80%',
        icon: Icons.favorite,
        color: Colors.pink,
        target: 1,
        current: 0,
        rewardCoins: 75,
        rewardGems: 8,
        category: ChallengeCategory.daily,
      ),
      DailyChallenge(
        id: 'social_butterfly',
        title: 'Social Butterfly',
        description: 'Increase friendship level by 20',
        icon: Icons.people,
        color: Colors.green,
        target: 20,
        current: 0,
        rewardCoins: 60,
        rewardGems: 6,
        category: ChallengeCategory.weekly,
      ),
      DailyChallenge(
        id: 'achievement_hunter',
        title: 'Achievement Hunter',
        description: 'Unlock 3 new achievements',
        icon: Icons.emoji_events,
        color: Colors.amber,
        target: 3,
        current: 0,
        rewardCoins: 150,
        rewardGems: 15,
        category: ChallengeCategory.weekly,
      ),
      DailyChallenge(
        id: 'mini_game_champion',
        title: 'Mini Game Champion',
        description: 'Score 1000+ points in any mini-game',
        icon: Icons.sports_esports,
        color: Colors.red,
        target: 1000,
        current: 0,
        rewardCoins: 80,
        rewardGems: 8,
        category: ChallengeCategory.daily,
      ),
    ];

    _calculateProgress();
  }

  void _calculateProgress() {
    final gameProvider = context.read<GameProvider>();
    final accountProvider = context.read<AccountProvider>();
    final isPremium = accountProvider.isPremium;

    // Simulate progress calculation (in real app, this would track actual progress)
    setState(() {
      _challenges[0].current = 2; // Feed pet progress
      _challenges[1].current = 3; // Games played
      _challenges[2].current = (gameProvider.pet?.health ?? 0) > 80 ? 1 : 0;
      _challenges[3].current = 15; // Friendship progress
      _challenges[4].current = 2; // Achievements
      _challenges[5].current = 850; // Mini game score

      _completedToday = _challenges.where((c) => c.isCompleted).length;

      // Apply 2x bonus for premium users
      final multiplier = isPremium ? 2 : 1;
      _totalRewardCoins = _challenges
          .where((c) => c.isCompleted)
          .fold(0, (sum, c) => sum + (c.rewardCoins * multiplier));
      _totalRewardGems = _challenges
          .where((c) => c.isCompleted)
          .fold(0, (sum, c) => sum + (c.rewardGems * multiplier));
    });
  }

  void _claimReward(DailyChallenge challenge) {
    if (!challenge.isCompleted || challenge.rewardClaimed) return;

    final accountProvider = context.read<AccountProvider>();
    final isPremium = accountProvider.isPremium;
    final multiplier = isPremium ? 2 : 1;

    setState(() {
      challenge.rewardClaimed = true;
    });

    // Update account with rewards (2x for premium)
    context.read<AccountProvider>().updateStats(
          coins: challenge.rewardCoins * multiplier,
          gems: challenge.rewardGems * multiplier,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🎉 Claimed ${challenge.rewardCoins * multiplier} coins and ${challenge.rewardGems * multiplier} gems!'
          '${isPremium ? ' (2x Premium Bonus!)' : ''}',
        ),
        backgroundColor: isPremium ? Colors.amber : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountProvider = context.read<AccountProvider>();
    final isPremium = accountProvider.isPremium;

    return Scaffold(
      backgroundColor: const Color(0xFF2D2D3A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B1FA2),
        title: Row(
          children: [
            const Text(
              'Daily Challenges',
              style: TextStyle(color: Colors.white),
            ),
            if (isPremium) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: Text(
                  '2X REWARDS',
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadChallenges,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF3D3D4A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF7B1FA2).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Today\'s Progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7B1FA2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$_completedToday/${_challenges.length}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _completedToday / _challenges.length,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF7B1FA2),
                  ),
                ),
                const SizedBox(height: 16),
                if (_totalRewardCoins > 0 || _totalRewardGems > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_totalRewardCoins > 0) ...[
                        const Icon(Icons.monetization_on, color: Colors.yellow),
                        const SizedBox(width: 4),
                        Text(
                          '$_totalRewardCoins',
                          style: const TextStyle(color: Colors.yellow),
                        ),
                      ],
                      if (_totalRewardGems > 0) ...[
                        const SizedBox(width: 16),
                        const Icon(Icons.diamond, color: Colors.cyan),
                        const SizedBox(width: 4),
                        Text(
                          '$_totalRewardGems',
                          style: const TextStyle(color: Colors.cyan),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),

          // Challenges List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _challenges.length,
              itemBuilder: (context, index) {
                final challenge = _challenges[index];
                return _buildChallengeCard(challenge);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(DailyChallenge challenge) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: challenge.isCompleted
          ? const Color(0xFF4A5F4A)
          : const Color(0xFF3D3D4A),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: challenge.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(challenge.icon, color: challenge.color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        challenge.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(challenge.category),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getCategoryName(challenge.category),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress: ${challenge.current}/${challenge.target}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${(challenge.current / challenge.target * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: (challenge.current / challenge.target).clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    challenge.isCompleted ? Colors.green : challenge.color,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Rewards and Claim Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      color: Colors.yellow,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${challenge.rewardCoins}',
                      style: const TextStyle(color: Colors.yellow),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.diamond, color: Colors.cyan, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${challenge.rewardGems}',
                      style: const TextStyle(color: Colors.cyan),
                    ),
                  ],
                ),
                if (challenge.isCompleted && !challenge.rewardClaimed)
                  ElevatedButton(
                    onPressed: () => _claimReward(challenge),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('Claim'),
                  )
                else if (challenge.rewardClaimed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Claimed',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  )
                else
                  const Text(
                    'In Progress',
                    style: TextStyle(color: Colors.white70),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryName(ChallengeCategory category) {
    switch (category) {
      case ChallengeCategory.daily:
        return 'Daily';
      case ChallengeCategory.weekly:
        return 'Weekly';
      case ChallengeCategory.special:
        return 'Special';
    }
  }

  Color _getCategoryColor(ChallengeCategory category) {
    switch (category) {
      case ChallengeCategory.daily:
        return Colors.blue;
      case ChallengeCategory.weekly:
        return Colors.purple;
      case ChallengeCategory.special:
        return Colors.orange;
    }
  }
}

class DailyChallenge {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int target;
  int current;
  final int rewardCoins;
  final int rewardGems;
  final ChallengeCategory category;
  bool rewardClaimed;

  DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.target,
    required this.current,
    required this.rewardCoins,
    required this.rewardGems,
    required this.category,
    this.rewardClaimed = false,
  });

  bool get isCompleted => current >= target;
}

enum ChallengeCategory { daily, weekly, special }
