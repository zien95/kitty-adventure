import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final stats = gameProvider.globalStats;
        final games = gameProvider.availableGames;

        return Scaffold(
          backgroundColor: const Color(0xFF2D2D3A),
          appBar: AppBar(
            title: const Text(
              '📊 Statistics',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF7B1FA2),
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overall Stats
                _buildSectionCard(
                  '🎮 Overall Statistics',
                  [
                    _buildStatRow('Total Play Time',
                        '${_formatMinutes(stats['totalPlayTime'])}'),
                    _buildStatRow('Total Score', '${stats['totalScore']}'),
                    _buildStatRow('Games Played', '${stats['gamesPlayed']}'),
                    _buildStatRow(
                        'Achievements', '${stats['achievementsUnlocked']}'),
                  ],
                ),

                const SizedBox(height: 20),

                // Block Builder Stats
                _buildSectionCard(
                  '🎮 Block Builder 2D',
                  [
                    _buildStatRow('Blocks Placed',
                        '${stats['blockBuilderStats']['blocksPlaced']}'),
                    _buildStatRow('Blocks Broken',
                        '${stats['blockBuilderStats']['blocksBroken']}'),
                    _buildStatRow('Highest Score',
                        '${stats['blockBuilderStats']['highestScore']}'),
                    _buildStatRow('Worlds Created',
                        '${stats['blockBuilderStats']['worldsCreated']}'),
                  ],
                ),

                const SizedBox(height: 20),

                // Pet Stats
                _buildSectionCard(
                  '🐾 Pet Statistics',
                  [
                    _buildStatRow(
                        'Pets Owned', '${stats['petStats']['petsOwned']}'),
                    _buildStatRow(
                        'Pets Evolved', '${stats['petStats']['petsEvolved']}'),
                    _buildStatRow(
                        'Times Fed', '${stats['petStats']['totalFed']}'),
                    _buildStatRow(
                        'Times Played', '${stats['petStats']['totalPlayed']}'),
                  ],
                ),

                const SizedBox(height: 20),

                // Mini-Games Stats
                _buildSectionCard(
                  '🎯 Mini-Games',
                  [
                    _buildStatRow('Puzzles Won',
                        '${stats['miniGamesStats']['puzzleGamesWon']}'),
                    _buildStatRow('Arcade Games',
                        '${stats['miniGamesStats']['arcadeGamesPlayed']}'),
                    _buildStatRow('Best Time Attack',
                        '${stats['miniGamesStats']['timeAttackBest']}s'),
                    _buildStatRow('Endurance Mode',
                        '${_formatMinutes(stats['miniGamesStats']['enduranceModeTime'])}'),
                  ],
                ),

                const SizedBox(height: 20),

                // Game Performance
                _buildSectionCard(
                  '🏆 Game Performance',
                  games.map((game) => _buildGamePerformanceRow(game)).toList(),
                ),

                const SizedBox(height: 20),

                // Session Stats
                _buildSectionCard(
                  '📅 Session Information',
                  [
                    _buildStatRow('Current Session',
                        '${_formatMinutes(stats['sessionStats']['currentSessionTime'])}'),
                    _buildStatRow('Last Play Date',
                        stats['sessionStats']['lastPlayDate'] ?? 'Never'),
                    _buildStatRow('Consecutive Days',
                        '${stats['sessionStats']['consecutiveDays']}'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamePerformanceRow(Map<String, dynamic> game) {
    final isUnlocked = game['unlocked'] as bool;
    final highScore = game['highScore'] as int;
    final playCount = game['playCount'] as int;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            game['icon'],
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              game['name'],
              style: TextStyle(
                color: isUnlocked ? Colors.white : Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          if (isUnlocked) ...[
            Text(
              '🏆 $highScore',
              style: const TextStyle(
                color: Colors.yellow,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '🎮 $playCount',
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 12,
              ),
            ),
          ] else ...[
            Text(
              '🔒 ${game['unlockRequirement']}',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}m';
    }
  }
}
