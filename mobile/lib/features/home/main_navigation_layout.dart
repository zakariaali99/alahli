import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainNavigationLayout extends StatelessWidget {
  final Widget child;

  const MainNavigationLayout({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location == '/card') return 1;
    if (location == '/notifications') return 2;
    if (location == '/profile') return 3;
    return 0; // Default to /
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/card');
        break;
      case 2:
        context.go('/notifications');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: Stack(
        children: [
          // Child Screen Content
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 96.0),
              child: child,
            ),
          ),
          // Floating Bottom Navigation Glass Pill Bar
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        context,
                        icon: Icons.home,
                        activeIcon: Icons.home,
                        label: 'الرئيسية',
                        index: 0,
                        currentIndex: selectedIndex,
                      ),
                      _buildNavItem(
                        context,
                        icon: Icons.qr_code_scanner,
                        activeIcon: Icons.qr_code_scanner,
                        label: 'بطاقتي',
                        index: 1,
                        currentIndex: selectedIndex,
                      ),
                      _buildNavItem(
                        context,
                        icon: Icons.notifications,
                        activeIcon: Icons.notifications,
                        label: 'التنبيهات',
                        index: 2,
                        currentIndex: selectedIndex,
                        hasBadge: true,
                      ),
                      _buildNavItem(
                        context,
                        icon: Icons.person,
                        activeIcon: Icons.person,
                        label: 'حسابي',
                        index: 3,
                        currentIndex: selectedIndex,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required int currentIndex,
    bool hasBadge = false,
  }) {
    final theme = Theme.of(context);
    final isActive = index == currentIndex;

    return GestureDetector(
      onTap: () => _onItemTapped(index, context),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.5)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? theme.colorScheme.primary : theme.colorScheme.outline,
                ),
                if (hasBadge)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? theme.colorScheme.primary : theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
