import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF5C7CFA);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFF4B740);
  static const Color danger = Color(0xFFE35D6A);
  static const Color background = Color(0xFFF8F7F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFFDFCFB);
  static const Color textMain = Color(0xFF22252B);
  static const Color textSecondary = Color(0xFF707784);
  static const Color border = Color(0xFFE8EAEE);

  static ThemeData get light {
    final base = GoogleFonts.montserrat();
    return ThemeData(
      useMaterial3: true,
      fontFamily: base.fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: surface,
        background: background,
        error: danger,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textMain,
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardTheme(
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: border),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textTheme: GoogleFonts.montserratTextTheme(
        const TextTheme(
          headlineMedium: TextStyle(fontWeight: FontWeight.w800, color: textMain),
          titleLarge: TextStyle(fontWeight: FontWeight.w800, color: textMain),
          titleMedium: TextStyle(fontWeight: FontWeight.w700, color: textMain),
          bodyMedium: TextStyle(color: textMain, height: 1.35),
          bodySmall: TextStyle(color: textSecondary),
        ),
      ),
    );
  }
}
