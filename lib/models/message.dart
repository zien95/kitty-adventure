class Message {
  final String id;
  final String title;
  final String content;
  final DateTime timestamp;
  final MessageCategory category;
  bool isRead;
  final String? sender;

  Message({
    required this.id,
    required this.title,
    required this.content,
    required this.timestamp,
    required this.category,
    this.isRead = false,
    this.sender,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'category': category.name,
      'isRead': isRead,
      'sender': sender,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      category: MessageCategory.values.firstWhere(
        (cat) => cat.name == json['category'],
        orElse: () => MessageCategory.system,
      ),
      isRead: json['isRead'] ?? false,
      sender: json['sender'],
    );
  }
}

enum MessageCategory {
  system,
  achievement,
  social,
  event,
  update,
  reminder,
}

// Predefined messages for the game
final List<Message> defaultMessages = [
  Message(
    id: 'welcome_back',
    title: 'Welcome Back!',
    content:
        'Your pet missed you! They\'re excited to see you again. Check their stats and give them some love!',
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    category: MessageCategory.system,
    sender: 'Pet Care System',
  ),
  Message(
    id: 'daily_reward',
    title: 'Daily Reward Available!',
    content:
        'You have a daily reward waiting! Come back every day to earn coins and gems.',
    timestamp: DateTime.now().subtract(const Duration(hours: 4)),
    category: MessageCategory.event,
    sender: 'Reward System',
  ),
  Message(
    id: 'new_games',
    title: 'New Mini-Games Added!',
    content:
        'We\'ve added Memory Match and Word Puzzle games! Try them out and compete for high scores!',
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    category: MessageCategory.update,
    sender: 'Game Updates',
  ),
  Message(
    id: 'pet_happiness',
    title: 'Pet Happiness Tip',
    content:
        'Your pet\'s happiness affects their evolution! Keep them happy with regular playtime and treats.',
    timestamp: DateTime.now().subtract(const Duration(days: 2)),
    category: MessageCategory.reminder,
    sender: 'Pet Care Guide',
  ),
  Message(
    id: 'account_benefits',
    title: 'Account Benefits',
    content:
        'Create an account to sync your progress across devices and unlock premium features!',
    timestamp: DateTime.now().subtract(const Duration(days: 3)),
    category: MessageCategory.system,
    sender: 'Account System',
  ),
  Message(
    id: 'achievement_milestone',
    title: 'Achievement Milestone!',
    content:
        'You\'re getting close to unlocking new achievements! Keep playing to reach your goals.',
    timestamp: DateTime.now().subtract(const Duration(days: 4)),
    category: MessageCategory.achievement,
    sender: 'Achievement System',
  ),
  Message(
    id: 'special_event',
    title: 'Weekend Bonus Event!',
    content:
        'This weekend only: Double coins and gems from all mini-games! Don\'t miss out!',
    timestamp: DateTime.now().subtract(const Duration(days: 5)),
    category: MessageCategory.event,
    sender: 'Event Team',
  ),
  Message(
    id: 'pet_evolution',
    title: 'Evolution Progress',
    content:
        'Your pet is growing! Continue taking good care of them to unlock new evolution stages.',
    timestamp: DateTime.now().subtract(const Duration(days: 6)),
    category: MessageCategory.system,
    sender: 'Evolution Guide',
  ),
  Message(
    id: 'social_feature',
    title: 'Social Features Coming Soon!',
    content:
        'Connect with friends, share your pet\'s progress, and compete on leaderboards coming next update!',
    timestamp: DateTime.now().subtract(const Duration(days: 7)),
    category: MessageCategory.social,
    sender: 'Development Team',
  ),
  Message(
    id: 'maintenance_notice',
    title: 'Scheduled Maintenance',
    content:
        'Server maintenance scheduled for tonight. Your local progress will be saved and restored automatically.',
    timestamp: DateTime.now().subtract(const Duration(days: 8)),
    category: MessageCategory.system,
    sender: 'System Admin',
  ),
];
