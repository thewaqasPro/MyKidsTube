import 'package:flutter/material.dart';

class KidColors {
  static const Color primary = Color(0xFF0284C7);      // Sky Blue
  static const Color accent = Color(0xFFF97316);       // Sunset Coral
  static const Color yellow = Color(0xFFF59E0B);       // Sunny Yellow
  static const Color green = Color(0xFF10B981);        // Mint Green
  static const Color purple = Color(0xFF8B5CF6);       // Lavender Purple
  static const Color red = Color(0xFFEF4444);          // Playful Red

  static const Color bgDark = Color(0xFF0B132B);       // Deep Night Sky
  static const Color cardDark = Color(0xFF1C2541);     // Navy Card
  static const Color surfaceDark = Color(0xFF3A506B);  // Muted Slate
  static const Color borderDark = Color(0xFF2E3856);

  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF94A3B8);
}

class KidTheme {
  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
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
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: KidColors.cardDark,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
}
