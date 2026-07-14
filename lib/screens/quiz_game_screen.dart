import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../services/sound_service.dart';

class QuizGameScreen extends StatefulWidget {
  const QuizGameScreen({super.key});

  @override
  State<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends State<QuizGameScreen> {
  final SoundService _soundService = SoundService();
  int _currentQuestion = 0;
  int _score = 0;
  int _correctAnswers = 0;
  bool _isAnswered = false;
  int? _selectedAnswer;

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'What should you do when your pet is hungry?',
      'options': ['Play with it', 'Feed it', 'Clean it', 'Sleep'],
      'correct': 1,
    },
    {
      'question': 'How do you increase your pet\'s intelligence?',
      'options': ['Feed it treats', 'Train it', 'Play games', 'Give medicine'],
      'correct': 1,
    },
    {
      'question': 'What does the shower (clean) action do now?',
      'options': [
        'Only cleans',
        'Makes pet happy',
        'Only gives XP',
        'Reduces energy'
      ],
      'correct': 1,
    },
    {
      'question': 'When should you use medicine on your pet?',
      'options': [
        'When hungry',
        'When health is low',
        'When happy',
        'When sleeping'
      ],
      'correct': 1,
    },
    {
      'question': 'What happens at level 10 in the game?',
      'options': [
        'Pet evolves',
        'Get more coins',
        'New game unlocks',
        'Nothing special'
      ],
      'correct': 0,
    },
    {
      'question': 'How do you increase friendship with your pet?',
      'options': ['Feed it', 'Bond with it', 'Train it', 'Clean it'],
      'correct': 1,
    },
    {
      'question': 'What is the best way to increase social stats?',
      'options': [
        'Sleep more',
        'Play and bond',
        'Feed treats',
        'Train intelligence'
      ],
      'correct': 1,
    },
    {
      'question': 'What status do you get at 95% friendship?',
      'options': ['Besties', 'BFF', 'Good Friends', 'Acquaintance'],
      'correct': 1,
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (_currentQuestion >= _questions.length) {
      return _buildResultsScreen();
    }

    final question = _questions[_currentQuestion];

    return Scaffold(
      backgroundColor: const Color(0xFF2D2D3A),
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title:
            const Text('📝 Quiz Game', style: TextStyle(color: Colors.white)),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Score: $_score',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          Container(
            margin: const EdgeInsets.all(16),
            child: LinearProgressIndicator(
              value: (_currentQuestion + 1) / _questions.length,
              backgroundColor: Colors.grey[600],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.indigo),
              minHeight: 8,
            ),
          ),

          // Question
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Question ${_currentQuestion + 1} of ${_questions.length}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF3D3D4A),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              question['question'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 30),

          // Answer options
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: question['options'].length,
              itemBuilder: (context, index) {
                final isCorrect = index == question['correct'];
                final isSelected = index == _selectedAnswer;
                final showResult = _isAnswered;

                Color backgroundColor;
                Color borderColor;

                if (showResult) {
                  if (isCorrect) {
                    backgroundColor = Colors.green.withValues(alpha: 0.3);
                    borderColor = Colors.green;
                  } else if (isSelected && !isCorrect) {
                    backgroundColor = Colors.red.withValues(alpha: 0.3);
                    borderColor = Colors.red;
                  } else {
                    backgroundColor = const Color(0xFF3D3D4A);
                    borderColor = Colors.grey;
                  }
                } else {
                  backgroundColor = isSelected
                      ? Colors.indigo.withValues(alpha: 0.3)
                      : const Color(0xFF3D3D4A);
                  borderColor = isSelected ? Colors.indigo : Colors.grey;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: _isAnswered ? null : () => _selectAnswer(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        border: Border.all(color: borderColor, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: borderColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + index), // A, B, C, D
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              question['options'][index],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (showResult && isCorrect)
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 24),
                          if (showResult && isSelected && !isCorrect)
                            const Icon(Icons.cancel,
                                color: Colors.red, size: 24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Next button
          if (_isAnswered)
            Container(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _currentQuestion < _questions.length - 1
                      ? 'Next Question'
                      : 'See Results',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _selectAnswer(int index) {
    setState(() {
      _selectedAnswer = index;
      _isAnswered = true;
    });

    final question = _questions[_currentQuestion];
    if (index == question['correct']) {
      _score += 10;
      _correctAnswers++;
      _soundService.playSound('level_up');
    } else {
      _soundService.playSound('click');
    }

    // Auto-advance after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _isAnswered) {
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      _currentQuestion++;
      _isAnswered = false;
      _selectedAnswer = null;
    });
  }

  Widget _buildResultsScreen() {
    final percentage = (_correctAnswers / _questions.length * 100).round();
    final gameProvider = context.read<GameProvider>();
    final xpReward = 20 + (_correctAnswers * 5);
    final coinReward = 10 + (_correctAnswers * 2);
    final gemReward = _correctAnswers >= 6 ? 2 : 1;

    // Award rewards
    gameProvider.awardGameRewards(xpReward, gemReward, coinReward);

    return Scaffold(
      backgroundColor: const Color(0xFF2D2D3A),
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: const Text('📝 Quiz Results',
            style: TextStyle(color: Colors.white)),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: const Color(0xFF3D3D4A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      percentage >= 75 ? Icons.emoji_events : Icons.star,
                      color: percentage >= 75 ? Colors.amber : Colors.indigo,
                      size: 80,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        color: percentage >= 75 ? Colors.amber : Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _getPerformanceMessage(percentage),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '$_correctAnswers out of ${_questions.length} correct',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    Text(
                      'Final Score: $_score',
                      style:
                          const TextStyle(color: Colors.yellow, fontSize: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Rewards Earned:',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                '$xpReward XP, $coinReward coins, $gemReward gems',
                style: const TextStyle(color: Colors.yellow, fontSize: 16),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                    ),
                    child: const Text('Exit', style: TextStyle(fontSize: 16)),
                  ),
                  ElevatedButton(
                    onPressed: _resetQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                    ),
                    child: const Text('Play Again',
                        style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPerformanceMessage(int percentage) {
    if (percentage >= 90) return 'Outstanding! 🌟';
    if (percentage >= 75) return 'Excellent! 🎉';
    if (percentage >= 60) return 'Good Job! 👍';
    if (percentage >= 40) return 'Nice Try! 💪';
    return 'Keep Learning! 📚';
  }

  void _resetQuiz() {
    setState(() {
      _currentQuestion = 0;
      _score = 0;
      _correctAnswers = 0;
      _isAnswered = false;
      _selectedAnswer = null;
    });
  }
}
