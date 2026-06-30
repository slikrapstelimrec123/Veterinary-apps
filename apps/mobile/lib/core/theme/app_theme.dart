import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF1F4E5F);
  static const Color accent = Color(0xFF6FAF98);
  static const Color background = Color(0xFFF8F6F1);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF1F2933);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: surface,
        background: background,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w800, color: text),
        titleLarge: TextStyle(fontWeight: FontWeight.w800, color: text),
        titleMedium: TextStyle(fontWeight: FontWeight.w700, color: text),
        bodyMedium: TextStyle(color: text, height: 1.35),
      ),
    );
  }
}

