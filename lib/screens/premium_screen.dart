import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/account_provider.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AccountProvider>().updateStats(isPremium: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D2D3A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B1FA2),
        title: const Text(
          'Premium Features',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<AccountProvider>(
        builder: (context, accountProvider, child) {
          final account = accountProvider.account;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFreeStatusCard(account?.username),
                const SizedBox(height: 24),
                const Text(
                  'Everything is unlocked',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ..._buildPremiumFeatures(),
                const SizedBox(height: 24),
                _buildComparisonTable(),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('All Features Unlocked'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFreeStatusCard(String? username) {
    final displayName =
        username == null || username.isEmpty ? 'player' : username;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD95C), Color(0xFFFF9D5C), Color(0xFFFF6FAF)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.28),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(Icons.star, size: 46, color: Colors.white),
          ),
          const SizedBox(height: 14),
          const Text(
            'Premium is Free',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'No payment needed, $displayName. Every pet, theme, bonus, and ad-free feature is ready to use.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPremiumFeatures() {
    final features = [
      {
        'title': 'Unlimited Pets',
        'description': 'Care for every pet without a paid unlock.',
        'icon': Icons.pets,
        'color': Colors.orange,
      },
      {
        'title': 'Exclusive Mini-Games',
        'description': 'All mini-games and bonus content are open.',
        'icon': Icons.videogame_asset,
        'color': Colors.pink,
      },
      {
        'title': 'Ad-Free Experience',
        'description': 'The game stays clean with ads turned off.',
        'icon': Icons.block,
        'color': Colors.lightBlueAccent,
      },
      {
        'title': 'Daily Bonus x2',
        'description': 'Daily challenge rewards always get the bonus.',
        'icon': Icons.monetization_on,
        'color': Colors.amber,
      },
      {
        'title': 'Custom Themes',
        'description': 'Galaxy, rainbow, golden, and more are unlocked.',
        'icon': Icons.palette,
        'color': Colors.purpleAccent,
      },
      {
        'title': 'Cloud Sync',
        'description': 'Progress tools stay available for everyone.',
        'icon': Icons.cloud_sync,
        'color': Colors.greenAccent,
      },
    ];

    return features.map(_buildFeatureCard).toList();
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature) {
    final color = feature['color'] as Color;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF3D3D4A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(feature['icon'] as IconData, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature['title'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feature['description'] as String,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTable() {
    final rows = [
      ['Pets', 'All'],
      ['Mini-games', 'All'],
      ['Themes', 'All'],
      ['Daily rewards', '2x'],
      ['Ads', 'Off'],
      ['Price', 'Free'],
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3D3D4A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Current Access',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...rows.map((row) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row[0],
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  Text(
                    row[1],
                    style: const TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
