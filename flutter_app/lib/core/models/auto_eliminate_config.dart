import 'block.dart';

/// 自動消除階段
enum AutoEliminateStage {
  /// Stage 1: 無自動消除（純手動）
  stage1,

  /// Stage 2: 隨機自動消除 1 顆
  stage2,

  /// Stage 3: 指定顏色消除 1 顆（含備用顏色）
  stage3,
}

/// 消除來源（用於能量倍率計算）
enum EliminationSource {
  /// 玩家手動點擊
  manual,

  /// 自動消除系統
  auto_,

  /// 三消連鎖反應
  chain,
}

/// 自動消除週期升級定義
class AutoIntervalLevel {
  final int level;
  final int intervalMs;
  final int cost; // 金幣

  const AutoIntervalLevel({
    required this.level,
    required this.intervalMs,
    required this.cost,
  });
}

/// 自動消除設定（可序列化持久保存）
class AutoEliminateConfig {
  /// 已解鎖的最高階段
  AutoEliminateStage unlockedStage;

  /// 開關
  bool isEnabled;

  /// 週期升級等級 (0~4)
  int intervalLevel;

  /// Stage 3: 優先消除顏色
  BlockColor? targetColor;

  /// Stage 3: 備用消除顏色（目標色不存在時使用）
  BlockColor? fallbackColor;

  AutoEliminateConfig({
    this.unlockedStage = AutoEliminateStage.stage1,
    this.isEnabled = false,
    this.intervalLevel = 0,
    this.targetColor,
    this.fallbackColor,
  });

  /// 當前週期（毫秒）
  int get intervalMs => intervalLevels[intervalLevel].intervalMs;

  /// 是否已達最高週期等級
  bool get isMaxIntervalLevel => intervalLevel >= intervalLevels.length - 1;

  /// 下一級升級費用（已滿級回傳 -1）
  int get nextUpgradeCost {
    if (isMaxIntervalLevel) return -1;
    return intervalLevels[intervalLevel + 1].cost;
  }

  /// 是否可使用自動消除（已解鎖 stage2+ 且已開啟）
  bool get isAutoActive =>
      isEnabled && unlockedStage.index >= AutoEliminateStage.stage2.index;

  // ─── 週期升級表 ───

  static const List<AutoIntervalLevel> intervalLevels = [
    AutoIntervalLevel(level: 0, intervalMs: 5000, cost: 0),
    AutoIntervalLevel(level: 1, intervalMs: 4000, cost: 500),
    AutoIntervalLevel(level: 2, intervalMs: 3000, cost: 1500),
    AutoIntervalLevel(level: 3, intervalMs: 2500, cost: 3000),
    AutoIntervalLevel(level: 4, intervalMs: 2000, cost: 5000),
  ];

  // ─── 階段解鎖條件（關卡突破） ───

  /// 自動消除解鎖需通關 1-10
  static const String autoEliminateUnlockStage = '1-10';

  /// 自動收成解鎖需通關 1-5
  static const String autoHarvestUnlockStage = '1-5';

  /// @deprecated 改用關卡解鎖，保留向下相容
  static const Map<AutoEliminateStage, int> unlockLevelRequirements = {
    AutoEliminateStage.stage1: 1,
    AutoEliminateStage.stage2: 1,
    AutoEliminateStage.stage3: 15,
  };

  // ─── 能量倍率常數 ───

  /// 自動消除單顆方塊的能量倍率
  static const double autoSingleMultiplier = 0.3;

  /// 自動消除觸發三消連鎖的能量倍率
  static const double autoChainMultiplier = 0.5;

  /// 手動消除的能量倍率
  static const double manualMultiplier = 1.0;

  // ─── 序列化 ───

  Map<String, dynamic> toJson() => {
        'unlockedStage': unlockedStage.index,
        'isEnabled': isEnabled,
        'intervalLevel': intervalLevel,
        'targetColor': targetColor?.index,
        'fallbackColor': fallbackColor?.index,
      };

  factory AutoEliminateConfig.fromJson(Map<String, dynamic> json) {
    return AutoEliminateConfig(
      unlockedStage: AutoEliminateStage
          .values[(json['unlockedStage'] as int?) ?? 0],
      isEnabled: (json['isEnabled'] as bool?) ?? false,
      intervalLevel: (json['intervalLevel'] as int?) ?? 0,
      targetColor: json['targetColor'] != null
          ? BlockColor.values[json['targetColor'] as int]
          : null,
      fallbackColor: json['fallbackColor'] != null
          ? BlockColor.values[json['fallbackColor'] as int]
          : null,
    );
  }
}
