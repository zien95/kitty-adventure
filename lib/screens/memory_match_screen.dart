import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';

class MemoryMatchScreen extends StatefulWidget {
  const MemoryMatchScreen({super.key});

  @override
  State<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryMatchScreenState extends State<MemoryMatchScreen> {
  List<String> _emojis = ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼'];
  List<CardModel> _cards = [];
  int _moves = 0;
  int _matches = 0;
  CardModel? _firstCard;
  CardModel? _secondCard;
  bool _isProcessing = false;
  int _score = 0;
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initializeGame() {
    _cards = [];
    _emojis.forEach((emoji) {
      _cards.add(CardModel(id: _cards.length, emoji: emoji));
      _cards.add(CardModel(id: _cards.length, emoji: emoji));
    });
    _cards.shuffle();
    _moves = 0;
    _matches = 0;
    _score = 0;
    _seconds = 0;
    _firstCard = null;
    _secondCard = null;
    _isProcessing = false;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _onCardTap(CardModel card) {
    if (_isProcessing || card.isFlipped || card.isMatched) return;

    setState(() {
      card.isFlipped = true;
      _moves++;
    });

    if (_firstCard == null) {
      _firstCard = card;
    } else {
      _secondCard = card;
      _isProcessing = true;
      _checkMatch();
    }
  }

  void _checkMatch() {
    if (_firstCard!.emoji == _secondCard!.emoji) {
      // Match found
      setState(() {
        _firstCard!.isMatched = true;
        _secondCard!.isMatched = true;
        _matches++;
        _score += 100;
      });

      // Update account stats
      context.read<AccountProvider>().updateStats(achievementsUnlocked: 1);

      if (_matches == _emojis.length) {
        _timer?.cancel();
        _showWinDialog();
      }

      _resetCards();
    } else {
      // No match
      Future.delayed(const Duration(milliseconds: 1000), () {
        setState(() {
          _firstCard!.isFlipped = false;
          _secondCard!.isFlipped = false;
        });
        _resetCards();
      });
    }
  }

  void _resetCards() {
    _firstCard = null;
    _secondCard = null;
    _isProcessing = false;
  }

  void _showWinDialog() {
    final bonusScore = _seconds < 60
        ? 200
        : _seconds < 120
            ? 100
            : 50;
    final totalScore = _score + bonusScore;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D3A),
        title: const Text('🎉 Congratulations!',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Time: $_seconds seconds',
                style: const TextStyle(color: Colors.white)),
            Text('Moves: $_moves', style: const TextStyle(color: Colors.white)),
            Text('Score: $totalScore',
                style: const TextStyle(color: Colors.yellow)),
            if (bonusScore > 0)
              Text('Time Bonus: $bonusScore',
                  style: const TextStyle(color: Colors.green)),
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
              _initializeGame();
              _startTimer();
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
        title:
            const Text('Memory Match', style: TextStyle(color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Score: $_score',
                    style: const TextStyle(color: Colors.yellow, fontSize: 16)),
                Text('Time: $_seconds',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStat('Moves', '$_moves'),
                _buildStat('Matches', '$_matches/${_emojis.length}'),
                _buildStat('Score', '$_score'),
              ],
            ),
          ),
          // Game Board
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                final card = _cards[index];
                return GestureDetector(
                  onTap: () => _onCardTap(card),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: card.isFlipped || card.isMatched
                          ? const Color(0xFF7B1FA2)
                          : const Color(0xFF4A4A6A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: card.isMatched
                            ? Colors.green
                            : Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: card.isFlipped || card.isMatched
                          ? Text(
                              card.emoji,
                              style: const TextStyle(fontSize: 32),
                            )
                          : const Icon(
                              Icons.help_outline,
                              color: Colors.white,
                              size: 32,
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class CardModel {
  final int id;
  final String emoji;
  bool isFlipped;
  bool isMatched;

  CardModel(
      {required this.id,
      required this.emoji,
      this.isFlipped = false,
      this.isMatched = false});
}
