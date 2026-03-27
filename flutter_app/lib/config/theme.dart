import 'package:flutter/material.dart';

/// 遊戲主題配置
/// 所有顏色、字體、圓角等視覺參數集中管理
class AppTheme {
  AppTheme._();

  // ─── 方塊顏色（貓咪點心屋配色） ───
  static const Color blockCoral = Color(0xFFE8723A);   // 烘焙橘紅 ☀️太陽
  static const Color blockTeal = Color(0xFF5BA4CF);    // 清泉藍 💧水滴
  static const Color blockMint = Color(0xFF6BAF5B);    // 香草綠 🍃葉子
  static const Color blockGold = Color(0xFFF0B0C8);    // 蜜桃粉 ⭐星星
  static const Color blockRose = Color(0xFF9B7EC8);    // 月光紫 🌙月亮

  static const List<Color> blockColors = [
    blockCoral,
    blockTeal,
    blockMint,
    blockGold,
    blockRose,
  ];

  // 方塊內的輔助符號（色盲友善）
  static const List<String> blockSymbols = ['●', '◆', '▲', '■', '★'];

  // ─── 背景與 UI 色系（暖木烘焙坊） ───
  static const Color bgPrimary = Color(0xFFC9A882);    // 烤餅乾色 — 主背景
  static const Color bgSecondary = Color(0xFFB89468);   // 暖木色 — 次背景/面板
  static const Color bgCard = Color(0xFFF2DCC8);        // 奶油杏仁 — 卡片（浮起）
  static const Color accentPrimary = Color(0xFFD4845A);  // 焦糖橘 — 主強調
  static const Color accentSecondary = Color(0xFF8B6F4E); // 巧克力棕 — 次強調
  static const Color textPrimary = Color(0xFF2C1810);    // 濃縮咖啡 — 主文字
  static const Color textSecondary = Color(0xFF5D4037);  // 摩卡 — 次文字

  // ─── 圓角 ───
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusBlock = 14.0;

  // ─── 方塊尺寸 ───
  static const double blockSize = 56.0;
  static const double blockGap = 4.0;

  // ─── 稀有度顏色 ───
  static const Color rarityN = Color(0xFF9E9E9E);
  static const Color rarityR = Color(0xFF42A5F5);
  static const Color raritySR = Color(0xFFAB47BC);
  static const Color raritySSR = Color(0xFFFF8F00);

  static Color rarityColor(String rarity) {
    switch (rarity.toUpperCase()) {
      case 'SSR':
        return raritySSR;
      case 'SR':
        return raritySR;
      case 'R':
        return rarityR;
      default:
        return rarityN;
    }
  }

  static List<Color> rarityGradient(String rarity) {
    switch (rarity.toUpperCase()) {
      case 'SSR':
        return [const Color(0xFFFF8F00), const Color(0xFFFFD54F)];
      case 'SR':
        return [const Color(0xFFAB47BC), const Color(0xFFCE93D8)];
      case 'R':
        return [const Color(0xFF42A5F5), const Color(0xFF90CAF9)];
      default:
        return [const Color(0xFF9E9E9E), const Color(0xFFBDBDBD)];
    }
  }

  // ─── 狀態顏色 ───
  static const Color stageCleared = Color(0xFF4CAF50);
  static const Color stageCurrent = Color(0xFF42A5F5);
  static const Color stageLocked = Color(0xFF616161);
  static const Color pathActive = Color(0xFF66BB6A);
  static const Color pathInactive = Color(0xFF424242);

  // ─── 間距 ───
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 12.0;
  static const double spacingLg = 16.0;
  static const double spacingXl = 24.0;

  // ─── 動畫時長 ───
  static const Duration animSwap = Duration(milliseconds: 150);
  static const Duration animEliminate = Duration(milliseconds: 250);
  static const Duration animDrop = Duration(milliseconds: 300);
  static const Duration animScore = Duration(milliseconds: 600);
  static const Duration animCardAppear = Duration(milliseconds: 200);
  static const Duration animPulse = Duration(milliseconds: 1500);

  // ─── ThemeData ───
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: bgPrimary,
      colorScheme: const ColorScheme.light(
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
