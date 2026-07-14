import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/game_provider.dart';

class PuzzleMasterScreen extends StatefulWidget {
  const PuzzleMasterScreen({super.key});

  @override
  State<PuzzleMasterScreen> createState() => _PuzzleMasterScreenState();
}

class _PuzzleMasterScreenState extends State<PuzzleMasterScreen> {
  List<List<int>> _puzzleGrid = [];
  int _moves = 0;
  int _score = 0;
  int _level = 1;
  bool _isGameWon = false;
  Timer? _gameTimer;
  int _timeElapsed = 0;

  @override
  void initState() {
    super.initState();
    _initializePuzzle();
    _startGameTimer();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  void _startGameTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeElapsed++;
      });
    });
  }

  void _initializePuzzle() {
    final size = 4 + (_level - 1); // 4x4, 5x5, 6x6 grids
    _puzzleGrid = List.generate(size,
        (i) => List.generate(size, (j) => (i * size + j + 1) % (size * size)));

    // Shuffle the puzzle
    _shufflePuzzle();

    _moves = 0;
    _score = 0;
    _isGameWon = false;
    _timeElapsed = 0;
  }

  void _shufflePuzzle() {
    final size = _puzzleGrid.length;
    final random = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < size * size * 10; i++) {
      final row = (random + i) % size;
      final col = ((random + i) ~/ size) % size;

      if (row > 0) {
        _swapTiles(row, col, row - 1, col);
      }
      if (col > 0) {
        _swapTiles(row, col, row, col - 1);
      }
    }
  }

  void _swapTiles(int row1, int col1, int row2, int col2) {
    final temp = _puzzleGrid[row1][col1];
    _puzzleGrid[row1][col1] = _puzzleGrid[row2][col2];
    _puzzleGrid[row2][col2] = temp;
  }

  void _onTileTap(int row, int col) {
    if (_isGameWon) return;

    final size = _puzzleGrid.length;

    // Check if adjacent to empty space (0)
    if (row > 0 && _puzzleGrid[row - 1][col] == 0) {
      _swapTiles(row, col, row - 1, col);
      _moves++;
    } else if (row < size - 1 && _puzzleGrid[row + 1][col] == 0) {
      _swapTiles(row, col, row + 1, col);
      _moves++;
    } else if (col > 0 && _puzzleGrid[row][col - 1] == 0) {
      _swapTiles(row, col, row, col - 1);
      _moves++;
    } else if (col < size - 1 && _puzzleGrid[row][col + 1] == 0) {
      _swapTiles(row, col, row, col + 1);
      _moves++;
    }

    _checkWinCondition();
    setState(() {});
  }

  void _checkWinCondition() {
    final size = _puzzleGrid.length;
    bool isWon = true;

    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        final expectedValue = (i * size + j + 1) % (size * size);
        if (_puzzleGrid[i][j] != expectedValue) {
          isWon = false;
          break;
        }
      }
      if (!isWon) break;
    }

    if (isWon) {
      _isGameWon = true;
      _gameTimer?.cancel();
      _calculateScore();
      _updateGameStats();
    }
  }

  void _calculateScore() {
    final baseScore = 1000;
    final movesPenalty = _moves * 5;
    final timePenalty = _timeElapsed * 2;
    final levelBonus = _level * 100;

    _score = (baseScore - movesPenalty - timePenalty + levelBonus)
        .clamp(0, double.infinity)
        .toInt();
  }

  void _updateGameStats() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    gameProvider.updateGameStats('puzzle_master', _score, _isGameWon);
  }

  void _nextLevel() {
    setState(() {
      _level++;
      _initializePuzzle();
    });
  }

  void _resetGame() {
    setState(() {
      _initializePuzzle();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        title: Text('🧩 Puzzle Master - Level $_level'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'How to play',
            icon: const Icon(Icons.help_outline),
            onPressed: _showHowToPlay,
          ),
          IconButton(
            tooltip: 'Reset',
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.purple.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Moves',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('$_moves', style: const TextStyle(fontSize: 20)),
                  ],
                ),
                Column(
                  children: [
                    const Text('Time',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${_timeElapsed}s',
                        style: const TextStyle(fontSize: 20)),
                  ],
                ),
                Column(
                  children: [
                    const Text('Score',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('$_score', style: const TextStyle(fontSize: 20)),
                  ],
                ),
              ],
            ),
          ),

          _buildHowToPlayCard(),

          // Puzzle Grid
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _puzzleGrid.length,
                    childAspectRatio: 1.0,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: _puzzleGrid.length * _puzzleGrid.length,
                  itemBuilder: (context, index) {
                    final row = index ~/ _puzzleGrid.length;
                    final col = index % _puzzleGrid.length;
                    final value = _puzzleGrid[row][col];

                    return GestureDetector(
                      onTap: () => _onTileTap(row, col),
                      child: Container(
                        decoration: BoxDecoration(
                          color: value == 0
                              ? Colors.grey.shade300
                              : Colors.purple.shade400,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.purple.shade600,
                            width: 2,
                          ),
                        ),
                        child: value == 0
                            ? null
                            : Center(
                                child: Text(
                                  '$value',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
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

          // Win Dialog
          if (_isGameWon)
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.green.shade100,
              child: Column(
                children: [
                  const Text(
                    '🎉 Puzzle Completed!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                      'Score: $_score | Moves: $_moves | Time: ${_timeElapsed}s'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _nextLevel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Next Level'),
                      ),
                      ElevatedButton(
                        onPressed: _resetGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Reset'),
                      ),
                    ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Text(
        'How to play: tap a numbered tile next to the empty square to slide it. Put the numbers in order, with the empty square last. Fewer moves and faster time mean a better score.',
        style: TextStyle(fontSize: 13, height: 1.35),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _showHowToPlay() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Play'),
        content: const Text(
          'Slide tiles into the empty square until the board is in order.\n\n'
          '1. Tap a tile beside the empty space.\n'
          '2. Keep sliding tiles until the numbers count up left to right.\n'
          '3. Finish with the blank tile in the bottom-right corner.\n\n'
          'Your score is higher when you solve it with fewer moves and less time.',
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
