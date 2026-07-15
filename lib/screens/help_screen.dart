import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D2D3A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B1FA2),
        title: const Text('🎮 Help & Guide',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection('🆕 WHAT\'S NEW', _whatsNewContent()),
            const SizedBox(height: 20),
            _buildSection('⌨️ KEYBOARD SHORTCUTS', _keyboardShortcutsContent()),
            const SizedBox(height: 20),
            _buildSection('🎯 HOW TO PLAY', _howToPlayContent()),
            const SizedBox(height: 20),
            _buildSection('💡 PRO TIPS', _proTipsContent()),
            const SizedBox(height: 20),
            _buildSection('📊 STAT GUIDE', _statGuideContent()),
            const SizedBox(height: 20),
            _buildSection('🏆 ACHIEVEMENTS', _achievementContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> content) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3D3D4A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF7B1FA2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _keyboardShortcutsContent() {
    return [
      _buildHelpItem(
        '⌨️ Pet Care Shortcuts',
        '• F - Feed pet\n'
            '• P - Play with pet\n'
            '• C - Clean pet\n'
            '• S - Sleep pet\n'
            '• T - Train pet\n'
            '• M - Give medicine',
        Icons.pets,
      ),
      _buildHelpItem(
        '🎮 Navigation Shortcuts',
        '• G - Open Games menu\n'
            '• Z - Open Customization\n'
            '• O - Open Obstacle Course\n'
            '• H - Open Help screen\n'
            '• Set - Open Settings\n'
            '• A - Toggle Actions menu\n'
            '• ESC - Close Actions menu',
        Icons.navigation,
      ),
      _buildHelpItem(
        '♿ Accessibility Features',
        'Keyboard shortcuts make the app accessible to users who '
            'prefer keyboard navigation or have difficulty using touch controls. '
            'All shortcuts are designed to be intuitive and easy to remember.',
        Icons.accessibility,
      ),
    ];
  }

  List<Widget> _whatsNewContent() {
    return [
      _buildFeatureItem(
        '🌍 BLOCK BUILDER v26.8.4',
        '3 complete worlds to explore\nPress T to teleport between dimensions\nEach world has unique blocks and surprises',
      ),
      _buildFeatureItem(
        '🔬 QUANTUM PHYSICS',
        'Realistic block interactions at atomic level\nQuantum entanglement between connected blocks\nParticle accelerator for element creation',
      ),
      _buildFeatureItem(
        '🧬 BIOMEDICAL ENGINEERING',
        'Living blocks and organisms\nDNA sequencing for custom block creation\nEvolution system for block adaptation',
      ),
      _buildFeatureItem(
        '🤖 AI ASSISTANTS',
        'Smart building companions\nMachine learning for optimal construction\nNeural interface for thought control',
      ),
      _buildFeatureItem(
        '🌌 SPACE EXPLORATION',
        'Travel to distant galaxies\nEstablish alien colonies on other planets\nUFO encounters with advanced technology',
      ),
      _buildFeatureItem(
        '⚛️ NUCLEAR POWER',
        'Advanced energy systems\nFusion reactors for unlimited power\nRadiation shielding and safety protocols',
      ),
      _buildFeatureItem(
        '🌊 REALISTIC PHYSICS',
        'Fluid dynamics simulation\nThermal dynamics between blocks\nElectrical systems with power grids',
      ),
      _buildFeatureItem(
        '🌪 NATURAL DISASTERS',
        'Tornadoes with evacuation systems\nTsunamis with ocean wave mechanics\nHurricanes with storm survival',
      ),
      _buildFeatureItem(
        '🌎 PLANETARY SYSTEMS',
        'Multiple worlds with orbital mechanics\nGravity manipulation with anti-gravity blocks\nTime travel to past and future worlds',
      ),
      _buildFeatureItem(
        '🌐 MULTIVERSE ACCESS',
        'Parallel universes with different physics\nWormholes for instant dimension travel\nPrecognition for future block placement',
      ),
      _buildFeatureItem(
        '🔬 MICROSCOPIC WORLD',
        'Explore blocks at atomic level\nQuantum mechanics at nanoscale\nSubatomic particle manipulation',
      ),
      _buildFeatureItem(
        '🤖 CYBERNETIC ENHANCEMENTS',
        'Upgrade player abilities with implants\nNeural interface for direct control\nQuantum computing for enhanced processing',
      ),
      _buildFeatureItem(
        '🚀 ADVANCED TRANSPORT',
        'Rocket launch systems for space travel\nMinecart railways with automated transport\nTeleportation networks across dimensions',
      ),
      _buildFeatureItem(
        '🎮 ENHANCED GAMEPLAY',
        '27 total blocks across all dimensions\nCreative mode with unlimited blocks\nStructure templates for instant building',
      ),
      _buildFeatureItem(
        '🌈 ENVIRONMENTAL SYSTEMS',
        'Dynamic weather with rain, snow, thunder\nLiving ecosystems with flora and fauna\nSeasonal changes and climate adaptation',
      ),
      _buildFeatureItem(
        '⚡ ENERGY SYSTEMS',
        'Power grids and electrical circuits\nNuclear fusion for clean energy\nQuantum entanglement for instant communication',
      ),
    ];
  }

  List<Widget> _howToPlayContent() {
    return [
      _buildGuideItem(
        '🎮 BASIC CONTROLS',
        '1. Press "Interact with Pet" to show action grid\n2. Tap any action button to interact\n3. Watch your pet\'s stats change\n4. Keep all stats balanced for best results',
      ),
      _buildGuideItem(
        '🍽️ DAILY CARE ROUTINE',
        '• Feed when hunger > 70 (reduces hunger +10 happiness)\n• Clean when cleanliness < 50 (+30 cleanliness +15 happiness)\n• Play when happiness < 60 (+25 happiness +3 social)\n• Sleep when energy < 30 (+50 energy +15 health)',
      ),
      _buildGuideItem(
        '🎓 TRAINING & SKILLS',
        '• Train to increase intelligence (+5 per session)\n• Level up skills in Skills menu (+2 intelligence each)\n• Max all 4 skills for +80 intelligence bonus',
      ),
      _buildGuideItem(
        '🎮 MINI-GAMES',
        '• Tap "Games" to play mini-games\n• Win XP, coins, and gems\n• Use gems to buy accessories\n• Use coins to buy items',
      ),
      _buildGuideItem(
        '🧬 EVOLUTION',
        '• Reach levels 10, 20, 35, 50 to evolve\n• Evolution gives permanent stat bonuses\n• Higher intelligence helps evolution',
      ),
    ];
  }

  List<Widget> _proTipsContent() {
    return [
      _buildTipItem(
        '⚡ ENERGY MANAGEMENT',
        '• Sleep before training sessions\n• Use energy drinks for quick boosts\n• Train when energy > 50 for multiple sessions',
      ),
      _buildTipItem(
        '💰 CURRENCY STRATEGY',
        '• Play mini-games for gems and coins\n• Save gems for accessories\n• Use coins for emergency items',
      ),
      _buildTipItem(
        '🎯 EFFICIENT TRAINING',
        '• Train is the best way to increase intelligence\n• Bond is free and increases social + friendship\n• Play gives happiness + social + XP',
      ),
      _buildTipItem(
        '🛡️ STAT BALANCE',
        '• Keep all stats above 50 for best health\n• Low stats cause health to decrease\n• High stats give health bonuses',
      ),
      _buildTipItem(
        '🎮 MINI-GAME MASTERY',
        '• Memory game: Focus on pattern recognition\n• Catch game: Keep paddle centered\n• Rhythm game: Watch the sequence carefully',
      ),
      _buildTipItem(
        '💝 FRIENDSHIP BUILDING',
        '• Bond daily (free social + friendship)\n• Use treats for loyalty bonuses\n• High friendship unlocks loving mood',
      ),
    ];
  }

  List<Widget> _statGuideContent() {
    return [
      _buildStatItem(
        '🍽️ Hunger',
        'Lower is better (0 = full, 100 = starving)\n• Feed: -25 hunger +10 happiness\n• Treat: -15 hunger +20 happiness +2 loyalty',
      ),
      _buildStatItem(
        '⚡ Energy',
        'Higher is better (0 = tired, 100 = energetic)\n• Sleep: +50 energy +15 health\n• Energy Drink: +50 energy +5 happiness',
      ),
      _buildStatItem(
        '🧼 Cleanliness',
        'Higher is better (0 = dirty, 100 = clean)\n• Clean: +30 cleanliness +15 happiness ⭐',
      ),
      _buildStatItem(
        '😊 Happiness',
        'Higher is better (0 = sad, 100 = very happy)\n• Play: +25 happiness +3 social\n• Toy: +15 happiness +2 social',
      ),
      _buildStatItem(
        '❤️ Health',
        'Higher is better (0 = sick, 100 = healthy)\n• Medicine: +30 health\n• Good stats give +1 health per decay',
      ),
      _buildStatItem(
        '🧠 Intelligence',
        'Higher is better for evolution\n• Train: +5 intelligence per session\n• Skills: +2 intelligence per level',
      ),
      _buildStatItem(
        '👥 Social',
        'Higher is better for mood\n• Play: +3 social\n• Bond: +2 social +1 friendship',
      ),
    ];
  }

  List<Widget> _achievementContent() {
    return [
      _buildAchievementItem(
        '🎯 LEVEL MILESTONES',
        '• Level 5: "Growing Pet"\n• Level 10: "Evolution Ready"\n• Level 25: "Experienced Owner"\n• Level 50: "Pet Master"\n• Level 100: "Legendary Pet"',
      ),
      _buildAchievementItem(
        '💰 CURRENCY GOALS',
        '• 100 Coins: "Coin Collector"\n• 500 Coins: "Rich Owner"\n• 10 Gems: "Gem Finder"\n• 50 Gems: "Gem Hoarder"',
      ),
      _buildAchievementItem(
        '🧬 EVOLUTION STAGES',
        '• First Evolution: "Evolution Beginner"\n• All Evolutions: "Evolution Master"',
      ),
      _buildAchievementItem(
        '💝 FRIENDSHIP LEVELS',
        '• 25% Friendship: "Good Friend"\n• 50% Friendship: "Best Friend"\n• 75% Friendship: "Soul Mate"\n• 100% Friendship: "Perfect Bond"',
      ),
      _buildAchievementItem(
        '🎮 MINI-GAME MASTERY',
        '• Win 10 Games: "Game Player"\n• Win 50 Games: "Game Expert"\n• Win 100 Games: "Game Master"',
      ),
    ];
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF3D3D4A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.cyan.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.cyan, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.cyan,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
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

  Widget _buildGuideItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.cyan,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.green,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
