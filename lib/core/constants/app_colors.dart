import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF5148D8);
  static const Color primaryLight = Color(0xFF8B84FF);
  static const Color accent = Color(0xFF00D2FF);

  // Light Theme Palette
  static const Color backgroundLight = Color(0xFFF7F8FC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceSecondaryLight = Color(0xFFF1F2F7);
  static const Color textPrimaryLight = Color(0xFF17181C);
  static const Color textSecondaryLight = Color(0xFF6B6E78);
  static const Color textHintLight = Color(0xFF9A9DA7);
  static const Color borderLight = Color(0xFFE2E4EA);
  static const Color dividerLight = Color(0xFFE9EAF0);

  // Dark Theme Palette
  static const Color backgroundDark = Color(0xFF0F1015);
  static const Color surfaceDark = Color(0xFF181920);
  static const Color surfaceSecondaryDark = Color(0xFF222430);
  static const Color textPrimaryDark = Color(0xFFF5F6FA);
  static const Color textSecondaryDark = Color(0xFFA0A4B0);
  static const Color textHintDark = Color(0xFF626675);
  static const Color borderDark = Color(0xFF2E3140);
  static const Color dividerDark = Color(0xFF252836);

  // Functional / Status
  static const Color success = Color(0xFF22A06B);
  static const Color error = Color(0xFFE5484D);
  static const Color warning = Color(0xFFE5A000);
  static const Color info = Color(0xFF3683DC);

  // AI & Chat UI Specifics
  static const Color userBubble = Color(0xFF6C63FF);
  static const Color aiBubbleLight = Color(0xFFFFFFFF);
  static const Color aiBubbleDark = Color(0xFF1E202B);
  static const Color codeBackgroundDark = Color(0xFF12131A);

  // Voice & Multimedia Indicators
  static const Color waveFormActive = Color(0xFFFF4757);
  static const Color pdfAccent = Color(0xFFFF5252);
  static const Color videoAccent = Color(0xFFFF793F);
  static const Color imageAccent = Color(0xFF2ED573);

  // Utilities
  static const Color online = Color(0xFF22A06B);
  static const Color offline = Color(0xFF9A9DA7);
  static const Color overlay = Color(0x66000000);
  static const Color transparent = Colors.transparent;
}
