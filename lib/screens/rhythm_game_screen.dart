import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/account_provider.dart';

class RhythmGameScreen extends StatefulWidget {
  const RhythmGameScreen({super.key});

  @override
  State<RhythmGameScreen> createState() => _RhythmGameScreenState();
}

class _RhythmGameScreenState extends State<RhythmGameScreen>
    with TickerProviderStateMixin {
  static const List<String> _songs = [
    'Pet Dance',
    'Happy Beats',
    'Rhythm Fun',
    'Music Time',
  ];

  int _currentSongIndex = 0;
  int _score = 0;
  int _combo = 0;
  int _maxCombo = 0;
  bool _isPlaying = false;
  bool _gameOver = false;
  int _missedNotes = 0;
  int _hitNotes = 0;

  late AnimationController _gameController;
  late AnimationController _noteController;
  List<Note> _notes = [];
  Timer? _gameTimer;
  Timer? _noteGenerator;

  static const double _noteSpeed = 5.0;
  static const double _hitZoneTop = 0.7;
  static const double _hitZoneBottom = 0.8;

  @override
  void initState() {
    super.initState();
    _gameController = AnimationController(
      duration: const Duration(seconds: 120),
      vsync: this,
    );
    _noteController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _gameController.dispose();
    _noteController.dispose();
    _gameTimer?.cancel();
    _noteGenerator?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _gameOver = false;
      _score = 0;
      _combo = 0;
      _maxCombo = 0;
      _missedNotes = 0;
      _hitNotes = 0;
      _notes.clear();
    });

    _gameController.reset();
    _gameController.forward();

    _noteGenerator = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_isPlaying && !_gameOver) {
        _generateNote();
      }
    });

    _gameTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_isPlaying && !_gameOver) {
        _updateGame();
      }
    });
  }

  void _generateNote() {
    final lanes = [0, 1, 2, 3];
    lanes.shuffle();
    final lane = lanes.first;

    _notes.add(Note(
      lane: lane,
      position: 0.0,
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    ));
  }

  void _updateGame() {
    setState(() {
      // Move notes down
      for (var note in _notes) {
        note.position += _noteSpeed / 100;
      }

      // Remove notes that are off screen
      _notes.removeWhere((note) {
        if (note.position > 1.0) {
          if (!note.hit) {
            _missedNotes++;
            _combo = 0;
            _checkGameOver();
          }
          return true;
        }
        return false;
      });

      // Check if song ended
      if (_gameController.isCompleted) {
        _endGame();
      }
    });
  }

  void _hitNote(int lane) {
    final hitNotes = _notes
        .where((note) =>
            note.lane == lane &&
            !note.hit &&
            note.position >= _hitZoneTop - 0.05 &&
            note.position <= _hitZoneBottom + 0.05)
        .toList();

    if (hitNotes.isNotEmpty) {
      // Hit the closest note
      hitNotes.sort((a, b) => (a.position - _hitZoneTop)
          .abs()
          .compareTo((b.position - _hitZoneTop).abs()));
      final note = hitNotes.first;
      note.hit = true;

      // Calculate score based on timing
      final timing = (note.position - _hitZoneTop).abs();
      int points;
      if (timing < 0.02) {
        points = 100; // Perfect
      } else if (timing < 0.05) {
        points = 50; // Good
      } else {
        points = 25; // OK
      }

      setState(() {
        _score += points * (1 + _combo ~/ 10);
        _combo++;
        _hitNotes++;
        if (_combo > _maxCombo) {
          _maxCombo = _combo;
        }
      });

      _noteController.forward().then((_) => _noteController.reset());

      // Update account stats
      context.read<AccountProvider>().updateStats(achievementsUnlocked: 1);
    } else {
      // Missed
      setState(() {
        _combo = 0;
      });
    }
  }

  void _checkGameOver() {
    if (_missedNotes >= 10) {
      _endGame();
    }
  }

  void _endGame() {
    _gameTimer?.cancel();
    _noteGenerator?.cancel();

    setState(() {
      _isPlaying = false;
      _gameOver = true;
    });

    _showGameOverDialog();
  }

  void _showGameOverDialog() {
    final accuracy = _hitNotes + _missedNotes > 0
        ? ((_hitNotes / (_hitNotes + _missedNotes)) * 100).round()
        : 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D3A),
        title: Text(
          _gameOver ? 'Game Over!' : 'Song Complete!',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Score: $_score',
                style: const TextStyle(color: Colors.yellow, fontSize: 20)),
            Text('Accuracy: $accuracy%',
                style: const TextStyle(color: Colors.green)),
            Text('Max Combo: $_maxCombo',
                style: const TextStyle(color: Colors.orange)),
            Text('Hit Notes: $_hitNotes',
                style: const TextStyle(color: Colors.blue)),
            Text('Missed Notes: $_missedNotes',
                style: const TextStyle(color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Back', style: TextStyle(color: Colors.purple)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startGame();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B1FA2)),
            child:
                const Text('Play Again', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D2D3A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B1FA2),
        title: Text('Rhythm Game - ${_songs[_currentSongIndex]}',
            style: const TextStyle(color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Score: $_score',
                    style: const TextStyle(color: Colors.yellow, fontSize: 16)),
                Text('Combo: $_combo',
                    style: const TextStyle(color: Colors.orange, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Game Stats
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat('Hit', '$_hitNotes', Colors.green),
                _buildStat('Miss', '$_missedNotes', Colors.red),
                _buildStat('Max Combo', '$_maxCombo', Colors.orange),
              ],
            ),
          ),

          // Game Area
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1a1a2e),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Stack(
                children: [
                  // Hit Zone
                  Positioned(
                    top: MediaQuery.of(context).size.height * _hitZoneTop,
                    left: 0,
                    right: 0,
                    height: MediaQuery.of(context).size.height *
                        (_hitZoneBottom - _hitZoneTop),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        border: Border.symmetric(
                          horizontal: BorderSide(
                              color: Colors.green.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                  ),

                  // Notes
                  ..._notes.map((note) => _buildNote(note)),

                  // Lanes
                  ...List.generate(4, (lane) => _buildLane(lane)),
                ],
              ),
            ),
          ),

          // Controls
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!_isPlaying)
                  ElevatedButton(
                    onPressed: _startGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B1FA2),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 16),
                    ),
                    child: const Text('Start Game',
                        style: TextStyle(color: Colors.white)),
                  ),
                ...List.generate(
                  4,
                  (lane) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton(
                        onPressed: _isPlaying ? () => _hitNote(lane) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getLaneColor(lane),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                        ),
                        child: Text(
                          String.fromCharCode(65 + lane), // A, B, C, D
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildLane(int lane) {
    return Positioned(
      top: 0,
      bottom: 0,
      left: MediaQuery.of(context).size.width * (0.125 + lane * 0.25),
      width: MediaQuery.of(context).size.width * 0.25,
      child: Container(
        decoration: BoxDecoration(
          border: Border.symmetric(
            vertical: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
        ),
      ),
    );
  }

  Widget _buildNote(Note note) {
    if (note.hit) return const SizedBox.shrink();

    return Positioned(
      top: MediaQuery.of(context).size.height * note.position,
      left: MediaQuery.of(context).size.width * (0.125 + note.lane * 0.25),
      width: MediaQuery.of(context).size.width * 0.25 - 8,
      child: Center(
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getLaneColor(note.lane),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _getLaneColor(note.lane).withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getLaneColor(int lane) {
    switch (lane) {
      case 0:
        return Colors.red;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 3:
        return Colors.yellow;
      default:
        return Colors.purple;
    }
  }
}

class Note {
  final String id;
  final int lane;
  double position;
  bool hit;

  Note({
    required this.id,
    required this.lane,
    required this.position,
    this.hit = false,
  });
}
