import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.textColor,
  });

  factory StatusBadge.active(String label) => StatusBadge(label: label, color: Colors.green);
  factory StatusBadge.inactive(String label) => StatusBadge(label: label, color: Colors.red);
  factory StatusBadge.warning(String label) => StatusBadge(label: label, color: Colors.orange);
  factory StatusBadge.info(String label) => StatusBadge(label: label, color: Colors.blue);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor ?? color,
        ),
      ),
    );
  }
}
