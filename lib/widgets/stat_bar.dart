import 'package:flutter/material.dart';

class StatBar extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const StatBar({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Icon
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),

        // Label
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ),

        // Progress Bar
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                _getProgressColor(value),
              ),
              minHeight: 12,
            ),
          ),
        ),

        // Value
        const SizedBox(width: 12),
        SizedBox(
          width: 36,
          child: Text(
            '$value%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(int value) {
    if (value <= 20) return Colors.red;
    if (value <= 40) return Colors.orange;
    if (value <= 60) return Colors.yellow;
    return color;
  }
}
