import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/admin/shell/admin_shell.dart';
import '../../features/admin/dashboard/dashboard_screen.dart';
import '../../features/admin/athletes/athletes_list_screen.dart';
import '../../features/admin/athletes/athlete_profile_screen.dart';
import '../../features/admin/athletes/add_athlete_screen.dart';
import '../../features/admin/approvals/approvals_screen.dart';
import '../../features/admin/subscriptions/subscriptions_screen.dart';
import '../../features/admin/academies/academies_screen.dart';
import '../../features/admin/coaches/coaches_screen.dart';
import '../../features/admin/staff/staff_screen.dart';
import '../../features/admin/reports/reports_screen.dart';
import '../../features/admin/verify/verify_screen.dart';
import '../../features/admin/notifications/notifications_screen.dart';
import '../../features/admin/settings/settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

CustomTransitionPage _slideTransitionPage({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
        child: child,
      );
    },
    child: child,
  );
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final isInitialized = ref.watch(authInitializedProvider);

  return GoRouter(
    initialLocation: '/',
    navigatorKey: _rootNavigatorKey,
    redirect: (context, state) {
      final isLoggedIn = authState != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isOnSplash = state.matchedLocation == '/splash';

      if (!isInitialized) {
        return isOnSplash ? null : '/splash';
      }

      if (!isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) {
        return '/';
      }

      final role = authState.role;
      if (!adminRoles.contains(role)) {
        return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return AdminShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/athletes',
            builder: (context, state) => const AthletesListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) =>
                    _slideTransitionPage(child: const AddAthleteScreen(), state: state),
              ),
              GoRoute(
                path: ':id',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) {
                  final idStr = state.pathParameters['id'];
                  final id = int.tryParse(idStr ?? '') ?? 0;
                  return _slideTransitionPage(
                    child: AthleteProfileScreen(athleteId: id),
                    state: state,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/approvals',
            builder: (context, state) => const ApprovalsScreen(),
          ),
          GoRoute(
            path: '/subscriptions',
            builder: (context, state) => const SubscriptionsScreen(),
          ),
          GoRoute(
            path: '/academies',
            builder: (context, state) => const AcademiesScreen(),
          ),
          GoRoute(
            path: '/coaches',
            builder: (context, state) => const CoachesScreen(),
          ),
          GoRoute(
            path: '/staff',
            builder: (context, state) => const StaffScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/verify',
            builder: (context, state) => const VerifyScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
