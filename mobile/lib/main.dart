import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

// Brand Provider to switch styling between Al Ahly (Blue) and AWS Academy (Green)
final brandProvider = StateProvider<SportsBrand>((ref) => SportsBrand.alAhly);

void main() {
  runApp(
    const ProviderScope(
      child: AlAhlyApp(),
    ),
  );
}

class AlAhlyApp extends ConsumerWidget {
  const AlAhlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBrand = ref.watch(brandProvider);

    return MaterialApp.router(
      title: 'مركز الأهلي الرياضي',
      debugShowCheckedModeBanner: false,
      routerConfig: goRouter,
      theme: AppTheme.themeData(activeBrand),
      locale: const Locale('ar', 'LY'), // Arabic (Libya) locale
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
