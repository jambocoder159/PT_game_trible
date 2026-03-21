import 'package:flutter/material.dart';

/// 遊戲主題配置
/// 所有顏色、字體、圓角等視覺參數集中管理
class AppTheme {
  AppTheme._();

  // ─── 方塊顏色（Coolors Palette 1 + 微調） ───
  // 原始: ff6f59-254441-43aa8b-b2b09b-ef3054
  // 調整: 254441→3A7D6E（提亮暗青）、B2B09B→D4C96A（飽和卡其）
  static const Color blockCoral = Color(0xFFFF6F59);   // 珊瑚橘紅
  static const Color blockTeal = Color(0xFF2B82D9);    // 天藍（原翡翠青改為藍色，避免與薄荷綠太相近）
  static const Color blockMint = Color(0xFF43AA8B);    // 薄荷綠
  static const Color blockGold = Color(0xFFD4C96A);    // 琥珀金（原 #B2B09B 飽和）
  static const Color blockRose = Color(0xFFEF3054);    // 玫瑰紅

  static const List<Color> blockColors = [
    blockCoral,
    blockTeal,
    blockMint,
    blockGold,
    blockRose,
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
  static const double radiusBlock = 14.0;

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
