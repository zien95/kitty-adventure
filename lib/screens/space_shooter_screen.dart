import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/game_provider.dart';

class SpaceShooterScreen extends StatefulWidget {
  const SpaceShooterScreen({super.key});

  @override
  State<SpaceShooterScreen> createState() => _SpaceShooterScreenState();
}

class _SpaceShooterScreenState extends State<SpaceShooterScreen> {
  double _playerX = 0.5;
  List<Map<String, dynamic>> _enemies = [];
  List<Map<String, dynamic>> _bullets = [];
  List<Map<String, dynamic>> _stars = [];
  int _score = 0;
  int _lives = 3;
  bool _gameOver = false;
  bool _isPaused = false;
  Timer? _gameTimer;
  Timer? _enemySpawnTimer;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _startGame();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _enemySpawnTimer?.cancel();
    super.dispose();
  }

  void _initializeGame() {
    _playerX = 0.5;
    _enemies = [];
    _bullets = [];
    _stars = _generateStars();
    _score = 0;
    _lives = 3;
    _gameOver = false;
    _isPaused = false;
  }

  List<Map<String, dynamic>> _generateStars() {
    return List.generate(
        20,
        (index) => {
              'x': (index * 137.5) % 1.0,
              'y': (index * 89.3) % 1.0,
              'size': ((index % 3) + 1) * 2.0,
              'speed': ((index % 3) + 1) * 0.002,
            });
  }

  void _startGame() {
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_gameOver && !_isPaused) {
        _updateGame();
      }
    });

    _enemySpawnTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_gameOver && !_isPaused) {
        _spawnEnemy();
      }
    });
  }

  void _updateGame() {
    // Update stars
    for (var star in _stars) {
      star['y'] = (star['y'] + star['speed']) % 1.0;
    }

    // Update bullets
    _bullets.removeWhere((bullet) {
      bullet['y'] -= 0.02;
      return bullet['y'] < 0;
    });

    // Update enemies
    _enemies.removeWhere((enemy) {
      enemy['y'] += enemy['speed'];

      // Check if enemy reached bottom
      if (enemy['y'] > 0.9) {
        _lives--;
        if (_lives <= 0) {
          _endGame();
        }
        return true;
      }

      return false;
    });

    // Check collisions
    _checkCollisions();

    setState(() {});
  }

  void _spawnEnemy() {
    _enemies.add({
      'x': (DateTime.now().millisecondsSinceEpoch % 100) / 100.0,
      'y': -0.1,
      'speed': 0.005 + (_score / 1000) * 0.002, // Speed increases with score
      'type': (DateTime.now().millisecondsSinceEpoch % 3),
    });
  }

  void _shoot() {
    if (_gameOver || _isPaused) return;

    _bullets.add({
      'x': _playerX,
      'y': 0.8,
    });
  }

  void _checkCollisions() {
    for (var bullet in List.from(_bullets)) {
      for (var enemy in List.from(_enemies)) {
        final dx = (bullet['x'] - enemy['x']).abs();
        final dy = (bullet['y'] - enemy['y']).abs();

        if (dx < 0.05 && dy < 0.05) {
          _bullets.remove(bullet);
          _enemies.remove(enemy);
          _score += 100;
          break;
        }
      }
    }
  }

  void _movePlayer(double deltaX) {
    setState(() {
      _playerX = (_playerX + deltaX).clamp(0.05, 0.95);
    });
  }

  void _endGame() {
    _gameOver = true;
    _gameTimer?.cancel();
    _enemySpawnTimer?.cancel();
    _updateGameStats();
  }

  void _updateGameStats() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    gameProvider.updateGameStats('space_shooter', _score, _score > 1000);
  }

  void _restartGame() {
    setState(() {
      _initializeGame();
      _startGame();
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('🚀 Space Shooter'),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: _togglePause,
          ),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          _movePlayer(details.delta.dx / 300);
        },
        onTap: _shoot,
        child: Stack(
          children: [
            // Stars background
            ..._stars.map((star) => Positioned(
                  left: star['x'] * MediaQuery.of(context).size.width,
                  top: star['y'] * MediaQuery.of(context).size.height,
                  child: Container(
                    width: star['size'],
                    height: star['size'],
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                )),

            // Enemies
            ..._enemies.map((enemy) => Positioned(
                  left: enemy['x'] * MediaQuery.of(context).size.width,
                  top: enemy['y'] * MediaQuery.of(context).size.height,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: [
                        Colors.red,
                        Colors.orange,
                        Colors.purple,
                      ][enemy['type'] % 3],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      [
                        Icons.bug_report,
                        Icons.flash_on,
                        Icons.whatshot,
                      ][enemy['type'] % 3],
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                )),

            // Bullets
            ..._bullets.map((bullet) => Positioned(
                  left: bullet['x'] * MediaQuery.of(context).size.width - 2,
                  top: bullet['y'] * MediaQuery.of(context).size.height,
                  child: Container(
                    width: 4,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.yellow,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),

            // Player
            Positioned(
              left: _playerX * MediaQuery.of(context).size.width - 15,
              bottom: 50,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.rocket_launch,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),

            // UI Overlay
            Positioned(
              top: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Score: $_score',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Lives: $_lives',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

            // Game Over Screen
            if (_gameOver)
              Container(
                color: Colors.black.withValues(alpha: 0.8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'GAME OVER',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Final Score: $_score',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _restartGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                        ),
                        child: const Text('Play Again'),
                      ),
                    ],
                  ),
                ),
              ),

            // Pause Screen
            if (_isPaused && !_gameOver)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: Text(
                    'PAUSED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // Instructions
            if (!_gameOver)
              Positioned(
                bottom: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Drag: Move',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      Text(
                        'Tap: Shoot',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
