import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  NotificationType? _selectedType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D2D3A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B1FA2),
        title:
            const Text('Notifications', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.done_all, color: Colors.white),
            onPressed: () {
              for (var notification in _notificationService.notifications) {
                _notificationService.markAsRead(notification.id);
              }
              setState(() {});
            },
            tooltip: 'Mark All as Read',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all, color: Colors.white),
            onPressed: () {
              _notificationService.clearAll();
              setState(() {});
            },
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip(null, 'All'),
                ...NotificationType.values.map(
                  (type) => _buildFilterChip(type, _getTypeDisplayName(type)),
                ),
              ],
            ),
          ),

          // Notifications List
          Expanded(
            child: _filteredNotifications.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = _filteredNotifications[index];
                      return _buildNotificationCard(notification);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<GameNotification> get _filteredNotifications {
    if (_selectedType == null) return _notificationService.notifications;
    return _notificationService.notifications
        .where((n) => n.type == _selectedType)
        .toList();
  }

  Widget _buildFilterChip(NotificationType? type, String label) {
    final isSelected = _selectedType == type;
    final count = type == null
        ? _notificationService.notifications.length
        : _notificationService.notifications
            .where((n) => n.type == type)
            .length;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedType = selected ? type : null;
          });
        },
        backgroundColor: const Color(0xFF4A4A6A),
        selectedColor: const Color(0xFF7B1FA2),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
        ),
        side: BorderSide(
          color: isSelected
              ? const Color(0xFF7B1FA2)
              : Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(GameNotification notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: notification.isRead
          ? const Color(0xFF3D3D4A)
          : const Color(0xFF4A4A6A),
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            _notificationService.markAsRead(notification.id);
            setState(() {});
          }
          _showNotificationDialog(notification);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: notification.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      notification.icon,
                      color: notification.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: notification.isRead
                                ? FontWeight.normal
                                : FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF7B1FA2),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    notification.timeAgo,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: notification.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getTypeDisplayName(notification.type),
                      style: TextStyle(
                        color: notification.color,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.white54,
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationDialog(GameNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D3A),
        title: Row(
          children: [
            Icon(
              notification.icon,
              color: notification.color,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                notification.title,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Type: ${_getTypeDisplayName(notification.type)}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              'Time: ${notification.timeAgo}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.purple)),
          ),
        ],
      ),
    );
  }

  String _getTypeDisplayName(NotificationType type) {
    switch (type) {
      case NotificationType.system:
        return 'System';
      case NotificationType.reward:
        return 'Reward';
      case NotificationType.achievement:
        return 'Achievement';
      case NotificationType.petCare:
        return 'Pet Care';
      case NotificationType.levelUp:
        return 'Level Up';
      case NotificationType.challenge:
        return 'Challenge';
      case NotificationType.social:
        return 'Social';
      case NotificationType.update:
        return 'Update';
    }
  }
}
