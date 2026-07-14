import 'dart:async';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<GameNotification> _notifications = [];
  final StreamController<GameNotification> _notificationController =
      StreamController<GameNotification>.broadcast();

  Stream<GameNotification> get notificationStream =>
      _notificationController.stream;
  List<GameNotification> get notifications => List.unmodifiable(_notifications);

  void addNotification(GameNotification notification) {
    _notifications.insert(0, notification);
    _notificationController.add(notification);

    // Keep only last 50 notifications
    if (_notifications.length > 50) {
      _notifications.removeRange(50, _notifications.length);
    }
  }

  void markAsRead(String notificationId) {
    final notification = _notifications.firstWhere(
      (n) => n.id == notificationId,
      orElse: () => throw Exception('Notification not found'),
    );
    notification.isRead = true;
  }

  void clearAll() {
    _notifications.clear();
  }

  void clearRead() {
    _notifications.removeWhere((n) => n.isRead);
  }

  // Predefined notification generators
  void showDailyRewardNotification() {
    addNotification(GameNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Daily Reward Available!',
      message: 'Claim your daily reward now!',
      type: NotificationType.reward,
      icon: Icons.card_giftcard,
      color: Colors.amber,
    ));
  }

  void showAchievementNotification(String achievementName) {
    addNotification(GameNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Achievement Unlocked!',
      message: 'You\'ve earned: $achievementName',
      type: NotificationType.achievement,
      icon: Icons.emoji_events,
      color: Colors.orange,
    ));
  }

  void showPetNeedsNotification(String need, String petName) {
    addNotification(GameNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Pet Needs Attention!',
      message: '$petName needs $need',
      type: NotificationType.petCare,
      icon: Icons.pets,
      color: Colors.pink,
    ));
  }

  void showLevelUpNotification(int newLevel, String petName) {
    addNotification(GameNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Level Up!',
      message: '$petName reached level $newLevel!',
      type: NotificationType.levelUp,
      icon: Icons.trending_up,
      color: Colors.green,
    ));
  }

  void showChallengeCompletedNotification(String challengeName, int reward) {
    addNotification(GameNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Challenge Completed!',
      message: 'Completed: $challengeName. Reward: $reward coins',
      type: NotificationType.challenge,
      icon: Icons.task_alt,
      color: Colors.purple,
    ));
  }

  void showFriendNotification(String friendName, String action) {
    addNotification(GameNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Friend Activity',
      message: '$friendName $action',
      type: NotificationType.social,
      icon: Icons.people,
      color: Colors.blue,
    ));
  }

  void showSystemNotification(String title, String message) {
    addNotification(GameNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: NotificationType.system,
      icon: Icons.info,
      color: Colors.grey,
    ));
  }
}

class GameNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final IconData icon;
  final Color color;
  bool isRead;

  GameNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.icon,
    required this.color,
    this.isRead = false,
  }) : timestamp = DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'icon': icon.codePoint,
      'color': color.value,
      'isRead': isRead,
    };
  }

  factory GameNotification.fromJson(Map<String, dynamic> json) {
    final type = NotificationType.values.firstWhere(
      (t) => t.name == json['type'],
      orElse: () => NotificationType.system,
    );

    return GameNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: type,
      icon: _iconForType(type),
      color: Color(json['color']),
      isRead: json['isRead'] ?? false,
    );
  }

  static IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.reward:
        return Icons.card_giftcard;
      case NotificationType.achievement:
        return Icons.emoji_events;
      case NotificationType.petCare:
        return Icons.pets;
      case NotificationType.levelUp:
        return Icons.trending_up;
      case NotificationType.challenge:
        return Icons.task_alt;
      case NotificationType.social:
        return Icons.people;
      case NotificationType.update:
        return Icons.system_update;
      case NotificationType.system:
        return Icons.info;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

enum NotificationType {
  system,
  reward,
  achievement,
  petCare,
  levelUp,
  challenge,
  social,
  update,
}
