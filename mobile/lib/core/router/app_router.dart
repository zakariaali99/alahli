import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/landing_screen.dart';
import '../../features/auth/register_athlete_screen.dart';
import '../../features/auth/register_parent_screen.dart';
import '../../features/admin/shell/admin_shell.dart';
import '../../features/admin/dashboard/dashboard_screen.dart';
import '../../features/admin/athletes/athletes_list_screen.dart';
import '../../features/admin/athletes/athlete_profile_screen.dart';
import '../../features/admin/athletes/add_athlete_screen.dart';
import '../../features/admin/approvals/approvals_screen.dart';
import '../../features/admin/subscriptions/subscriptions_screen.dart';
import '../../features/admin/subscriptions/add_subscription_screen.dart';
import '../../features/admin/academies/academies_screen.dart';
import '../../features/admin/coaches/coaches_screen.dart';
import '../../features/admin/staff/staff_screen.dart';
import '../../features/admin/reports/reports_screen.dart';
import '../../features/admin/verify/verify_screen.dart';
import '../../features/admin/notifications/notifications_screen.dart';
import '../../features/admin/settings/settings_screen.dart';
import '../../features/admin/packages/packages_screen.dart';
import '../../features/user/shell/user_shell.dart';
import '../../features/user/subscriptions/user_subscription_screen.dart';
import '../../features/user/athletes/user_athlete_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();
final _userShellNavigatorKey = GlobalKey<NavigatorState>();

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
      final isRegistering = state.matchedLocation.startsWith('/register');
      final isLanding = state.matchedLocation == '/';

      if (!isInitialized) {
        return isOnSplash ? null : '/splash';
      }

      if (!isLoggedIn) {
        if (isLoggingIn || isRegistering || isLanding) {
          return null;
        }
        return '/';
      }

      // If logged in
      if (isOnSplash || isLoggingIn || isRegistering || isLanding) {
        final role = authState.role;
        if (role == 'athlete' || role == 'parent') {
          return '/user';
        } else {
          return '/dashboard';
        }
      }

      // Role check for routes
      final role = authState.role;
      final isDashboardRoute = state.matchedLocation.startsWith('/dashboard');
      final isUserRoute = state.matchedLocation.startsWith('/user');

      if (isDashboardRoute && (role == 'athlete' || role == 'parent')) {
        return '/user';
      }
      if (isUserRoute && !(role == 'athlete' || role == 'parent')) {
        return '/dashboard';
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
      GoRoute(
        path: '/',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: '/register/athlete',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegisterAthleteScreen(),
      ),
      GoRoute(
        path: '/register/parent',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const RegisterParentScreen(),
      ),
      
      // Admin Shell Route
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return AdminShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/dashboard/athletes',
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
            path: '/dashboard/approvals',
            builder: (context, state) => const ApprovalsScreen(),
          ),
          GoRoute(
            path: '/dashboard/subscriptions',
            builder: (context, state) => const SubscriptionsScreen(),
            routes: [
              GoRoute(
                path: 'add',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) =>
                    _slideTransitionPage(child: const AddSubscriptionScreen(), state: state),
              ),
            ],
          ),
          GoRoute(
            path: '/dashboard/academies',
            builder: (context, state) => const AcademiesScreen(),
          ),
          GoRoute(
            path: '/dashboard/packages',
            builder: (context, state) => const PackagesScreen(),
          ),
          GoRoute(
            path: '/dashboard/coaches',
            builder: (context, state) => const CoachesScreen(),
          ),
          GoRoute(
            path: '/dashboard/staff',
            builder: (context, state) => const StaffScreen(),
          ),
          GoRoute(
            path: '/dashboard/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/dashboard/verify',
            builder: (context, state) => const VerifyScreen(),
          ),
          GoRoute(
            path: '/dashboard/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/dashboard/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),

      // User Shell Route
      ShellRoute(
        navigatorKey: _userShellNavigatorKey,
        builder: (context, state, child) {
          return UserShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/user',
            builder: (context, state) => const UserSubscriptionScreen(),
          ),
          GoRoute(
            path: '/user/athlete',
            builder: (context, state) => const UserAthleteScreen(),
          ),
        ],
      ),
    ],
  );
});
