import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StatusBadge extends StatefulWidget {
  final String status;

  const StatusBadge({required this.status, super.key});

  @override
  State<StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<StatusBadge> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.status.toLowerCase() == 'pending') {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;
    String label;

    switch (widget.status.toLowerCase()) {
      case 'active':
      case 'approved':
        bgColor = AppColors.secondary.withValues(alpha: 0.15);
        fgColor = AppColors.secondary;
        label = 'نشط';
        break;
      case 'expired':
        bgColor = AppColors.destructive.withValues(alpha: 0.15);
        fgColor = AppColors.destructive;
        label = 'منتهي';
        break;
      case 'inactive':
        bgColor = AppColors.mutedForeground.withValues(alpha: 0.15);
        fgColor = AppColors.mutedForeground;
        label = 'غير نشط';
        break;
      case 'pending':
        bgColor = AppColors.warning.withValues(alpha: 0.15);
        fgColor = AppColors.warning;
        label = 'معلق';
        break;
      case 'rejected':
        bgColor = AppColors.mutedForeground.withValues(alpha: 0.15);
        fgColor = AppColors.mutedForeground;
        label = 'مرفوض';
        break;
      default:
        bgColor = AppColors.border.withValues(alpha: 0.2);
        fgColor = AppColors.mutedForeground;
        label = widget.status;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? bgColor.withValues(alpha: 0.1) : bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fgColor.withValues(alpha: 0.1), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) => Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fgColor.withValues(alpha: widget.status.toLowerCase() == 'pending' ? _pulseAnimation.value : 1.0),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fgColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
