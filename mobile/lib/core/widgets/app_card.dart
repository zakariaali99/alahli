import 'dart:ui';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Border? border;
  final bool useGradient;
  final LinearGradient? gradient;

  const AppCard({
    required this.child,
    this.onTap,
    this.padding,
    this.color,
    this.border,
    this.useGradient = false,
    this.gradient,
    super.key,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _yOffsetAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _yOffsetAnimation = Tween<double>(begin: 0.0, end: -4.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Default gradient if useGradient is true
    final defaultGradient = isDark
        ? const LinearGradient(
            colors: [AppColors.darkPrimaryGradientStart, AppColors.darkPrimaryGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final glassBgColor = isDark
        ? const Color(0xFF111B2E).withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.75);

    final glassBorder = Border.all(
      color: isDark
          ? AppColors.darkBorder
          : AppColors.border,
      width: 1.2,
    );

    final glassShadows = isDark
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
            BoxShadow(
              color: const Color(0xFF00288E).withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ];

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        // Apply transform to match the glass-card-hover interactive translation
        return Transform.translate(
          offset: Offset(0, _yOffsetAnimation.value),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: widget.useGradient ? null : (widget.color ?? glassBgColor),
                gradient: widget.useGradient ? (widget.gradient ?? defaultGradient) : null,
                borderRadius: BorderRadius.circular(24),
                border: widget.border ?? (widget.useGradient ? null : glassBorder),
                boxShadow: widget.useGradient
                    ? [
                        BoxShadow(
                          color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : glassShadows,
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  onTap: widget.onTap,
                  onTapDown: widget.onTap != null ? (_) => _animController.forward() : null,
                  onTapUp: widget.onTap != null ? (_) => _animController.reverse() : null,
                  onTapCancel: widget.onTap != null ? () => _animController.reverse() : null,
                  borderRadius: BorderRadius.circular(24),
                  splashColor: (widget.useGradient ? Colors.white : AppColors.primary).withValues(alpha: 0.1),
                  highlightColor: (widget.useGradient ? Colors.white : AppColors.primary).withValues(alpha: 0.05),
                  child: Padding(
                    padding: widget.padding ?? const EdgeInsets.all(16.0),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
