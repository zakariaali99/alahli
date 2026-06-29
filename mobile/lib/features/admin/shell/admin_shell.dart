import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/providers/providers.dart';

class AdminShell extends ConsumerWidget {
  final Widget child;

  const AdminShell({required this.child, super.key});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location == '/') return 0;
    if (location.startsWith('/athletes')) return 1;
    if (location.startsWith('/approvals')) return 2;
    return 3; // "More" tab for all other sub-features
  }

  void _onItemTapped(int index, BuildContext context) {
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
        // Navigates to a "More" sub-route, or settings as fallback if already there
        final location = GoRouterState.of(context).matchedLocation;
        if (location == '/settings' || location == '/staff' || location == '/reports' || location == '/verify' || location == '/academies' || location == '/coaches' || location == '/subscriptions' || location == '/notifications') {
          // If already inside one of the more sub-routes, go to a menu state
          context.go('/settings');
        } else {
          // Default to settings or a menu page. We'll show settings page as the default "More" page
          context.go('/settings');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Fetch pending badge counts
    final registrationsAsync = ref.watch(registrationsProvider({'status': 'pending'}));
    final subscriptionsAsync = ref.watch(subscriptionsProvider({'status': 'pending'}));

    int pendingCount = 0;
    registrationsAsync.whenData((list) => pendingCount += list.length);
    subscriptionsAsync.whenData((list) => pendingCount += list.length);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkMuted : AppColors.border,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) => _onItemTapped(index, context),
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: isDark ? Colors.white60 : Colors.black45,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: AppStrings.dashboard,
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: AppStrings.athletes,
            ),
            BottomNavigationBarItem(
              icon: Badge(
                label: Text(pendingCount.toString()),
                isLabelVisible: pendingCount > 0,
                child: const Icon(Icons.check_circle_outline),
              ),
              activeIcon: Badge(
                label: Text(pendingCount.toString()),
                isLabelVisible: pendingCount > 0,
                child: const Icon(Icons.check_circle),
              ),
              label: AppStrings.approvals,
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.menu),
              label: AppStrings.more,
            ),
          ],
        ),
      ),
    );
  }
}
