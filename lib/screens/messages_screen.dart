import 'package:flutter/material.dart';
import '../models/message.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<Message> _messages = [];
  MessageCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() {
    setState(() {
      _messages = List.from(defaultMessages);
      _messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  List<Message> get _filteredMessages {
    if (_selectedCategory == null) return _messages;
    return _messages.where((msg) => msg.category == _selectedCategory).toList();
  }

  void _markAsRead(Message message) {
    setState(() {
      message.isRead = true;
    });
  }

  void _deleteMessage(Message message) {
    setState(() {
      _messages.remove(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D2D3A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7B1FA2),
        title: const Text('Messages', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.done_all, color: Colors.white),
            onPressed: () {
              setState(() {
                for (var msg in _messages) {
                  msg.isRead = true;
                }
              });
            },
            tooltip: 'Mark All as Read',
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip(null, 'All'),
                ...MessageCategory.values.map(
                  (category) =>
                      _buildCategoryChip(category, _getCategoryName(category)),
                ),
              ],
            ),
          ),
          // Messages List
          Expanded(
            child: _filteredMessages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredMessages.length,
                    itemBuilder: (context, index) {
                      final message = _filteredMessages[index];
                      return _buildMessageCard(message);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(MessageCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
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

  Widget _buildMessageCard(Message message) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: message.isRead ? const Color(0xFF3D3D4A) : const Color(0xFF4A4A6A),
      child: InkWell(
        onTap: () {
          _markAsRead(message);
          _showMessageDialog(message);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getCategoryIcon(message.category),
                    color: _getCategoryColor(message.category),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: message.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (!message.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF7B1FA2),
                        shape: BoxShape.circle,
                      ),
                    ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white54),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteMessage(message);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                message.content,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (message.sender != null) ...[
                    Text(
                      message.sender!,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    _formatTimestamp(message.timestamp),
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
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
            Icons.mail_outline,
            size: 80,
            color: Colors.white54,
          ),
          const SizedBox(height: 16),
          const Text(
            'No messages',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for updates and notifications',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageDialog(Message message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D3A),
        title: Row(
          children: [
            Icon(
              _getCategoryIcon(message.category),
              color: _getCategoryColor(message.category),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.title,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.sender != null) ...[
              Text(
                'From: ${message.sender}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message.content,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Sent: ${_formatTimestamp(message.timestamp)}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.purple)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(message);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(MessageCategory category) {
    switch (category) {
      case MessageCategory.system:
        return 'System';
      case MessageCategory.achievement:
        return 'Achievements';
      case MessageCategory.social:
        return 'Social';
      case MessageCategory.event:
        return 'Events';
      case MessageCategory.update:
        return 'Updates';
      case MessageCategory.reminder:
        return 'Reminders';
    }
  }

  IconData _getCategoryIcon(MessageCategory category) {
    switch (category) {
      case MessageCategory.system:
        return Icons.info;
      case MessageCategory.achievement:
        return Icons.emoji_events;
      case MessageCategory.social:
        return Icons.people;
      case MessageCategory.event:
        return Icons.event;
      case MessageCategory.update:
        return Icons.system_update;
      case MessageCategory.reminder:
        return Icons.notifications;
    }
  }

  Color _getCategoryColor(MessageCategory category) {
    switch (category) {
      case MessageCategory.system:
        return Colors.blue;
      case MessageCategory.achievement:
        return Colors.amber;
      case MessageCategory.social:
        return Colors.green;
      case MessageCategory.event:
        return Colors.purple;
      case MessageCategory.update:
        return Colors.orange;
      case MessageCategory.reminder:
        return Colors.red;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
