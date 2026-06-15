
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primarySeedColor = Color(0xFF6A1B9A);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primarySeedColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textTheme(colorScheme),
      cardTheme: _cardTheme(colorScheme),
      appBarTheme: _appBarTheme(colorScheme),
      elevatedButtonTheme: _elevatedButtonTheme(colorScheme),
      navigationBarTheme: _navigationBarTheme(colorScheme),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primarySeedColor,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textTheme(colorScheme),
      cardTheme: _cardTheme(colorScheme),
      appBarTheme: _appBarTheme(colorScheme),
      elevatedButtonTheme: _elevatedButtonTheme(colorScheme),
      navigationBarTheme: _navigationBarTheme(colorScheme),
    );
  }

  static TextTheme _textTheme(ColorScheme colorScheme) => TextTheme(
        displayLarge: GoogleFonts.poppins(
          fontSize: 57,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
        bodyMedium: GoogleFonts.roboto(
          fontSize: 14,
          color: colorScheme.onSurface,
        ),
      );

  static CardThemeData _cardTheme(ColorScheme colorScheme) => CardThemeData(
        elevation: 4,
        color: colorScheme.surface.withAlpha(204),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      );

  static AppBarTheme _appBarTheme(ColorScheme colorScheme) => AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      );

  static ElevatedButtonThemeData _elevatedButtonTheme(ColorScheme colorScheme) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  static NavigationBarThemeData _navigationBarTheme(ColorScheme colorScheme) =>
      NavigationBarThemeData(
        backgroundColor: colorScheme.surface.withAlpha(230),
        indicatorColor: colorScheme.primary,
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      );
}
