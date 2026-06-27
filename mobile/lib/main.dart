import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/providers.dart';
import 'core/router/app_router.dart';
import 'core/services/push_service.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  final pushService = PushService();
  await pushService.initialize();

  ErrorWidget.builder = (details) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Text(
        'عذراً، حدث خطأ غير متوقع',
        style: TextStyle(fontSize: 18),
        textAlign: TextAlign.center,
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
      overrides: [
        pushServiceProvider.overrideWithValue(pushService),
      ],
      child: const AlAhlyApp(),
    ),
  );
}

class AlAhlyApp extends ConsumerWidget {
  const AlAhlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBrand = ref.watch(brandProvider);

    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'مركز الأهلي الرياضي',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.themeData(activeBrand),
      darkTheme: AppTheme.themeData(activeBrand, brightness: Brightness.dark),
      themeMode: themeMode,
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
    );
  }
}
