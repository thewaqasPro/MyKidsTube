import 'package:flutter/material.dart';

/// Authentic YouTube Dark Design System Tokens
class KidColors {
  // YouTube Brand Red & Primary Accents
  static const Color primary = Color(0xFFFF0000);         // YouTube Red (#FF0000)
  static const Color accent = Color(0xFFFF0000);          // YouTube Red
  static const Color red = Color(0xFFFF0000);             // YouTube Red
  static const Color coral = Color(0xFFFF0000);           // Clean Red
  static const Color sun = Color(0xFFFFB300);             // Subtle Amber
  static const Color sky = Color(0xFF3EA6FF);             // YouTube Blue (#3EA6FF)
  static const Color mint = Color(0xFF2BA640);            // Clean YouTube Green
  static const Color violet = Color(0xFFA855F7);          // Bedtime Violet
  static const Color bubblegum = Color(0xFFF472B6);       // Soft Pink

  // Background & Surfaces (Official YouTube Dark Mode)
  static const Color bgDark = Color(0xFF0F0F0F);          // True YouTube Dark Background (#0F0F0F)
  static const Color canvasDark = Color(0xFF0F0F0F);      // Canvas Dark
  static const Color surfaceDark = Color(0xFF212121);     // YouTube Card Surface (#212121)
  static const Color cardDark = Color(0xFF212121);        // YouTube Card Surface (#212121)
  static const Color cardElevated = Color(0xFF282828);    // YouTube Elevated Surface (#282828)
  static const Color borderDark = Color(0xFF303030);      // YouTube Border/Divider (#303030)
  static const Color borderSubtle = Color(0xFF272727);    // Subtle Divider

  // YouTube Category Filter Chips
  static const Color chipUnselectedBg = Color(0xFF272727);
  static const Color chipUnselectedText = Color(0xFFF1F1F1);
  static const Color chipSelectedBg = Color(0xFFFFFFFF);  // Pure White for selected pill (YouTube style)
  static const Color chipSelectedText = Color(0xFF0F0F0F);// Dark text on selected white chip

  // Typography Tokens (YouTube Standards)
  static const Color textLight = Color(0xFFFFFFFF);       // Primary High-Contrast White
  static const Color textMuted = Color(0xFFAAAAAA);       // YouTube Secondary Metadata Gray (#AAAAAA)
  static const Color textTertiary = Color(0xFF717171);    // Subtle Tertiary Gray (#717171)

  // Overlays, Radii & Badges
  static const Color durationBadgeBg = Color(0xCC000000); // 80% Black Duration Badge
  static const Color yellow = Color(0xFFFFB300);          // Amber
  static const Color green = Color(0xFF2BA640);           // Verified Green
  static const Color purple = Color(0xFFA855F7);          // Violet
  static const Color pink = Color(0xFFF472B6);            // Pink
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
            fontSize: 19,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          color: KidColors.cardDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: KidColors.borderDark, width: 0.8),
          ),
        ),
      );
}
