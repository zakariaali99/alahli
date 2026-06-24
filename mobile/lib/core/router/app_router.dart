import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/card/membership_card_screen.dart';
import '../../features/membership/membership_details_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/home/splash_screen.dart';
import '../../features/home/main_navigation_layout.dart';
import '../../features/schedules/exercise_schedules_screen.dart';
import '../../features/schedules/exercise_details_screen.dart';
import '../../features/verify/subscription_verification_screen.dart';
import '../../features/coach/coach_profile_screen.dart';
import '../../features/progress/progress_tracking_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/booking/booking_confirmation_screen.dart';
import '../../features/help/help_center_screen.dart';
import '../../features/store/sports_store_screen.dart';
import '../providers/providers.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _GoRouterNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final status = notifier._status;
      final isLoginRoute = state.matchedLocation == '/login';
      final isSplashRoute = state.matchedLocation == '/splash';

      if (status == AuthStatus.initial) return '/splash';

      if (status == AuthStatus.unauthenticated && !isLoginRoute) {
        return '/login';
      }

      if (status == AuthStatus.authenticated && (isLoginRoute || isSplashRoute)) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainNavigationLayout(child: child);
        },
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          GoRoute(path: '/card', builder: (context, state) => const MembershipCardScreen()),
          GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
          GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
        ],
      ),
      GoRoute(
        path: '/membership-details',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MembershipDetailsScreen(),
      ),
      GoRoute(
        path: '/exercise-schedules',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ExerciseSchedulesScreen(),
      ),
      GoRoute(
        path: '/exercise-details',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.uri.queryParameters['id'] ?? '');
          return ExerciseDetailsScreen(exerciseId: id);
        },
      ),
      GoRoute(
        path: '/verify',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SubscriptionVerificationScreen(),
      ),
      GoRoute(
        path: '/coach-profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CoachProfileScreen(),
      ),
      GoRoute(
        path: '/progress',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProgressTrackingScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/booking-confirmation',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.tryParse(state.uri.queryParameters['id'] ?? '');
          return BookingConfirmationScreen(bookingId: id);
        },
      ),
      GoRoute(
        path: '/help',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: '/store',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SportsStoreScreen(),
      ),
    ],
  );
});

class _GoRouterNotifier extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;

  AuthStatus get status => _status;

  _GoRouterNotifier(Ref ref) {
    ref.listen<AuthState>(authStateProvider, (_, next) {
      _status = next.status;
      notifyListeners();
    });
  }
}
