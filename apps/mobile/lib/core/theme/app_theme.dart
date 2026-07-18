import 'package:flutter/material.dart';

class AppTheme {
  // Lappo brand palette — derived from logo gradient (cyan #52E5C0 → purple #9B87F5)
  static const Color primary = Color(0xFF7B6CF5); // purple from logo
  static const Color accent = Color(0xFF52E5C0); // cyan/mint from logo
  static const Color success = Color(0xFF3ECFB2); // mint-teal
  static const Color warning = Color(0xFFF4B740);
  static const Color danger = Color(0xFFE35D6A);
  static const Color background = Color(0xFFF5F6FF); // very light blue-lavender
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFFAFAFF);
  static const Color textMain = Color(0xFF1A2340); // dark navy from logo bg
  static const Color textSecondary = Color(0xFF6270A0); // blue-grey
  static const Color border = Color(0xFFE2E4F0); // soft blue-grey border

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Montserrat',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: surface,
        error: danger,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textMain,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: border),
        ),
      ),
      dividerTheme: const DividerThemeData(color: border),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: border),
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        titleTextStyle: TextStyle(
          color: textMain,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: TextStyle(color: textSecondary, fontSize: 12),
      ),
      tabBarTheme: const TabBarThemeData(
        labelStyle: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w800, color: textMain),
        titleLarge: TextStyle(fontWeight: FontWeight.w800, color: textMain),
        titleMedium: TextStyle(fontWeight: FontWeight.w700, color: textMain),
        bodyMedium: TextStyle(color: textMain, height: 1.35),
        bodySmall: TextStyle(color: textSecondary),
      ),
    );
  }
}
