import 'package:flutter/material.dart';
import 'app_card.dart';
import '../constants/app_colors.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool animate;

  const StatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor = AppColors.primary,
    this.animate = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Try to parse value as number for animation
    final numValue = double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
    final isPercentage = value.contains('%');
    final isCurrency = value.contains('د.ل');

    return Stack(
      children: [
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      iconColor.withValues(alpha: 0.2),
                      iconColor.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (animate && numValue != null)
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: numValue),
                        duration: const Duration(seconds: 1),
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
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : AppColors.foreground,
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
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.foreground,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Accent Bar
        Positioned(
          right: 6,
          top: 18,
          bottom: 18,
          child: Container(
            width: 4,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}
