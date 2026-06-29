import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/providers/paginated_providers.dart';

class AdminShell extends ConsumerWidget {
  final Widget child;

  const AdminShell({required this.child, super.key});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location == '/') return 0;
    if (location.startsWith('/athletes')) return 1;
    if (location.startsWith('/approvals')) return 2;
    if (location.startsWith('/subscriptions') ||
        location.startsWith('/academies') ||
        location.startsWith('/coaches') ||
        location.startsWith('/staff') ||
        location.startsWith('/reports') ||
        location.startsWith('/verify') ||
        location.startsWith('/notifications') ||
        location.startsWith('/settings')) {
      return 3;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context, WidgetRef ref) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/athletes');
        break;
      case 2:
        context.go('/approvals');
        break;
      case 3:
        _showMoreMenu(context, ref);
        break;
    }
  }

  void _showMoreMenu(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.read(authProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _MoreMenuItem(
                  icon: Icons.credit_card,
                  label: 'الاشتراكات',
                  color: AppColors.primary,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/subscriptions');
                  },
                ),
                _MoreMenuItem(
                  icon: Icons.qr_code_scanner,
                  label: 'الفحص السريع (QR)',
                  color: Colors.teal,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/verify');
                  },
                ),
                if (user?.role == 'super_admin') ...[
                  _MoreMenuItem(
                    icon: Icons.business,
                    label: 'الأكاديميات',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.pop(ctx);
                      context.go('/academies');
                    },
                  ),
                  _MoreMenuItem(
                    icon: Icons.card_membership,
                    label: 'الباقات',
                    color: Colors.pink,
                    onTap: () {
                      Navigator.pop(ctx);
                      context.go('/packages');
                    },
                  ),
                  _MoreMenuItem(
                    icon: Icons.sports,
                    label: 'المدربون',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(ctx);
                      context.go('/coaches');
                    },
                  ),
                  _MoreMenuItem(
                    icon: Icons.admin_panel_settings,
                    label: 'الموظفون',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(ctx);
                      context.go('/staff');
                    },
                  ),
                ],
                _MoreMenuItem(
                  icon: Icons.bar_chart,
                  label: 'التقارير',
                  color: Colors.deepPurple,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/reports');
                  },
                ),
                _MoreMenuItem(
                  icon: Icons.notifications_outlined,
                  label: 'التنبيهات',
                  color: Colors.amber.shade700,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/notifications');
                  },
                ),
                _MoreMenuItem(
                  icon: Icons.settings,
                  label: 'الإعدادات',
                  color: Colors.blueGrey,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/settings');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final registrationsAsync = ref.watch(registrationsProvider(const {'status': 'pending'}));
    final subscriptionsAsync = ref.watch(subscriptionsProvider(SubscriptionFilter(status: 'pending')));

    int pendingCount = 0;
    registrationsAsync.whenData((list) => pendingCount += list.length);
    subscriptionsAsync.whenData((list) => pendingCount += list.length);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 80.0), // Space for floating nav bar
          child: child,
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : colorScheme.shadow).withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ColorFilter.mode(
                (isDark ? AppColors.darkCard : colorScheme.surface).withValues(alpha: 0.85),
                BlendMode.srcOver,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _NavTile(
                      icon: Icons.dashboard_outlined,
                      activeIcon: Icons.dashboard,
                      label: 'الرئيسية',
                      isSelected: selectedIndex == 0,
                      color: isDark ? AppColors.darkPrimary : colorScheme.primary,
                      onTap: () => _onItemTapped(0, context, ref),
                    ),
                    _NavTile(
                      icon: Icons.people_outline,
                      activeIcon: Icons.people,
                      label: 'اللاعبون',
                      isSelected: selectedIndex == 1,
                      color: isDark ? AppColors.darkPrimary : colorScheme.primary,
                      onTap: () => _onItemTapped(1, context, ref),
                    ),
                    _NavTile(
                      icon: Icons.check_circle_outline,
                      activeIcon: Icons.check_circle,
                      label: 'الموافقات',
                      isSelected: selectedIndex == 2,
                      color: isDark ? AppColors.darkPrimary : colorScheme.primary,
                      badge: pendingCount,
                      onTap: () => _onItemTapped(2, context, ref),
                    ),
                    _NavTile(
                      icon: Icons.menu,
                      activeIcon: Icons.menu,
                      label: 'المزيد',
                      isSelected: selectedIndex == 3,
                      color: isDark ? AppColors.darkPrimary : colorScheme.primary,
                      onTap: () => _onItemTapped(3, context, ref),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const SizedBox(height: 0),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final Color color;
  final int badge;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              label: Text(badge.toString()),
              isLabelVisible: badge > 0,
              backgroundColor: AppColors.destructive,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Icon(
                  isSelected ? activeIcon : icon,
                  key: ValueKey(isSelected),
                  color: isSelected ? color : color.withValues(alpha: 0.5),
                  size: 24,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
                child: Text(label),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MoreMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MoreMenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      trailing: Icon(
        Icons.chevron_left,
        color: theme.colorScheme.outline,
      ),
      onTap: onTap,
    );
  }
}
