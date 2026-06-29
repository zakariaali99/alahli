import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum SportsBrand {
  alAhly,
  awsAcademy
}

class AppTheme {
  static ColorScheme get alAhlyColorScheme => const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFF00204F),
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF1A3668),
        onPrimaryContainer: Color(0xFF87A0D9),
        secondary: Color(0xFF2C694E),
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFAEEECB),
        onSecondaryContainer: Color(0xFF316E52),
        tertiary: Color(0xFF735C00),
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFCBA72F),
        onTertiaryContainer: Color(0xFF4E3D00),
        error: Color(0xFFBA1A1A),
        onError: Colors.white,
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFF93000A),
        surface: Color(0xFFF8F9FA),
        onSurface: Color(0xFF191C1D),
        onSurfaceVariant: Color(0xFF44474F),
        outline: Color(0xFF747780),
        outlineVariant: Color(0xFFC4C6D0),
        shadow: Colors.black12,
      );

  static ColorScheme get alAhlyDarkColorScheme => const ColorScheme(
        brightness: Brightness.dark,
        primary: Color(0xFF87A0D9),
        onPrimary: Color(0xFF001A41),
        primaryContainer: Color(0xFF002966),
        onPrimaryContainer: Color(0xFFB0C4FF),
        secondary: Color(0xFF73D2A8),
        onSecondary: Color(0xFF003824),
        secondaryContainer: Color(0xFF1A523A),
        onSecondaryContainer: Color(0xFFAEEECB),
        tertiary: Color(0xFFF5C542),
        onTertiary: Color(0xFF3B2E00),
        tertiaryContainer: Color(0xFF574400),
        onTertiaryContainer: Color(0xFFFDE070),
        error: Color(0xFFFFB4AB),
        onError: Color(0xFF690005),
        errorContainer: Color(0xFF93000A),
        onErrorContainer: Color(0xFFFFDAD6),
        surface: Color(0xFF121212),
        onSurface: Color(0xFFE2E2E6),
        onSurfaceVariant: Color(0xFFC4C6D0),
        outline: Color(0xFF8E9099),
        outlineVariant: Color(0xFF44474F),
        shadow: Colors.black38,
      );

  static ColorScheme get awsColorScheme => const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFF1E7A43),
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF14532D),
        onPrimaryContainer: Color(0xFFA7F3D0),
        secondary: Color(0xFF00204F),
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFD8E2FF),
        onSecondaryContainer: Color(0xFF001A42),
        tertiary: Color(0xFF735C00),
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFCBA72F),
        onTertiaryContainer: Color(0xFF4E3D00),
        error: Color(0xFFBA1A1A),
        onError: Colors.white,
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFF93000A),
        surface: Color(0xFFF8F9FA),
        onSurface: Color(0xFF191C1D),
        onSurfaceVariant: Color(0xFF44474F),
        outline: Color(0xFF747780),
        outlineVariant: Color(0xFFC4C6D0),
        shadow: Colors.black12,
      );

  static ThemeData themeData(SportsBrand brand, {Brightness brightness = Brightness.light}) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = brand == SportsBrand.alAhly
        ? (isDark ? alAhlyDarkColorScheme : alAhlyColorScheme)
        : (isDark ? awsColorScheme : awsColorScheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(
        TextTheme(
          displayLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: colorScheme.onSurface),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: colorScheme.onSurfaceVariant),
          labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colorScheme.primary),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ),
      cardTheme: CardTheme(
        color: colorScheme.surfaceContainerLow,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5), width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: colorScheme.surface,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        actionsPadding: const EdgeInsets.all(16),
      ),
      dividerTheme: DividerThemeData(
        thickness: 0.5,
        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        space: 1,
      ),
    );
  }
}

extension ColorSchemeExt on ColorScheme {
  Color get surfaceContainerLowest => surface.withValues(alpha: 1.0);
  Color get surfaceContainerLow => surfaceContainerLowest.withValues(alpha: 0.95);
  Color get surfaceContainer => surfaceContainerLowest.withValues(alpha: 0.90);
  Color get surfaceContainerHigh => surfaceContainerLowest.withValues(alpha: 0.85);
  Color get surfaceContainerHighest => surfaceContainerLowest.withValues(alpha: 0.80);
}
