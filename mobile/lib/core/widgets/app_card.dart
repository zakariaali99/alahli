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

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
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

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        decoration: BoxDecoration(
          color: widget.useGradient ? null : (widget.color ?? Theme.of(context).cardTheme.color),
          gradient: widget.useGradient ? (widget.gradient ?? defaultGradient) : null,
          borderRadius: BorderRadius.circular(16),
          border: widget.border ?? Border.all(
            color: widget.useGradient 
                ? Colors.transparent 
                : (isDark ? AppColors.darkMuted : AppColors.border.withValues(alpha: 0.5)),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.useGradient 
                  ? (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: widget.onTap != null ? (_) => _animController.forward() : null,
            onTapUp: widget.onTap != null ? (_) => _animController.reverse() : null,
            onTapCancel: widget.onTap != null ? () => _animController.reverse() : null,
            borderRadius: BorderRadius.circular(16),
            splashColor: (widget.useGradient ? Colors.white : AppColors.primary).withValues(alpha: 0.1),
            highlightColor: (widget.useGradient ? Colors.white : AppColors.primary).withValues(alpha: 0.05),
            child: Padding(
              padding: widget.padding ?? const EdgeInsets.all(16.0),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
