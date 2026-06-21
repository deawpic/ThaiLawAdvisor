import 'package:flutter/material.dart';

class AppColors {
  // Light Mode Colors
  static const Color lightText = Color(0xFF0F172A); // Slate 900
  static const Color lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color lightCard = Colors.white;
  static const Color lightPrimary = Color(0xFF1E3A8A); // Deep Blue
  static const Color lightSecondary = Color(0xFF0F766E); // Teal
  static const Color lightAccent = Color(0xFFD97706); // Amber Gold
  static const Color lightBgElement = Color(0xFFF1F5F9); // Slate 100
  static const Color lightBgSelected = Color(0xFFE2E8F0); // Slate 200
  static const Color lightTextSecondary = Color(0xFF64748B); // Slate 500
  static const Color lightBorder = Color(0xFFCBD5E1); // Slate 300
  static const Color lightSuccess = Color(0xFF10B981); // Emerald 500
  static const Color lightError = Color(0xFFEF4444); // Red 500

  // Dark Mode Colors
  static const Color darkText = Color(0xFFF8FAFC); // Slate 50
  static const Color darkBackground = Color(0xFF0B0F19); // Deep dark slate
  static const Color darkCard = Color(0xFF151F32); // Dark slate card
  static const Color darkPrimary = Color(0xFF3B82F6); // Light Blue
  static const Color darkSecondary = Color(0xFF14B8A6); // Teal
  static const Color darkAccent = Color(0xFFF59E0B); // Amber Gold
  static const Color darkBgElement = Color(0xFF1E293B); // Slate 800
  static const Color darkBgSelected = Color(0xFF334155); // Slate 700
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color darkBorder = Color(0xFF334155); // Slate 700
  static const Color darkSuccess = Color(0xFF34D399); // Emerald 400
  static const Color darkError = Color(0xFFF87171); // Red 400

  // Premium Gradients
  static const LinearGradient lightHeroGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF0F766E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkHeroGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0B0F19)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.lightPrimary,
      scaffoldBackgroundColor: AppColors.lightBackground,
      cardColor: AppColors.lightCard,
      dividerColor: AppColors.lightBorder,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        secondary: AppColors.lightSecondary,
        tertiary: AppColors.lightAccent,
        surface: AppColors.lightCard,
        error: AppColors.lightError,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.lightText, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.lightText, fontSize: 14),
        titleLarge: TextStyle(color: AppColors.lightText, fontWeight: FontWeight.bold, fontSize: 20),
        titleMedium: TextStyle(color: AppColors.lightText, fontWeight: FontWeight.w600, fontSize: 16),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.darkPrimary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardColor: AppColors.darkCard,
      dividerColor: AppColors.darkBorder,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        secondary: AppColors.darkSecondary,
        tertiary: AppColors.darkAccent,
        surface: AppColors.darkCard,
        error: AppColors.darkError,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.darkText, fontSize: 16),
        bodyMedium: TextStyle(color: AppColors.darkText, fontSize: 14),
        titleLarge: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold, fontSize: 20),
        titleMedium: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w600, fontSize: 16),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkCard,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
      ),
    );
  }
}
