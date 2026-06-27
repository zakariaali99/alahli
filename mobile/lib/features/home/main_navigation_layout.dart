import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainNavigationLayout extends StatelessWidget {
  final Widget child;

  const MainNavigationLayout({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location == '/membership-details') return 1;
    if (location == '/card') return 2;
    if (location == '/notifications') return 3;
    if (location == '/profile') return 4;
    if (location == '/settings' ||
        location == '/store' ||
        location == '/coach-profile' ||
        location == '/progress' ||
        location == '/exercise-schedules' ||
        location == '/exercise-details' ||
        location == '/verify' ||
        location == '/booking-confirmation' ||
        location == '/help') {
      return 5;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/'); break;
      case 1: context.go('/membership-details'); break;
      case 2: context.go('/card'); break;
      case 3: context.go('/notifications'); break;
      case 4: context.go('/profile'); break;
      case 5: _showMoreMenu(context); break;
    }
  }

  void _showMoreMenu(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المزيد', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _menuItem(ctx, Icons.settings, 'الإعدادات', '/settings'),
            _menuItem(ctx, Icons.store, 'المتجر', '/store'),
            _menuItem(ctx, Icons.person, 'الملف الشخصي للمدرب', '/coach-profile'),
            _menuItem(ctx, Icons.trending_up, 'تقدمي', '/progress'),
            _menuItem(ctx, Icons.calendar_today, 'جدول التمارين', '/exercise-schedules'),
            _menuItem(ctx, Icons.verified, 'التحقق من الاشتراك', '/verify'),
            _menuItem(ctx, Icons.help_outline, 'المساعدة', '/help'),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(BuildContext ctx, IconData icon, String label, String route) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_left),
      onTap: () {
        Navigator.pop(ctx);
        ctx.go(route);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedIndex = _calculateSelectedIndex(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 360;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset + 72),
              child: child,
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: bottomInset + 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: isNarrow ? 6 : 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
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
                      Flexible(child: _buildNavItem(context, icon: Icons.home, activeIcon: Icons.home, label: 'الرئيسية', index: 0, currentIndex: selectedIndex, isNarrow: isNarrow)),
                      Flexible(child: _buildNavItem(context, icon: Icons.card_membership, activeIcon: Icons.card_membership, label: 'الاشتراكات', index: 1, currentIndex: selectedIndex, isNarrow: isNarrow)),
                      Flexible(child: _buildNavItem(context, icon: Icons.qr_code_scanner, activeIcon: Icons.qr_code_scanner, label: 'بطاقتي', index: 2, currentIndex: selectedIndex, isNarrow: isNarrow)),
                      Flexible(child: _buildNavItem(context, icon: Icons.notifications, activeIcon: Icons.notifications, label: 'التنبيهات', index: 3, currentIndex: selectedIndex, hasBadge: true, isNarrow: isNarrow)),
                      Flexible(child: _buildNavItem(context, icon: Icons.person, activeIcon: Icons.person, label: 'حسابي', index: 4, currentIndex: selectedIndex, isNarrow: isNarrow)),
                      Flexible(child: _buildNavItem(context, icon: Icons.more_horiz, activeIcon: Icons.more_horiz, label: 'المزيد', index: 5, currentIndex: selectedIndex, isNarrow: isNarrow)),
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
    bool isNarrow = false,
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
            padding: EdgeInsets.symmetric(horizontal: isNarrow ? 6 : 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.5)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? theme.colorScheme.primary : theme.colorScheme.outline,
                  size: isNarrow ? 18 : 22,
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
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: isNarrow ? 7 : 9,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? theme.colorScheme.primary : theme.colorScheme.outline,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}