import 'package:flutter/material.dart';

/// 遊戲主題配置
/// 所有顏色、字體、圓角等視覺參數集中管理
class AppTheme {
  AppTheme._();

  // ─── 方塊顏色（從原始 JS GameEngine 移植） ───
  static const Color blockRed = Color(0xFFF87171);
  static const Color blockBlue = Color(0xFF60A5FA);
  static const Color blockGreen = Color(0xFF4ADE80);
  static const Color blockYellow = Color(0xFFFACC15);
  static const Color blockPurple = Color(0xFFA78BFA);
  static const Color blockOrange = Color(0xFFFFA94D);

  static const List<Color> blockColors = [
    blockRed,
    blockBlue,
    blockGreen,
    blockYellow,
    blockPurple,
  ];

  // 方塊內的輔助符號（色盲友善）
  static const List<String> blockSymbols = ['●', '◆', '▲', '■', '★'];

  // ─── 背景與 UI 色系 ───
  static const Color bgPrimary = Color(0xFF1A1A2E);
  static const Color bgSecondary = Color(0xFF16213E);
  static const Color bgCard = Color(0xFF0F3460);
  static const Color accentPrimary = Color(0xFF533483);
  static const Color accentSecondary = Color(0xFFE94560);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);

  // ─── 圓角 ───
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusBlock = 10.0;

  // ─── 方塊尺寸 ───
  static const double blockSize = 56.0;
  static const double blockGap = 4.0;

  // ─── 動畫時長 ───
  static const Duration animSwap = Duration(milliseconds: 150);
  static const Duration animEliminate = Duration(milliseconds: 250);
  static const Duration animDrop = Duration(milliseconds: 300);
  static const Duration animScore = Duration(milliseconds: 600);

  // ─── ThemeData ───
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgPrimary,
      colorScheme: const ColorScheme.dark(
        primary: accentPrimary,
        secondary: accentSecondary,
        surface: bgSecondary,
      ),
      fontFamily: 'NotoSansTC',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPrimary,
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
    );
  }
}
