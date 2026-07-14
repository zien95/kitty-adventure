import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/account_provider.dart';

class WordPuzzleScreen extends StatefulWidget {
  const WordPuzzleScreen({super.key});

  @override
  State<WordPuzzleScreen> createState() => _WordPuzzleScreenState();
}

class _WordPuzzleScreenState extends State<WordPuzzleScreen> {
  final List<String> _words = [
    'PET',
    'CARE',
    'LOVE',
    'PLAY',
    'FEED',
    'HAPPY',
    'FRIEND',
    'SMILE',
    'DREAM',
    'JOY',
    'HEART',
    'KIND',
    'GENTLE',
    'SWEET',
    'BRIGHT',
    'SHINE'
  ];

  String _currentWord = '';
  List<String> _shuffledLetters = [];
  List<String> _selectedLetters = [];
  int _score = 0;
  int _level = 1;
  int _hints = 3;
  bool _isWon = false;

  @override
  void initState() {
    super.initState();
    _generateNewWord();
  }

  void _generateNewWord() {
    setState(() {
      _currentWord = _words[(_level - 1) % _words.length];
      _shuffledLetters = _currentWord.split('')..shuffle();
      _selectedLetters = [];
      _isWon = false;
    });
  }

  void _onLetterTap(String letter) {
    if (_isWon) return;

    setState(() {
      _selectedLetters.add(letter);
      _shuffledLetters.remove(letter);

      if (_selectedLetters.length == _currentWord.length) {
        final formedWord = _selectedLetters.join('');
        if (formedWord == _currentWord) {
          _isWon = true;
          _score += _level * 100;
          context.read<AccountProvider>().updateStats(achievementsUnlocked: 1);
          _showWinDialog();
        } else {
          Future.delayed(const Duration(milliseconds: 1000), () {
            setState(() {
              _shuffledLetters.addAll(_selectedLetters);
              _shuffledLetters.shuffle();
              _selectedLetters = [];
            });
          });
        }
      }
    });
  }

  void _onSelectedLetterTap(String letter) {
    if (_isWon) return;

    setState(() {
      _selectedLetters.remove(letter);
      _shuffledLetters.insert(0, letter);
    });
  }

  void _useHint() {
    if (_hints > 0 && !_isWon) {
      setState(() {
        _hints--;
        final correctLetter = _currentWord[_selectedLetters.length];
        if (_shuffledLetters.contains(correctLetter)) {
          _shuffledLetters.remove(correctLetter);
          _selectedLetters.add(correctLetter);
        }
      });
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D3A),
        title:
            const Text('🎉 Word Found!', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Word: $_currentWord',
                style: const TextStyle(color: Colors.green, fontSize: 20)),
            Text('Score: +${_level * 100}',
                style: const TextStyle(color: Colors.yellow)),
            Text('Level: $_level', style: const TextStyle(color: Colors.white)),
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
              setState(() {
                _level++;
              });
              _generateNewWord();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B1FA2)),
            child:
                const Text('Next Level', style: TextStyle(color: Colors.white)),
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
        title: const Text('Word Puzzle', style: TextStyle(color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Level: $_level',
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
                Text('Score: $_score',
                    style: const TextStyle(color: Colors.yellow, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats and Hints
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildHintButton(),
                _buildWordLengthHint(),
              ],
            ),
          ),

          // Selected Letters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _currentWord.length,
                (index) => Padding(
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: index < _selectedLetters.length
                          ? const Color(0xFF7B1FA2)
                          : const Color(0xFF4A4A6A),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: index < _selectedLetters.length
                          ? Text(
                              _selectedLetters[index],
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Available Letters
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _shuffledLetters.length,
              itemBuilder: (context, index) {
                final letter = _shuffledLetters[index];
                return GestureDetector(
                  onTap: () => _onLetterTap(letter),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF3D3D4A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: Center(
                      child: Text(
                        letter,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Selected Letters (for removal)
          if (_selectedLetters.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('Tap letters to remove:',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _selectedLetters.map((letter) {
                      return GestureDetector(
                        onTap: () => _onSelectedLetterTap(letter),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7B1FA2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            letter,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 20),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHintButton() {
    return ElevatedButton.icon(
      onPressed: _hints > 0 ? _useHint : null,
      icon: const Icon(Icons.lightbulb_outline),
      label: Text('Hints: $_hints'),
      style: ElevatedButton.styleFrom(
        backgroundColor: _hints > 0 ? Colors.orange : Colors.grey,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildWordLengthHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF4A4A6A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Word length: ${_currentWord.length}',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
