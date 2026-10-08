import 'package:flutter/material.dart';

/// WonderKids Bespoke Kid-Friendly Visual Design Tokens
class KidColors {
  // Primary Playful Brand Accents (Warm & Approachable)
  static const Color primary = Color(0xFFFF5E62);         // Wonder Coral (#FF5E62)
  static const Color accent = Color(0xFFFFB300);          // Wonder Sun (#FFB300)
  static const Color red = Color(0xFFFF5E62);             // Friendly Coral Red
  static const Color coral = Color(0xFFFF5E62);           // Warm Playful Coral
  static const Color sun = Color(0xFFFFB300);             // Joyful Sunshine Yellow
  static const Color sky = Color(0xFF38BDF8);             // Electric Sky Sparkle
  static const Color mint = Color(0xFF10B981);            // Nature & Verified Safe Green
  static const Color violet = Color(0xFFA855F7);          // Magic Bedtime Violet
  static const Color bubblegum = Color(0xFFF472B6);       // Cheerful Bubblegum Pink

  // Background & Surfaces (WonderKids Cosmic Night Fort)
  static const Color bgDark = Color(0xFF0B0F19);          // Deep Cosmic Indigo (#0B0F19)
  static const Color canvasDark = Color(0xFF0D1322);      // Atmospheric Canvas (#0D1322)
  static const Color surfaceDark = Color(0xFF151D33);     // Card Surface (#151D33)
  static const Color cardDark = Color(0xFF151D33);        // Rounded Card Base (#151D33)
  static const Color cardElevated = Color(0xFF1D2845);    // Elevated Surface (#1D2845)
  static const Color borderDark = Color(0xFF243052);      // Cosmic Navy Border (#243052)

  // Top Category Filter Chips
  static const Color chipUnselectedBg = Color(0xFF151D33);
  static const Color chipUnselectedText = Color(0xFF94A3B8);
  static const Color chipSelectedBg = Color(0xFF38BDF8);   // Playful Sky Blue for selected
  static const Color chipSelectedText = Color(0xFF0D1322);

  // Typography Tokens
  static const Color textLight = Color(0xFFFFFFFF);       // Pure White Text
  static const Color textMuted = Color(0xFF94A3B8);       // Soft Slate Secondary Text
  static const Color textTertiary = Color(0xFF64748B);    // Dim Slate Text

  // Overlays, Radii & Badges
  static const Color durationBadgeBg = Color(0xDD0B0F19); // Cosmic Translucent Badge
  static const Color yellow = Color(0xFFFFB300);          // Sun Gold
  static const Color green = Color(0xFF10B981);           // Mint Green
  static const Color purple = Color(0xFFA855F7);          // Magic Violet
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
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          color: KidColors.cardDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: KidColors.borderDark, width: 1.2),
          ),
        ),
      );
}
