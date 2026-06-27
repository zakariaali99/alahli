import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/card/membership_card_screen.dart';
import '../../features/membership/membership_details_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/profile/profile_screen.dart';
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
import '../../features/admin/admin_shell_screen.dart';
import '../../features/admin/dashboard/admin_dashboard_screen.dart';
import '../../features/admin/subscribers/subscriber_management_screen.dart';
import '../../features/admin/groups/group_management_screen.dart';
import '../../features/admin/accounts/account_management_screen.dart';
import '../../features/admin/notifications/admin_notifications_screen.dart';
import '../../features/admin/sessions/session_management_screen.dart';
import '../../features/admin/financial/financial_dashboard_screen.dart';
import '../../features/admin/performance/trainer_performance_screen.dart';
import '../../features/admin/exercises/exercise_builder_screen.dart';
import '../../features/admin/trainer/trainer_dashboard_screen.dart';
import '../../features/admin/athlete/athlete_detail_screen.dart';
import '../../features/admin/packages/package_management_screen.dart';
import '../../features/admin/staff/staff_management_screen.dart';
import '../models/user_model.dart';
import '../providers/providers.dart';

Page _pageBuilder(Widget child) => CustomTransitionPage(
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.05, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');
final _adminShellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'adminShell');

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _GoRouterNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final status = notifier._status;
      final user = notifier._user;
      final isLoginRoute = state.matchedLocation == '/login';
      final isAdminRoute = state.matchedLocation.startsWith('/admin');

      if (status == AuthStatus.initial) return null;

      if (status == AuthStatus.unauthenticated && !isLoginRoute) {
        return '/login';
      }

      if (status == AuthStatus.authenticated && isLoginRoute) {
        if (user != null && (user.role == 'super_admin' || user.role == 'reception' || user.role == 'trainer')) {
          return '/admin/dashboard';
        }
        return '/';
      }

      if (status == AuthStatus.authenticated && isAdminRoute) {
        if (user != null && (user.role == 'super_admin' || user.role == 'reception' || user.role == 'trainer')) {
          return null;
        }
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _pageBuilder(const LoginScreen()),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainNavigationLayout(child: child);
        },
        routes: [
          GoRoute(path: '/', pageBuilder: (context, state) => _pageBuilder(const HomeScreen())),
          GoRoute(path: '/card', pageBuilder: (context, state) => _pageBuilder(const MembershipCardScreen())),
          GoRoute(path: '/membership-details', pageBuilder: (context, state) => _pageBuilder(const MembershipDetailsScreen())),
          GoRoute(path: '/notifications', pageBuilder: (context, state) => _pageBuilder(const NotificationsScreen())),
          GoRoute(path: '/profile', pageBuilder: (context, state) => _pageBuilder(const ProfileScreen())),
          GoRoute(path: '/settings', pageBuilder: (context, state) => _pageBuilder(const SettingsScreen())),
          GoRoute(path: '/store', pageBuilder: (context, state) => _pageBuilder(const SportsStoreScreen())),
          GoRoute(path: '/coach-profile', pageBuilder: (context, state) => _pageBuilder(const CoachProfileScreen())),
          GoRoute(path: '/progress', pageBuilder: (context, state) => _pageBuilder(const ProgressTrackingScreen())),
          GoRoute(path: '/exercise-schedules', pageBuilder: (context, state) => _pageBuilder(const ExerciseSchedulesScreen())),
          GoRoute(
            path: '/exercise-details',
            pageBuilder: (context, state) => _pageBuilder(
              ExerciseDetailsScreen(exerciseId: int.tryParse(state.uri.queryParameters['id'] ?? '')),
            ),
          ),
          GoRoute(path: '/verify', pageBuilder: (context, state) => _pageBuilder(const SubscriptionVerificationScreen())),
          GoRoute(
            path: '/booking-confirmation',
            pageBuilder: (context, state) => _pageBuilder(
              BookingConfirmationScreen(bookingId: int.tryParse(state.uri.queryParameters['id'] ?? '')),
            ),
          ),
          GoRoute(path: '/help', pageBuilder: (context, state) => _pageBuilder(const HelpCenterScreen())),
        ],
      ),
      ShellRoute(
        navigatorKey: _adminShellNavigatorKey,
        builder: (context, state, child) {
          return AdminShellScreen(child: child);
        },
        routes: [
          GoRoute(path: '/admin/dashboard', pageBuilder: (context, state) => _pageBuilder(const AdminDashboardScreen())),
          GoRoute(path: '/admin/subscribers', pageBuilder: (context, state) => _pageBuilder(const SubscriberManagementScreen())),
          GoRoute(path: '/admin/groups', pageBuilder: (context, state) => _pageBuilder(const GroupManagementScreen())),
          GoRoute(path: '/admin/accounts', pageBuilder: (context, state) => _pageBuilder(const AccountManagementScreen())),
          GoRoute(path: '/admin/notifications', pageBuilder: (context, state) => _pageBuilder(const AdminNotificationsScreen())),
          GoRoute(path: '/admin/sessions', pageBuilder: (context, state) => _pageBuilder(const SessionManagementScreen())),
          GoRoute(path: '/admin/financial', pageBuilder: (context, state) => _pageBuilder(const FinancialDashboardScreen())),
          GoRoute(path: '/admin/performance', pageBuilder: (context, state) => _pageBuilder(const TrainerPerformanceScreen())),
          GoRoute(path: '/admin/exercises', pageBuilder: (context, state) => _pageBuilder(const ExerciseBuilderScreen())),
          GoRoute(path: '/admin/trainer', pageBuilder: (context, state) => _pageBuilder(const TrainerDashboardScreen())),
          GoRoute(path: '/admin/packages', pageBuilder: (context, state) => _pageBuilder(const PackageManagementScreen())),
          GoRoute(
            path: '/admin/athlete/:id',
            pageBuilder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return _pageBuilder(AthleteDetailScreen(athleteId: id));
            },
          ),
          GoRoute(path: '/admin/staff', pageBuilder: (context, state) => _pageBuilder(const StaffManagementScreen())),
        ],
      ),
    ],
  );
});

class _GoRouterNotifier extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;

  AuthStatus get status => _status;
  UserModel? get user => _user;

  _GoRouterNotifier(Ref ref) {
    ref.listen<AuthState>(authStateProvider, (_, next) {
      _status = next.status;
      _user = next.user;
      notifyListeners();
    });
  }
}