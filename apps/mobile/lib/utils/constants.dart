import 'package:flutter/material.dart';

/// Authentic YouTube / YouTube Kids Visual Design Tokens
class KidColors {
  // Primary YouTube Brand Colors
  static const Color primary = Color(0xFFFF0000);         // YouTube Red (#FF0000)
  static const Color accent = Color(0xFFFF0000);          // YouTube Red
  static const Color red = Color(0xFFFF0000);

  // Background & Surfaces (Dark Mode)
  static const Color bgDark = Color(0xFF0F0F0F);          // True YouTube Deep Black (#0F0F0F)
  static const Color surfaceDark = Color(0xFF222222);     // Secondary Surface (#222222)
  static const Color cardDark = Color(0xFF272727);        // Card Grey (#272727)
  static const Color borderDark = Color(0xFF303030);      // Divider / Border (#303030)

  // Top Category Filter Chips
  static const Color chipUnselectedBg = Color(0xFF272727);
  static const Color chipUnselectedText = Color(0xFFF1F1F1);
  static const Color chipSelectedBg = Color(0xFFF1F1F1);
  static const Color chipSelectedText = Color(0xFF0F0F0F);

  // Typography Tokens
  static const Color textLight = Color(0xFFF1F1F1);       // Primary Text (#F1F1F1)
  static const Color textMuted = Color(0xFFAAAAAA);       // Secondary Metadata (#AAAAAA)

  // Overlays & Badges
  static const Color durationBadgeBg = Color(0xCC000000); // #000000 with 80% opacity
  static const Color yellow = Color(0xFFFFD700);          // Star Gold (#FFD700)
  static const Color green = Color(0xFF2BA640);           // YouTube Success / Download Green
  static const Color purple = Color(0xFF8B5CF6);
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
          surface: KidColors.surfaceDark,
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
