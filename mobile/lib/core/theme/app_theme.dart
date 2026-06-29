import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryContainer,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        error: AppColors.destructive,
        onError: AppColors.destructiveForeground,
        surface: AppColors.card,
        onSurface: AppColors.cardForeground,
        surfaceTint: Colors.transparent,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: GoogleFonts.ibmPlexSansArabic().fontFamily,
      textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(ThemeData.light().textTheme),
      cardTheme: CardTheme(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkPrimaryFg,
        primaryContainer: AppColors.darkPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        error: AppColors.destructive,
        onError: AppColors.destructiveForeground,
        surface: AppColors.darkCard,
        onSurface: AppColors.darkForeground,
        surfaceTint: Colors.transparent,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
      fontFamily: GoogleFonts.ibmPlexSansArabic().fontFamily,
      textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(ThemeData.dark().textTheme),
      cardTheme: CardTheme(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.darkMuted, width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkMuted,
        thickness: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkCard,
        foregroundColor: AppColors.darkForeground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
      ),
    );
  }
}
