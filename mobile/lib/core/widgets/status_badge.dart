import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;
    String label;

    switch (status.toLowerCase()) {
      case 'active':
      case 'approved':
        bgColor = AppColors.secondary.withValues(alpha: 0.1);
        fgColor = AppColors.secondary;
        label = 'نشط';
        break;
      case 'expired':
        bgColor = AppColors.destructive.withValues(alpha: 0.1);
        fgColor = AppColors.destructive;
        label = 'منتهي';
        break;
      case 'pending':
        bgColor = AppColors.warning.withValues(alpha: 0.1);
        fgColor = AppColors.warning;
        label = 'معلق';
        break;
      case 'rejected':
        bgColor = AppColors.mutedForeground.withValues(alpha: 0.1);
        fgColor = AppColors.mutedForeground;
        label = 'مرفوض';
        break;
      default:
        bgColor = AppColors.border.withValues(alpha: 0.2);
        fgColor = AppColors.mutedForeground;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fgColor.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fgColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
