import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/providers/paginated_providers.dart';
import '../../../core/helpers/ui_helpers.dart';

class AdminShell extends ConsumerWidget {
  final Widget child;

  const AdminShell({required this.child, super.key});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location == '/dashboard') return 0;
    if (location.startsWith('/dashboard/athletes')) return 1;
    if (location.startsWith('/dashboard/approvals')) return 2;
    if (location.startsWith('/dashboard/subscriptions')) return 3;
    if (location.startsWith('/dashboard/academies')) return 4;
    if (location.startsWith('/dashboard/coaches')) return 5;
    if (location.startsWith('/dashboard/packages')) return 6;
    if (location.startsWith('/dashboard/staff')) return 7;
    if (location.startsWith('/dashboard/verify')) return 8;
    if (location.startsWith('/dashboard/reports')) return 9;
    if (location.startsWith('/dashboard/notifications')) return 10;
    if (location.startsWith('/dashboard/settings')) return 11;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    Navigator.pop(context); // Close drawer
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/dashboard/athletes');
        break;
      case 2:
        context.go('/dashboard/approvals');
        break;
      case 3:
        context.go('/dashboard/subscriptions');
        break;
      case 4:
        context.go('/dashboard/academies');
        break;
      case 5:
        context.go('/dashboard/coaches');
        break;
      case 6:
        context.go('/dashboard/packages');
        break;
      case 7:
        context.go('/dashboard/staff');
        break;
      case 8:
        context.go('/dashboard/verify');
        break;
      case 9:
        context.go('/dashboard/reports');
        break;
      case 10:
        context.go('/dashboard/notifications');
        break;
      case 11:
        context.go('/dashboard/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final user = ref.watch(authProvider);

    final registrationsAsync = ref.watch(registrationsProvider(const {'status': 'pending'}));
    final subscriptionsAsync = ref.watch(subscriptionsProvider(SubscriptionFilter(status: 'pending')));

    int pendingCount = 0;
    registrationsAsync.whenData((list) => pendingCount += list.length);
    subscriptionsAsync.whenData((list) => pendingCount += list.length);

    String getRoleLabel(String? role) {
      if (role == 'super_admin') return 'مدير النظام';
      if (role == 'reception') return 'موظف استقبال';
      if (role == 'academy_manager') return 'مدير الأكاديمية';
      return 'مشاهد';
    }

    return Scaffold(
      drawer: Drawer(
        backgroundColor: const Color(0xFF0D1B2A), // Matches the dark sidebar bg
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              left: BorderSide(color: Color(0xFF1B2A4A), width: 1),
            ),
          ),
          child: Column(
            children: [
              // Sidebar Header
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              isDark ? AppColors.darkPrimary : AppColors.primary,
                              (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.5),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'أ',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الأهلي للياقة',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'نظام إدارة الأداء',
                              style: TextStyle(
                                color: Color(0xFF8E9AAF),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(color: Color(0xFF1B2A4A), height: 1),

              // Navigation Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    _SidebarItem(
                      icon: Icons.dashboard_outlined,
                      label: 'لوحة القيادة',
                      isSelected: selectedIndex == 0,
                      onTap: () => _onItemTapped(0, context),
                    ),
                    _SidebarItem(
                      icon: Icons.people_outline,
                      label: 'اللاعبين',
                      isSelected: selectedIndex == 1,
                      onTap: () => _onItemTapped(1, context),
                    ),
                    _SidebarItem(
                      icon: Icons.credit_card_outlined,
                      label: 'الاشتراكات',
                      isSelected: selectedIndex == 3,
                      onTap: () => _onItemTapped(3, context),
                    ),
                    _SidebarItem(
                      icon: Icons.qr_code_scanner_outlined,
                      label: 'الفحص السريع',
                      isSelected: selectedIndex == 8,
                      onTap: () => _onItemTapped(8, context),
                    ),
                    _SidebarItem(
                      icon: Icons.assignment_outlined,
                      label: 'الطلبات الجديدة',
                      isSelected: selectedIndex == 2,
                      badgeCount: pendingCount > 0 ? pendingCount : null,
                      onTap: () => _onItemTapped(2, context),
                    ),
                    _SidebarItem(
                      icon: Icons.business_outlined,
                      label: 'الأكاديميات',
                      isSelected: selectedIndex == 4,
                      onTap: () => _onItemTapped(4, context),
                    ),
                    _SidebarItem(
                      icon: Icons.sports_outlined,
                      label: 'المدربون',
                      isSelected: selectedIndex == 5,
                      onTap: () => _onItemTapped(5, context),
                    ),
                    _SidebarItem(
                      icon: Icons.card_membership_outlined,
                      label: 'الباقات',
                      isSelected: selectedIndex == 6,
                      onTap: () => _onItemTapped(6, context),
                    ),
                    _SidebarItem(
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'الإدارة',
                      isSelected: selectedIndex == 7,
                      onTap: () => _onItemTapped(7, context),
                    ),
                    _SidebarItem(
                      icon: Icons.notifications_none_outlined,
                      label: 'التنبيهات',
                      isSelected: selectedIndex == 10,
                      onTap: () => _onItemTapped(10, context),
                    ),
                    _SidebarItem(
                      icon: Icons.bar_chart_outlined,
                      label: 'التقارير',
                      isSelected: selectedIndex == 9,
                      onTap: () => _onItemTapped(9, context),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFF1B2A4A), height: 1),

              // Bottom section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    _SidebarItem(
                      icon: Icons.settings_outlined,
                      label: 'الإعدادات',
                      isSelected: selectedIndex == 11,
                      onTap: () => _onItemTapped(11, context),
                    ),
                    _SidebarItem(
                      icon: Icons.logout,
                      label: 'تسجيل الخروج',
                      isSelected: false,
                      isDestructive: true,
                      onTap: () {
                        Navigator.pop(context);
                        ref.read(authProvider.notifier).logout();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F1A2C) : Colors.white.withValues(alpha: 0.85),
        elevation: 0,
        scrolledUnderElevation: 1,
        // Profile Info on the right (start in RTL)
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user?.fullNameAr ?? 'المسؤول',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.foreground,
                  ),
                ),
                Text(
                  getRoleLabel(user?.role),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
              backgroundImage: user?.photo != null ? NetworkImage(user!.photo!) : null,
              child: user?.photo == null
                  ? Text(
                      safeInitials(user?.firstNameAr),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDark ? AppColors.darkPrimary : AppColors.primary,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
      body: child,
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badgeCount;
  final bool isDestructive;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeBgColor = const Color(0xFF00288E).withValues(alpha: 0.2);
    final itemColor = isDestructive
        ? AppColors.destructive
        : (isSelected ? Colors.white : const Color(0xFF8E9AAF));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Material(
        color: isSelected ? activeBgColor : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: itemColor,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: itemColor,
                      fontSize: 13.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.normal,
                    ),
                  ),
                ),
                if (badgeCount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.destructive,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
