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

  // ─── 背景與 UI 色系（陽光甜點街 — 鄉村明亮風） ───
  static const Color bgPrimary = Color(0xFFFFF5E1);    // 陽光奶油 — 主背景
  static const Color bgSecondary = Color(0xFFFFE4B5);   // 蜂蜜金 — 次背景/面板
  static const Color bgCard = Color(0xFFFFFFFF);        // 純白 — 卡片（清爽浮起）
  static const Color accentPrimary = Color(0xFFE86B30);  // 暖橘紅 — 主強調/CTA
  static const Color accentSecondary = Color(0xFF7B4B2A); // 深木棕 — 次強調/邊框（飽和）
  static const Color textPrimary = Color(0xFF2D1A0E);    // 深焦咖啡 — 主文字
  static const Color textSecondary = Color(0xFF6B4226);  // 焦糖棕 — 次文字（飽和深色）

  // ─── 圓角（加大，更可愛） ───
  static const double radiusSmall = 10.0;
  static const double radiusMedium = 14.0;
  static const double radiusLarge = 20.0;
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
  static const Color stageLocked = Color(0xFF9E9E9E);
  static const Color pathActive = Color(0xFF66BB6A);
  static const Color pathInactive = Color(0xFFBDBDBD);

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

  // ─── 字級系統 ───
  // 常規 8 層級，特效文字（傷害數字、慶祝 emoji 等）維持 inline
  static const double fontDisplayLg = 28.0; // 頁面大標題
  static const double fontDisplayMd = 22.0; // 區塊標題、對話框標題
  static const double fontTitleLg = 18.0;   // 卡片標題、角色名
  static const double fontTitleMd = 16.0;   // 小節標題、按鈕文字
  static const double fontBodyLg = 14.0;    // 主要內文、說明
  static const double fontBodyMd = 12.0;    // 次要內文、標籤
  static const double fontLabelLg = 11.0;   // 徽章、chips、狀態
  static const double fontLabelSm = 9.0;    // 極小註解

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
      fontFamily: 'jf-openhuninn',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: fontDisplayLg,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: fontDisplayMd,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: fontTitleLg,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: fontTitleMd,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(fontSize: fontBodyLg, color: textPrimary),
        bodyMedium: TextStyle(fontSize: fontBodyMd, color: textSecondary),
        labelLarge: TextStyle(
          fontSize: fontLabelLg,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        labelSmall: TextStyle(fontSize: fontLabelSm, color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),
    );
  }
}

/// 預組合 TextStyle 常數，方便 inline 使用
/// 用法：`style: AppTextStyle.displayLg` 或 `.titleMd.copyWith(color: ...)`
class AppTextStyle {
  AppTextStyle._();

  // ─── Display（頁面標題級） ───
  static const displayLg = TextStyle(
    fontSize: AppTheme.fontDisplayLg,
    fontWeight: FontWeight.bold,
    color: AppTheme.textPrimary,
  );
  static const displayMd = TextStyle(
    fontSize: AppTheme.fontDisplayMd,
    fontWeight: FontWeight.bold,
    color: AppTheme.textPrimary,
  );

  // ─── Title（區塊 / 卡片標題級） ───
  static const titleLg = TextStyle(
    fontSize: AppTheme.fontTitleLg,
    fontWeight: FontWeight.bold,
    color: AppTheme.textPrimary,
  );
  static const titleMd = TextStyle(
    fontSize: AppTheme.fontTitleMd,
    fontWeight: FontWeight.w600,
    color: AppTheme.textPrimary,
  );

  // ─── Body（內文級） ───
  static const bodyLg = TextStyle(
    fontSize: AppTheme.fontBodyLg,
    color: AppTheme.textPrimary,
  );
  static const bodyMd = TextStyle(
    fontSize: AppTheme.fontBodyMd,
    color: AppTheme.textSecondary,
  );

  // ─── Label（標籤 / 註解級） ───
  static const labelLg = TextStyle(
    fontSize: AppTheme.fontLabelLg,
    fontWeight: FontWeight.w500,
    color: AppTheme.textSecondary,
  );
  static const labelSm = TextStyle(
    fontSize: AppTheme.fontLabelSm,
    color: AppTheme.textSecondary,
  );
}
