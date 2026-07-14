import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/pet.dart';

class ObstacleCourseScreen extends StatefulWidget {
  const ObstacleCourseScreen({super.key});

  @override
  State<ObstacleCourseScreen> createState() => _ObstacleCourseScreenState();
}

class _ObstacleCourseScreenState extends State<ObstacleCourseScreen> {
  double _petX = 50.0;
  double _petY = 300.0;
  bool _isJumping = false;
  bool _isSliding = false;
  bool _gameOver = false;
  bool _gameWon = false;
  int _score = 0;
  int _coins = 0;
  int _level = 1;
  List<Obstacle> _obstacles = [];
  List<Coin> _coinsList = [];
  double _gameSpeed = 2.0;

  // Touch control variables
  bool _isPressed = false;
  Timer? _longPressTimer;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    _generateLevel();
    _gameLoop();
  }

  void _generateLevel() {
    _obstacles.clear();
    _coinsList.clear();

    // Generate obstacles based on level
    for (int i = 0; i < 5 + _level; i++) {
      _obstacles.add(Obstacle(
        x: 400.0 + (i * 200.0),
        y: _getRandomY(),
        type: _getRandomObstacleType(),
        width: 40.0,
        height: 60.0,
      ));
    }

    // Generate coins
    for (int i = 0; i < 8 + _level * 2; i++) {
      _coinsList.add(Coin(
        x: 300.0 + (i * 150.0),
        y: 200.0 + (i % 3) * 50.0,
        collected: false,
      ));
    }
  }

  double _getRandomY() {
    final positions = [300.0, 250.0, 350.0];
    return positions[(DateTime.now().millisecond % 3)];
  }

  ObstacleType _getRandomObstacleType() {
    final types = [ObstacleType.box, ObstacleType.spike, ObstacleType.bird];
    return types[(DateTime.now().millisecond % 3)];
  }

  void _gameLoop() {
    if (_gameOver || _gameWon) return;

    Future.delayed(const Duration(milliseconds: 16), () {
      _updateGame();
      _gameLoop();
    });
  }

  void _updateGame() {
    // Move obstacles
    for (var obstacle in _obstacles) {
      obstacle.x -= _gameSpeed;
    }

    // Move coins
    for (var coin in _coinsList) {
      coin.x -= _gameSpeed;
    }

    // Check collisions
    _checkCollisions();

    // Check if level complete
    if (_obstacles.every((o) => o.x < -50)) {
      _levelComplete();
    }

    setState(() {});
  }

  void _checkCollisions() {
    // Check obstacle collisions
    for (var obstacle in _obstacles) {
      if (_isColliding(
        _petX,
        _petY,
        40.0,
        40.0,
        obstacle.x,
        obstacle.y,
        obstacle.width,
        obstacle.height,
      )) {
        if (!_isJumping && !_isSliding) {
          _gameOver = true;
          _showGameOver();
        }
      }
    }

    // Check coin collections
    for (var coin in _coinsList) {
      if (!coin.collected &&
          _isColliding(
            _petX,
            _petY,
            40.0,
            40.0,
            coin.x,
            coin.y,
            30.0,
            30.0,
          )) {
        coin.collected = true;
        _coins++;
        _score += 10;

        // Award coins to pet immediately
        context.read<GameProvider>().awardGameRewards(5, 0, 1);
        context.read<GameProvider>().playClickSound();
      }
    }
  }

  bool _isColliding(double x1, double y1, double w1, double h1, double x2,
      double y2, double w2, double h2) {
    return x1 < x2 + w2 && x1 + w1 > x2 && y1 < y2 + h2 && y1 + h1 > y2;
  }

  void _jump() {
    if (_isJumping || _gameOver || _gameWon) return;

    setState(() {
      _isJumping = true;
    });

    // Jump animation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _petY = 200.0);
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _petY = 300.0;
          _isJumping = false;
        });
      }
    });
  }

  void _slide() {
    if (_isSliding || _gameOver || _gameWon) return;

    setState(() {
      _isSliding = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isSliding = false);
    });
  }

  void _levelComplete() {
    _gameWon = true;
    _score += 100 * _level;

    // Award rewards to pet
    final gameProvider = context.read<GameProvider>();
    final xpReward = 50 * _level;
    final coinReward = 20 * _level;
    final gemReward = _level > 3 ? 2 : 1;

    gameProvider.awardGameRewards(xpReward, gemReward, coinReward);

    _showLevelComplete();
  }

  void _showGameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D3A),
        title: const Text(
          '💥 Game Over!',
          style: TextStyle(color: Colors.red, fontSize: 24),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Score: $_score',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              'Coins: $_coins',
              style: const TextStyle(color: Colors.yellow, fontSize: 18),
            ),
            Text(
              'Level: $_level',
              style: const TextStyle(color: Colors.cyan, fontSize: 18),
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
              _restartGame();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showLevelComplete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D3A),
        title: const Text(
          '🎉 Level Complete!',
          style: TextStyle(color: Colors.green, fontSize: 24),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Score: $_score',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              'Coins: $_coins',
              style: const TextStyle(color: Colors.yellow, fontSize: 18),
            ),
            Text(
              'Level $_level Complete!',
              style: const TextStyle(color: Colors.cyan, fontSize: 18),
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
              _nextLevel();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            child:
                const Text('Next Level', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _restartGame() {
    setState(() {
      _petX = 50.0;
      _petY = 300.0;
      _isJumping = false;
      _isSliding = false;
      _gameOver = false;
      _gameWon = false;
      _score = 0;
      _coins = 0;
      _level = 1;
      _gameSpeed = 2.0;
    });
    _generateLevel();
    _gameLoop();
  }

  void _nextLevel() {
    setState(() {
      _petX = 50.0;
      _petY = 300.0;
      _isJumping = false;
      _isSliding = false;
      _gameOver = false;
      _gameWon = false;
      _level++;
      _gameSpeed = 2.0 + (_level * 0.3);
    });
    _generateLevel();
    _gameLoop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF87CEEB), // Sky blue
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF2D2D3A),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Level $_level',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Score: $_score',
                    style: const TextStyle(
                        color: Colors.yellow,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '💰 $_coins',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // Game Area
            Expanded(
              child: Focus(
                autofocus: true,
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent && !_gameOver && !_gameWon) {
                    switch (event.logicalKey.keyLabel) {
                      case 'Space':
                        _jump();
                        return KeyEventResult.handled;
                      case 'Shift':
                      case 'Shift Left':
                      case 'Shift Right':
                        _slide();
                        return KeyEventResult.handled;
                    }
                  }
                  return KeyEventResult.ignored;
                },
                child: GestureDetector(
                  onTapDown: (details) {
                    if (!_gameOver && !_gameWon) {
                      _isPressed = true;
                      _jump();

                      // Start long press timer for sliding
                      _longPressTimer =
                          Timer(const Duration(milliseconds: 300), () {
                        if (_isPressed) {
                          _slide();
                        }
                      });
                    }
                  },
                  onTapUp: (details) {
                    _isPressed = false;
                    _longPressTimer?.cancel();
                  },
                  onTapCancel: () {
                    _isPressed = false;
                    _longPressTimer?.cancel();
                  },
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF87CEEB), Color(0xFF98FB98)],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Ground
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 100,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF8B4513), Color(0xFF654321)],
                              ),
                            ),
                          ),
                        ),

                        // Obstacles
                        ..._obstacles.map((obstacle) => Positioned(
                              left: obstacle.x,
                              bottom: obstacle.y,
                              child: _buildObstacle(obstacle),
                            )),

                        // Coins
                        ..._coinsList.map((coin) => coin.collected
                            ? const SizedBox()
                            : Positioned(
                                left: coin.x,
                                bottom: coin.y,
                                child: _buildCoin(),
                              )),

                        // Pet
                        Positioned(
                          left: _petX,
                          bottom: _petY,
                          child: _buildPet(),
                        ),

                        // Instructions
                        if (_level == 1 && _score == 0)
                          Positioned(
                            top: 20,
                            left: 20,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'PC: Space to Jump, Shift to Slide!\n'
                                'Phone: Tap to Jump, Long Press to Slide!\n'
                                'Avoid obstacles and collect coins!',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Controls
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF2D2D3A),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _jump,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                    ),
                    child: const Text('Jump', style: TextStyle(fontSize: 18)),
                  ),
                  ElevatedButton(
                    onPressed: _slide,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                    ),
                    child: const Text('Slide', style: TextStyle(fontSize: 18)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                    ),
                    child: const Text('Exit', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPet() {
    final gameProvider = context.read<GameProvider>();
    final pet = gameProvider.pet;
    final petSize = _isSliding ? 20.0 : 40.0;
    final petOffset = _isSliding ? 20.0 : 0.0;

    if (pet == null) {
      return Container(
        width: petSize,
        height: petSize,
        margin: EdgeInsets.only(top: petOffset),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.8),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Text('🐾', style: TextStyle(fontSize: 24)),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: petSize,
      height: petSize,
      margin: EdgeInsets.only(top: petOffset),
      decoration: BoxDecoration(
        color: pet.type.color.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        border: Border.all(color: pet.type.color, width: 2),
      ),
      child: Center(
        child: Text(
          pet.type.emoji,
          style: TextStyle(fontSize: _isSliding ? 16 : 24),
        ),
      ),
    );
  }

  Widget _buildObstacle(Obstacle obstacle) {
    switch (obstacle.type) {
      case ObstacleType.box:
        return Container(
          width: obstacle.width,
          height: obstacle.height,
          decoration: BoxDecoration(
            color: Colors.brown,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.black),
          ),
        );
      case ObstacleType.spike:
        return Container(
          width: obstacle.width,
          height: obstacle.height,
          decoration: const BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.change_history, color: Colors.red, size: 30),
        );
      case ObstacleType.bird:
        return Container(
          width: obstacle.width,
          height: obstacle.height,
          child: const Column(
            children: [
              Icon(Icons.flight, color: Colors.blue, size: 30),
              Text('🦅', style: TextStyle(fontSize: 20)),
            ],
          ),
        );
    }
  }

  Widget _buildCoin() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.yellow,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.orange, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.yellow.withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Center(
        child: Text('💰', style: TextStyle(fontSize: 16)),
      ),
    );
  }
}

class Obstacle {
  double x;
  double y;
  ObstacleType type;
  double width;
  double height;

  Obstacle({
    required this.x,
    required this.y,
    required this.type,
    required this.width,
    required this.height,
  });
}

class Coin {
  double x;
  double y;
  bool collected;

  Coin({
    required this.x,
    required this.y,
    this.collected = false,
  });
}

enum ObstacleType {
  box,
  spike,
  bird,
}
