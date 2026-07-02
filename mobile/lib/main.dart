import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/network/connectivity_service.dart';
import 'core/providers/providers.dart';
import 'core/router/app_router.dart';
import 'core/services/push_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/offline_banner.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  final pushService = PushService();
  await pushService.initialize();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (!kDebugMode) {
      debugPrint('[FlutterError] ${details.exception} ${details.stack}');
    }
  };

  ui.PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[PlatformDispatcher] $error $stack');
    return true;
  };

  ErrorWidget.builder = (details) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: kDebugMode
                ? Text(
                    details.exception.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  )
                : const Text(
                    'عذراً، حدث خطأ غير متوقع في النظام',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
          ),
        ),
      );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(
    ProviderScope(
      child: const AlAhlyApp(),
    ),
  );
}

class AlAhlyApp extends ConsumerWidget {
  const AlAhlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? true;

    ref.read(pushServiceProvider).setRouter(router);

    return Stack(
      children: [
        MaterialApp.router(
          title: 'مركز الأهلي الرياضي - الإدارة',
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          locale: const Locale('ar', 'LY'),
          supportedLocales: const [
            Locale('ar', 'LY'),
            Locale('en', 'US'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
        if (!isOnline)
          Positioned(
            top: MediaQuery.of(context).viewPadding.top,
            left: 0,
            right: 0,
            child: const OfflineBanner(),
          ),
      ],
    );
  }
}
