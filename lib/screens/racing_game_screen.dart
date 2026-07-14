import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show KeyDownEvent, KeyEvent, KeyRepeatEvent, LogicalKeyboardKey;
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/pet.dart';
import '../services/sound_service.dart';

class RacingGameScreen extends StatefulWidget {
  const RacingGameScreen({super.key});

  @override
  State<RacingGameScreen> createState() => _RacingGameScreenState();
}

class _RacingGameScreenState extends State<RacingGameScreen> {
  final SoundService _soundService = SoundService();
  final FocusNode _raceFocusNode = FocusNode(debugLabel: 'Racing controls');
  double _petPosition = 50.0;
  double _progress = 0.0;
  double _opponentProgress = 0.0;
  bool _isRacing = false;
  bool _raceFinished = false;
  int _tapCount = 0;
  int _level = 1;
  double _opponentSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _startRace();
  }

  @override
  void dispose() {
    _raceFocusNode.dispose();
    super.dispose();
  }

  void _requestRaceFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _raceFocusNode.canRequestFocus) {
        _raceFocusNode.requestFocus();
      }
    });
  }

  void _startRace() {
    setState(() {
      _isRacing = true;
      _raceFinished = false;
      _progress = 0.0;
      _opponentProgress = 0.0;
      _tapCount = 0;
      _opponentSpeed = 1.0 + (_level * 0.2);
    });
    _requestRaceFocus();
    _raceLoop();
  }

  KeyEventResult _handleRaceKey(FocusNode node, KeyEvent event) {
    final isSpace = event.logicalKey == LogicalKeyboardKey.space;
    final shouldAdvance = event is KeyDownEvent || event is KeyRepeatEvent;

    if (isSpace && shouldAdvance) {
      _tap();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _raceLoop() {
    if (!_isRacing || _raceFinished) return;

    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) {
        _updateRace();
        _raceLoop();
      }
    });
  }

  void _updateRace() {
    setState(() {
      // Opponent moves automatically
      _opponentProgress += _opponentSpeed * 0.5;
      if (_opponentProgress > 100) _opponentProgress = 100;

      // Check if opponent finished
      if (_opponentProgress >= 100 && _progress < 100) {
        _raceFinished = true;
        _isRacing = false;
        _showRaceResult(false);
      }
    });
  }

  void _tap() {
    if (!_isRacing || _raceFinished) return;

    setState(() {
      _progress += 2.0;
      _tapCount++;
      _petPosition = 50.0 + (_tapCount % 4) * 10 - 15; // Bobbing effect

      if (_progress > 100) _progress = 100;
    });

    _soundService.playSound('click');

    // Check if player finished
    if (_progress >= 100 && _opponentProgress < 100) {
      setState(() {
        _raceFinished = true;
        _isRacing = false;
      });
      _showRaceResult(true);
    }
  }

  void _showRaceResult(bool won) {
    final gameProvider = context.read<GameProvider>();
    final xpReward = won ? 40 : 15;
    final coinReward = won ? 25 : 10;
    final gemReward = won ? 2 : 1;

    gameProvider.awardGameRewards(xpReward, gemReward, coinReward);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D3A),
        title: Text(
          won ? '🏆 You Won!' : '🏁 Race Over',
          style: TextStyle(
            color: won ? Colors.green : Colors.orange,
            fontSize: 24,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              won
                  ? 'Great racing! You beat the opponent!'
                  : 'Better luck next time!',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Your Hits: $_tapCount',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
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
          if (won)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _nextLevel();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('Next Level',
                  style: TextStyle(color: Colors.white)),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startRace();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _nextLevel() {
    setState(() {
      _level++;
    });
    _startRace();
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.read<GameProvider>();
    final pet = gameProvider.pet;

    return Scaffold(
      backgroundColor: const Color(0xFF87CEEB),
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text('🏃 Racing Game - Level $_level',
            style: const TextStyle(color: Colors.white)),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Hits: $_tapCount',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
      body: Focus(
        focusNode: _raceFocusNode,
        autofocus: true,
        onKeyEvent: _handleRaceKey,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            _requestRaceFocus();
            _tap();
          },
          child: Column(
            children: [
              // Progress bars
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Player progress
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: pet?.type.color ?? Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              pet?.type.emoji ?? '🐾',
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: _progress / 100,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.blue),
                            minHeight: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text('You',
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Opponent progress
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Center(
                            child: Text('🏃', style: TextStyle(fontSize: 20)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: _opponentProgress / 100,
                            backgroundColor: Colors.grey[300],
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(Colors.red),
                            minHeight: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text('Opponent',
                            style:
                                TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),

              // Race track
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.brown[300],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.brown[700]!, width: 4),
                  ),
                  child: Stack(
                    children: [
                      // Track lines
                      ...List.generate(5, (index) {
                        final position = (index + 1) * 20.0;
                        return Positioned(
                          left: position,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 2,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        );
                      }),

                      // Start line
                      Positioned(
                        left: 20,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 4,
                          color: Colors.green,
                        ),
                      ),

                      // Finish line
                      Positioned(
                        right: 20,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 4,
                          color: Colors.red,
                        ),
                      ),

                      // Player pet
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 100),
                        left: 20 +
                            (_progress / 100) *
                                (MediaQuery.of(context).size.width - 80),
                        bottom: 100 + _petPosition,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: pet?.type.color ?? Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              pet?.type.emoji ?? '🐾',
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      ),

                      // Opponent
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 100),
                        left: 20 +
                            (_opponentProgress / 100) *
                                (MediaQuery.of(context).size.width - 80),
                        bottom: 50,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('🏃', style: TextStyle(fontSize: 24)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Instructions
              if (_level == 1 && _tapCount == 0)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'TAP OR PRESS SPACE FAST TO RUN!\nRace against the opponent to the finish line!',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Control area
              Container(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      const Text('Exit Race', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
