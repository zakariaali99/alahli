import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import placeholders for now, we will create these widgets soon.
import '../../features/auth/login_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/card/membership_card_screen.dart';
import '../../features/membership/membership_details_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/home/splash_screen.dart';
import '../../features/home/main_navigation_layout.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    // Stateful Shell Route for Bottom Navigation Bar Tabs
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainNavigationLayout(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/card',
          builder: (context, state) => const MembershipCardScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/membership-details',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MembershipDetailsScreen(),
    ),
  ],
);
