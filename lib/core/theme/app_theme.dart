import 'package:flutter/material.dart';

class AppTheme {
  static const Color background = Color(0xFF0B0819);
  static const Color surface = Color(0xFF151230);
  static const Color surfaceHigh = Color(0xFF1E1840);
  static const Color primary = Color(0xFF9F7BFF);
  static const Color primaryDeep = Color(0xFF5B3DD8);
  static const Color accent = Color(0xFF00D4A0);
  static const Color danger = Color(0xFFFF5C7A);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8E6BFF), Color(0xFF5B3DD8)],
  );

  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF151030), Color(0xFF0B0819)],
  );

  static const List<BoxShadow> glow = [
    BoxShadow(
      color: Color(0x599F7BFF),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> softGlow = [
    BoxShadow(
      color: Color(0x2E9F7BFF),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primaryDeep,
      brightness: Brightness.dark,
    ).copyWith(
      primary: primary,
      surface: surface,
      error: danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: Colors.white,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surfaceHigh,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        iconColor: primary,
        prefixIconColor: Colors.white.withValues(alpha: 0.55),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.08),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
      ),
    );
  }
}
