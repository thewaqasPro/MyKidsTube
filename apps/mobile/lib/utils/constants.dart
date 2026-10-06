import 'package:flutter/material.dart';

/// YouTube Modern Design System tokens (DESIGN.md)
class KidColors {
  // Primary YouTube Red
  static const Color primary = Color(0xFFFF0000);

  // Backgrounds & Surfaces
  static const Color bgDark = Color(0xFF0F0F0F);       // Deep Black (#0f0f0f)
  static const Color surfaceDark = Color(0xFF272727);  // Card/Button Grey (#272727)
  static const Color cardDark = Color(0xFF272727);     // Card/Button Grey (#272727)
  static const Color borderDark = Color(0xFF3F3F3F);   // Subtle cinematic divider

  // Typography
  static const Color textLight = Color(0xFFFFFFFF);    // Primary White (#ffffff)
  static const Color textMuted = Color(0xFFAAAAAA);    // Secondary Metadata (#aaaaaa)

  // Accents
  static const Color accent = Color(0xFFFF0000);       // YouTube Red
  static const Color yellow = Color(0xFFF59E0B);       // Star Gold
  static const Color green = Color(0xFF2BA640);        // Download Green
  static const Color purple = Color(0xFF8B5CF6);
  static const Color red = Color(0xFFFF0000);
}

class KidTheme {
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: KidColors.bgDark,
        primaryColor: KidColors.primary,
        colorScheme: const ColorScheme.dark(
          primary: KidColors.primary,
          secondary: KidColors.accent,
          surface: KidColors.cardDark,
          onPrimary: Colors.white,
          onSurface: KidColors.textLight,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: KidColors.bgDark,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: KidColors.textLight,
            fontFamily: 'Roboto',
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: KidColors.cardDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: KidColors.borderDark, width: 1.0),
          ),
        ),
      );
}
