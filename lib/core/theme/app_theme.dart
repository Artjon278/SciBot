import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme Colors
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Colors.white;
  static const Color lightText = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF6B6B6B);
  static const Color lightBorder = Color(0xFFE5E5E5);
  static const Color lightAccent = Color(0xFF2D2D2D);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color darkSurface = Color(0xFF252525);
  static const Color darkText = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFF9A9A9A);
  static const Color darkBorder = Color(0xFF333333);
  static const Color darkAccent = Color(0xFFE5E5E5);

  // ── Semantic Colors ──
  static const Color accentBlue = Color(0xFF4A90D9);
  static const Color accentBlueDark = Color(0xFF5B9FE8);
  static const Color success = Color(0xFF34A853);
  static const Color successDark = Color(0xFF4ABA68);
  static const Color warning = Color(0xFFE8A33D);
  static const Color warningDark = Color(0xFFF0B555);
  static const Color error = Color(0xFFD93025);
  static const Color errorDark = Color(0xFFEF5350);
  static const Color info = Color(0xFF7E57C2);
  static const Color infoDark = Color(0xFF9575CD);

  // ── Gradient Presets ──
  static List<Color> primaryGradient(bool isDark) => isDark
      ? [const Color(0xFF1A3A5C), const Color(0xFF2A1A4E)]
      : [const Color(0xFF4A90D9), const Color(0xFF7E57C2)];

  static List<Color> secondaryGradient(bool isDark) => isDark
      ? [const Color(0xFF1E2A5C), const Color(0xFF3A1A5C)]
      : [const Color(0xFF5C6BC0), const Color(0xFF7E57C2)];

  // ── Helpers ──
  static Color subtleFill(bool isDark) =>
      isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05);

  static Color subtleBorder(bool isDark) =>
      isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08);

  static Color accentColor(bool isDark) => isDark ? accentBlueDark : accentBlue;
  static Color successColor(bool isDark) => isDark ? successDark : success;
  static Color warningColor(bool isDark) => isDark ? warningDark : warning;
  static Color errorColor(bool isDark) => isDark ? errorDark : error;
  static Color infoColor(bool isDark) => isDark ? infoDark : info;

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBackground,
    colorScheme: const ColorScheme.light(
      surface: lightSurface,
      primary: lightAccent,
      onPrimary: Colors.white,
      secondary: lightTextSecondary,
      onSurface: lightText,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: lightBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: lightText),
      titleTextStyle: TextStyle(
        color: lightText,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: lightText,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: lightText,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: lightText,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: lightTextSecondary,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: lightBorder,
      thickness: 1,
    ),
    cardTheme: CardThemeData(
      color: lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: lightBorder),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: const ColorScheme.dark(
      surface: darkSurface,
      primary: darkAccent,
      onPrimary: Colors.black,
      secondary: darkTextSecondary,
      onSurface: darkText,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: darkText),
      titleTextStyle: TextStyle(
        color: darkText,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: darkText,
        letterSpacing: -0.5,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: darkText,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: darkText,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: darkTextSecondary,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: darkBorder,
      thickness: 1,
    ),
    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: darkBorder),
      ),
    ),
  );
}
