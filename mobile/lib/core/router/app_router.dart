import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
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
import '../../features/admin/packages/package_management_screen.dart';
import '../../features/admin/staff/staff_management_screen.dart';
import '../../features/admin/athlete/athlete_detail_screen.dart';
import '../../features/admin/approvals/approvals_screen.dart';
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

      if (status == AuthStatus.authenticated) {
        final isAdmin = user != null &&
            (user.role == 'super_admin' ||
                user.role == 'reception' ||
                user.role == 'trainer');
        if (!isAdmin) {
          ref.read(authStateProvider.notifier).logout();
          return '/login';
        }
        if (isLoginRoute || !isAdminRoute) {
          return '/admin/dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _pageBuilder(const LoginScreen()),
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
          GoRoute(path: '/admin/approvals', pageBuilder: (context, state) => _pageBuilder(const ApprovalsScreen())),
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