import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminShellScreen extends StatelessWidget {
  final Widget child;

  const AdminShellScreen({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location == '/admin/subscribers') return 1;
    if (location == '/admin/groups') return 2;
    if (location == '/admin/accounts') return 3;
    if (location == '/admin/notifications') return 4;
    if (location.startsWith('/admin/sessions') ||
        location.startsWith('/admin/financial') ||
        location.startsWith('/admin/performance') ||
        location.startsWith('/admin/exercises') ||
        location.startsWith('/admin/trainer') ||
        location.startsWith('/admin/packages') ||
        location.startsWith('/admin/athlete')) {
      return 5;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/admin/dashboard'); break;
      case 1: context.go('/admin/subscribers'); break;
      case 2: context.go('/admin/groups'); break;
      case 3: context.go('/admin/accounts'); break;
      case 4: context.go('/admin/notifications'); break;
      case 5: _showServicesMenu(context); break;
    }
  }

  void _showServicesMenu(BuildContext context) {
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
            Text('الخدمات', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _menuItem(ctx, Icons.card_giftcard, 'باقات الاشتراك', '/admin/packages'),
            _menuItem(ctx, Icons.event, 'الجلسات', '/admin/sessions'),
            _menuItem(ctx, Icons.trending_up, 'التقارير المالية', '/admin/financial'),
            _menuItem(ctx, Icons.fitness_center, 'التمارين', '/admin/exercises'),
            _menuItem(ctx, Icons.person, 'المدربين', '/admin/trainer'),
            _menuItem(ctx, Icons.star, 'أداء المدربين', '/admin/performance'),
            _menuItem(ctx, Icons.people_alt, 'إدارة الموظفين', '/admin/staff'),
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
              padding: EdgeInsets.only(bottom: bottomInset + 80),
              child: child,
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: bottomInset + 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: isNarrow ? 8 : 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5), width: 0.5),
                  boxShadow: [
                    BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Flexible(child: _buildNavItem(context, icon: Icons.dashboard, activeIcon: Icons.dashboard, label: 'لوحة التحكم', index: 0, currentIndex: selectedIndex, isNarrow: isNarrow)),
                    Flexible(child: _buildNavItem(context, icon: Icons.people_outline, activeIcon: Icons.people, label: 'المشتركين', index: 1, currentIndex: selectedIndex, isNarrow: isNarrow)),
                    Flexible(child: _buildNavItem(context, icon: Icons.groups_outlined, activeIcon: Icons.groups, label: 'المجموعات', index: 2, currentIndex: selectedIndex, isNarrow: isNarrow)),
                    Flexible(child: _buildNavItem(context, icon: Icons.admin_panel_settings_outlined, activeIcon: Icons.admin_panel_settings, label: 'الحسابات', index: 3, currentIndex: selectedIndex, isNarrow: isNarrow)),
                    Flexible(child: _buildNavItem(context, icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'الإشعارات', index: 4, currentIndex: selectedIndex, isNarrow: isNarrow)),
                    Flexible(child: _buildNavItem(context, icon: Icons.more_horiz, activeIcon: Icons.more_horiz, label: 'المزيد', index: 5, currentIndex: selectedIndex, isNarrow: isNarrow)),
                  ],
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
            padding: EdgeInsets.symmetric(horizontal: isNarrow ? 8 : 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? theme.colorScheme.secondaryContainer.withValues(alpha: 0.5)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isActive ? activeIcon : icon,
              color: isActive ? theme.colorScheme.primary : theme.colorScheme.outline,
              size: isNarrow ? 20 : 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: isNarrow ? 8 : 10,
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