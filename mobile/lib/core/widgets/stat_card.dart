import 'package:flutter/material.dart';
import 'app_card.dart';
import '../constants/app_colors.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool animate;
  final String? badge;
  final String? trend; // 'up', 'down', or null

  const StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor = AppColors.primary,
    this.animate = true,
    this.badge,
    this.trend,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Try to parse value as number for animation
    final numValue = double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
    final isPercentage = value.contains('%');
    final isCurrency = value.contains('د.ل');

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title & Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Bottom Row: Value/Badge & Trend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (animate && numValue != null)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: numValue),
                        duration: const Duration(milliseconds: 1200),
                        curve: Curves.easeOutCubic,
                        builder: (context, val, child) {
                          String displayValue = isCurrency 
                              ? '${val.toStringAsFixed(0)} د.ل'
                              : isPercentage 
                                  ? '%${val.toInt()}' 
                                  : val.toInt().toString();
                          return Text(
                            displayValue,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : AppColors.foreground,
                              letterSpacing: -0.5,
                            ),
                          );
                        },
                      )
                    else
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.foreground,
                          letterSpacing: -0.5,
                        ),
                      ),
                    if (badge != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        badge!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trend != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: trend == 'up'
                        ? AppColors.secondary.withValues(alpha: 0.1)
                        : AppColors.destructive.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: trend == 'up'
                          ? AppColors.secondary.withValues(alpha: 0.1)
                          : AppColors.destructive.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trend == 'up' ? Icons.trending_up : Icons.trending_down,
                        color: trend == 'up' ? AppColors.secondary : AppColors.destructive,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trend == 'up' ? 'نمو' : 'تراجع',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: trend == 'up' ? AppColors.secondary : AppColors.destructive,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
