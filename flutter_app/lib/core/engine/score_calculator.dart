import '../../config/game_modes.dart';
import 'match_detector.dart';

/// 分數計算結果
class ScoreResult {
  final int basePoints;
  final int comboBonus;
  final int milestoneBonus;
  final int totalPoints;

  const ScoreResult({
    required this.basePoints,
    required this.comboBonus,
    required this.milestoneBonus,
    required this.totalPoints,
  });
}

/// 分數計算引擎
/// 從 web/js/GameEngine.js 的計分邏輯移植
class ScoreCalculator {
  /// 計算一次消除的分數
  static ScoreResult calculate({
    required List<MatchResult> matches,
    required int currentCombo,
    required int chainCount,
    required ScoringConfig scoring,
  }) {
    // 基礎分 = 消除方塊數 × 基礎分數
    int eliminatedCount = 0;
    final countedIds = <String>{};
    for (final match in matches) {
      for (final block in match.blocks) {
        if (countedIds.add(block.id)) {
          eliminatedCount++;
        }
      }
    }

    final basePoints = eliminatedCount * scoring.baseScore;

    // Combo 加成 = 基礎分 × 連擊數 × 連擊倍率
    final comboBonus = (basePoints * currentCombo * scoring.comboMultiplier).round();

    // 連鎖加成（同一回合多次消除）
    final chainBonus = chainCount > 1
        ? (basePoints * (chainCount - 1) * scoring.chainMultiplier).round()
        : 0;

    // 里程碑獎勵
    int milestoneBonus = 0;
    if (scoring.comboMilestones.containsKey(currentCombo)) {
      milestoneBonus = scoring.comboMilestones[currentCombo]!;
    }

    final total = basePoints + comboBonus + chainBonus + milestoneBonus;

    return ScoreResult(
      basePoints: basePoints,
      comboBonus: comboBonus + chainBonus,
      milestoneBonus: milestoneBonus,
      totalPoints: total,
    );
  }
}
