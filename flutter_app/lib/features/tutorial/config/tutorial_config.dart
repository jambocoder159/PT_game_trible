/// 教學期間專用參數
class TutorialConfig {
  TutorialConfig._();

  // ─── Phase 1 首頁教學 ───
  static const double energyChargeMultiplier = 3.0;

  // ─── Phase 3 闘關教學 ───
  static const double enemyHpMultiplier = 0.4;
  static const double skillChargeMultiplier = 2.0;
  static const double enemyIntervalMultiplier = 1.5;
  static const int staminaCost = 0;
  static const double expMultiplier = 0.3;

  // ─── 露露（第一位夥伴） ───
  static const String luluAgentId = 'tide';

  // ─── 教學完成獎勵 ───
  static const int rewardGold = 300;
  static const int rewardDiamonds = 20;
  static const int rewardCoffee = 5;
  static const int rewardEnergy = 20;

  // ─── Phase 步驟數（精簡版） ───
  static const int phase0Slides = 3;     // 原 4→3
  static const int phase1PartASteps = 4; // 原 12→4（推門+點擊+三連消+進首頁）
  static const int phase1PartBSteps = 3; // 原 6→3（兌換+製作+去闖關）
  static const int phase3Battles = 1;    // 原 3→1

  // ─── Phase 4 步驟定義（保留給舊玩家向下相容） ───
  static const int phase4Steps = 6;
}
