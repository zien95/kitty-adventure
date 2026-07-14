import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/sound_service.dart';

class PuzzleGameScreen extends StatefulWidget {
  const PuzzleGameScreen({super.key});

  @override
  State<PuzzleGameScreen> createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends State<PuzzleGameScreen> {
  final SoundService _soundService = SoundService();
  List<int> _tiles = [];
  int _moves = 0;
  bool _isWon = false;
  final int _gridSize = 3;

  @override
  void initState() {
    super.initState();
    _initializePuzzle();
  }

  void _initializePuzzle() {
    _tiles = List.generate(9, (index) => index);
    _tiles.shuffle();
    // Ensure puzzle is solvable
    while (!_isSolvable()) {
      _tiles.shuffle();
    }
  }

  bool _isSolvable() {
    int inversions = 0;
    for (int i = 0; i < _tiles.length - 1; i++) {
      for (int j = i + 1; j < _tiles.length; j++) {
        if (_tiles[i] != 8 && _tiles[j] != 8 && _tiles[i] > _tiles[j]) {
          inversions++;
        }
      }
    }
    return inversions % 2 == 0;
  }

  void _moveTile(int index) {
    if (_isWon) return;

    final emptyIndex = _tiles.indexOf(8);
    final row = index ~/ _gridSize;
    final col = index % _gridSize;
    final emptyRow = emptyIndex ~/ _gridSize;
    final emptyCol = emptyIndex % _gridSize;

    // Check if adjacent to empty tile
    if ((row == emptyRow && (col - emptyCol).abs() == 1) ||
        (col == emptyCol && (row - emptyRow).abs() == 1)) {
      setState(() {
        _tiles[index] = 8;
        _tiles[emptyIndex] = index;
        _moves++;
      });
      _soundService.playSound('click');
      _checkWin();
    }
  }

  void _checkWin() {
    for (int i = 0; i < _tiles.length; i++) {
      if (_tiles[i] != i) return;
    }
    setState(() {
      _isWon = true;
    });
    _soundService.playSound('level_up');
    _showWinDialog();
  }

  void _showWinDialog() {
    final gameProvider = context.read<GameProvider>();
    final xpReward = 30;
    final coinReward = 15;
    final gemReward = 1;

    gameProvider.awardGameRewards(xpReward, gemReward, coinReward);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D3A),
        title: const Text(
          '🎉 Puzzle Complete!',
          style: TextStyle(color: Colors.green, fontSize: 24),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You solved it in $_moves moves!',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Rewards: $xpReward XP, $coinReward coins, $gemReward gem',
              style: const TextStyle(color: Colors.yellow, fontSize: 16),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Exit', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetGame();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child:
                const Text('Play Again', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      _moves = 0;
      _isWon = false;
    });
    _initializePuzzle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D2D3A),
      appBar: AppBar(
        backgroundColor: Colors.red,
        title:
            const Text('🧩 Puzzle Game', style: TextStyle(color: Colors.white)),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'How to play',
            icon: const Icon(Icons.help_outline),
            onPressed: _showHowToPlay,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Moves: $_moves',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHowToPlayCard(),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D3D4A),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: 9,
                    itemBuilder: (context, index) {
                      final tileNumber = _tiles[index];
                      final isEmpty = tileNumber == 8;

                      return GestureDetector(
                        onTap: () => _moveTile(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isEmpty
                                ? Colors.transparent
                                : Colors.red.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(8),
                            border: isEmpty
                                ? null
                                : Border.all(color: Colors.white, width: 2),
                            boxShadow: isEmpty
                                ? null
                                : [
                                    BoxShadow(
                                      color: Colors.red.withValues(alpha: 0.3),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                          ),
                          child: isEmpty
                              ? null
                              : Center(
                                  child: Text(
                                    '${tileNumber + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _resetGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                  ),
                  child: const Text('New Game', style: TextStyle(fontSize: 16)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                  ),
                  child: const Text('Exit', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowToPlayCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: const Text(
        'How to play: tap a tile next to the empty space to slide it. Put 1-8 in order, then leave the blank space at the end.',
        style: TextStyle(color: Colors.white, fontSize: 13, height: 1.35),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _showHowToPlay() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D3A),
        title: const Text(
          'How to Play',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Slide tiles into the empty square until the board is solved.\n\n'
          '1. Tap a tile beside the empty space.\n'
          '2. Keep sliding until the tiles read 1, 2, 3, 4, 5, 6, 7, 8.\n'
          '3. The blank space should finish in the last slot.\n\n'
          'Try to solve it in as few moves as possible.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
