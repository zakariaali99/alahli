import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum SportsBrand {
  alAhly, // Blue
  awsAcademy // Green
}

class AppTheme {
  // Brand 1: Al Ahly Fitness Center Colors (Blue-centric)
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

  // Brand 2: AWS Football Academy Colors (Green-centric)
  static ColorScheme get awsColorScheme => const ColorScheme(
        brightness: Brightness.light,
        primary: Color(0xFF1E7A43),
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF14532D),
        onPrimaryContainer: Color(0xFFA7F3D0),
        secondary: Color(0xFF00204F), // Mix standard primary
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

  static ThemeData themeData(SportsBrand brand) {
    final colorScheme = brand == SportsBrand.alAhly ? alAhlyColorScheme : awsColorScheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(
        TextTheme(
          displayLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: colorScheme.onSurface),
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: colorScheme.onSurface),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: colorScheme.onSurfaceVariant),
          labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: colorScheme.primary),
        ),
      ),
      cardTheme: CardTheme(
        color: colorScheme.surfaceContainerLow,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5), width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
    );
  }
}

// Extra light-weight helper configuration class
extension ColorSchemeExt on ColorScheme {
  Color get surfaceContainerLowest => Colors.white;
  Color get surfaceContainerLow => const Color(0xFFF3F4F5);
  Color get surfaceContainer => const Color(0xFFEDEEEF);
  Color get surfaceContainerHigh => const Color(0xFFE7E8E9);
  Color get surfaceContainerHighest => const Color(0xFFE1E3E4);
}
