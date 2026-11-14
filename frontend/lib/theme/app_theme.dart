import 'package:flutter/material.dart';

class AppTheme {
  // Brand Color Palette
  static const Color primaryEmerald = Color(0xFF0F382C);
  static const Color accentSage = Color(0xFF2E7D32);
  static const Color lightMint = Color(0xFF81C784);
  static const Color backgroundLight = Color(0xFFF4F7F4);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color darkSlate = Color(0xFF1E293B);
  static const Color mutedGrey = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Status Colors
  static const Color warningAmber = Color(0xFFD97706);
  static const Color infoBlue = Color(0xFF2563EB);
  static const Color successGreen = Color(0xFF16A34A);
  static const Color errorRed = Color(0xFFDC2626);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F382C), Color(0xFF1B5E20)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF062118), Color(0xFF0F382C), Color(0xFF1E5642)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // App Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryEmerald,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryEmerald,
        primary: primaryEmerald,
        secondary: accentSage,
        surface: surfaceWhite,
        error: errorRed,
      ),
      fontFamily: 'Roboto',

      // Card Theme
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accentSage, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: errorRed),
        ),
        labelStyle: const TextStyle(color: mutedGrey, fontSize: 14),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryEmerald,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryEmerald.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryEmerald,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: primaryEmerald, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryEmerald,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // Common Box Shadows
  static List<BoxShadow> get subtleShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: primaryEmerald.withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}
