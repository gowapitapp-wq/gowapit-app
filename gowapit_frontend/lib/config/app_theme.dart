import 'package:flutter/material.dart';
import '../design/tokens.dart';

/// Konfigurasi Tema Terpusat Go Wapit App
/// Mengikuti prinsip Apple Photography-First (DESIGN.md) dengan Action Pine tunggal.
abstract class AppTheme {
  AppTheme._();

  // ==================== TEMA TERANG ====================
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppTokens.fontFamily,
      scaffoldBackgroundColor: Colors.transparent, // Menjaga tembusan gradient & logo emboss

      colorScheme: const ColorScheme.light(
        primary: AppTokens.actionPine,
        onPrimary: AppTokens.canvas,
        secondary: AppTokens.actionPineFocus,
        onSecondary: AppTokens.canvas,
        surface: AppTokens.canvas,
        onSurface: AppTokens.ink,
        surfaceContainerHighest: AppTokens.canvasParchment,
        error: AppTokens.statusRed,
        onError: AppTokens.canvas,
        outline: AppTokens.hairlineLight,
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: AppTokens.displayLg,
        displayMedium: AppTokens.displayMd,
        headlineMedium: AppTokens.tagline,
        bodyLarge: AppTokens.bodyStrong,
        bodyMedium: AppTokens.body,
        bodySmall: AppTokens.caption,
        labelLarge: AppTokens.buttonLarge,
        labelMedium: AppTokens.buttonUtility,
        labelSmall: AppTokens.finePrint,
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: AppTokens.ink,
        titleTextStyle: TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppTokens.ink,
          letterSpacing: -0.2,
        ),
      ),

      // Elevated Button Theme (Pill Action Pine)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTokens.actionPine,
          foregroundColor: AppTokens.canvas,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: AppTokens.pill),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: AppTokens.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),

      // Outlined Button Theme (Secondary Ghost Pill)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTokens.actionPine,
          side: const BorderSide(color: AppTokens.actionPine, width: 1),
          shape: RoundedRectangleBorder(borderRadius: AppTokens.pill),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: AppTokens.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppTokens.actionPine,
          shape: RoundedRectangleBorder(borderRadius: AppTokens.pill),
          textStyle: const TextStyle(
            fontFamily: AppTokens.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Card Theme (Hairline border, radius 18, NO shadow)
      cardTheme: CardThemeData(
        color: AppTokens.canvas,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppTokens.r18,
          side: const BorderSide(color: AppTokens.hairlineLight, width: 1),
        ),
      ),

      // Input Decoration Theme (Pill / R18, Hairline, Height 44)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.canvas,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        hintStyle: const TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 15,
          color: AppTokens.inkMuted48,
        ),
        labelStyle: const TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 15,
          color: AppTokens.inkMuted80,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppTokens.pill,
          borderSide: const BorderSide(color: AppTokens.hairlineLight, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppTokens.pill,
          borderSide: const BorderSide(color: AppTokens.actionPine, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppTokens.pill,
          borderSide: const BorderSide(color: AppTokens.statusRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppTokens.pill,
          borderSide: const BorderSide(color: AppTokens.statusRed, width: 1.5),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppTokens.dividerSoft,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // ==================== TEMA GELAP ====================
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppTokens.fontFamily,
      scaffoldBackgroundColor: Colors.transparent, // Menjaga tembusan gradient & logo emboss

      colorScheme: const ColorScheme.dark(
        primary: AppTokens.actionPineDark,
        onPrimary: AppTokens.surfaceBlack,
        secondary: AppTokens.actionPineOnDark,
        onSecondary: AppTokens.surfaceBlack,
        surface: AppTokens.surfaceTile1,
        onSurface: AppTokens.inkOnDark,
        surfaceContainerHighest: AppTokens.surfaceTile2,
        error: AppTokens.statusRed,
        onError: AppTokens.canvas,
        outline: AppTokens.hairlineDark,
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: AppTokens.displayLg,
        displayMedium: AppTokens.displayMd,
        headlineMedium: AppTokens.tagline,
        bodyLarge: AppTokens.bodyStrong,
        bodyMedium: AppTokens.body,
        bodySmall: AppTokens.caption,
        labelLarge: AppTokens.buttonLarge,
        labelMedium: AppTokens.buttonUtility,
        labelSmall: AppTokens.finePrint,
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: AppTokens.inkOnDark,
        titleTextStyle: TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppTokens.inkOnDark,
          letterSpacing: -0.2,
        ),
      ),

      // Elevated Button Theme (Pill Action Pine Dark)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTokens.actionPineDark,
          foregroundColor: AppTokens.surfaceBlack,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: AppTokens.pill),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: AppTokens.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),

      // Outlined Button Theme (Secondary Ghost Pill Dark)
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTokens.actionPineDark,
          side: const BorderSide(color: AppTokens.actionPineDark, width: 1),
          shape: RoundedRectangleBorder(borderRadius: AppTokens.pill),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: AppTokens.fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppTokens.actionPineDark,
          shape: RoundedRectangleBorder(borderRadius: AppTokens.pill),
          textStyle: const TextStyle(
            fontFamily: AppTokens.fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Card Theme (Hairline border, radius 18, NO shadow)
      cardTheme: CardThemeData(
        color: AppTokens.surfaceTile1,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppTokens.r18,
          side: const BorderSide(color: AppTokens.hairlineDark, width: 1),
        ),
      ),

      // Input Decoration Theme (Pill / R18, Hairline, Height 44)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.surfaceTile1,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        hintStyle: const TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 15,
          color: AppTokens.inkMuted48,
        ),
        labelStyle: const TextStyle(
          fontFamily: AppTokens.fontFamily,
          fontSize: 15,
          color: AppTokens.bodyMutedOnDark,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppTokens.pill,
          borderSide: const BorderSide(color: AppTokens.hairlineDark, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppTokens.pill,
          borderSide: const BorderSide(color: AppTokens.actionPineDark, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppTokens.pill,
          borderSide: const BorderSide(color: AppTokens.statusRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppTokens.pill,
          borderSide: const BorderSide(color: AppTokens.statusRed, width: 1.5),
        ),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppTokens.surfaceTile2,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
