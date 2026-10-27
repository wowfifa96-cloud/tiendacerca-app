// Autor: Roberto
// Paleta de colores y tema visual de la app.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const accent = Color(0xFFD9660B);
  static const accentDark = Color(0xFFC2410C);

  static const background = Color(0xFFF7F5F1);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFEDF0F4);

  static const headerBackground = Color(0xFF20232B);
  static const headerText = Colors.white;

  static const textPrimary = Color(0xFF1C1F26);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);

  static const border = Color(0xFFE7E2DA);

  static const success = Color(0xFF2F8F5B);
  static const successBackground = Color(0xFFE7F5EC);

  static const closed = Color(0xFF8B93A1);
  static const closedBackground = Color(0xFFEEF0F3);

  static const favorite = Color(0xFFE23744);
}

class AppRadius {
  AppRadius._();
  static const card = 16.0;
  static const control = 10.0;
  static const pill = 999.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final headlineFont = GoogleFonts.spaceGrotesk();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        primary: AppColors.accent,
        surface: AppColors.surface,
      ),
      fontFamily: GoogleFonts.notoSans().fontFamily,
      textTheme: TextTheme(
        headlineSmall: headlineFont.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: AppColors.textPrimary,
        ),
        titleLarge: headlineFont.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: 19,
          color: AppColors.textPrimary,
        ),
        titleMedium: headlineFont.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.headerBackground,
        foregroundColor: AppColors.headerText,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
    );
  }
}
