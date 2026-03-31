/// 教學期間專用參數
class TutorialConfig {
  TutorialConfig._();

  // ─── Phase 1 首頁教學 ───
  static const double energyChargeMultiplier = 3.0;
  static const int pastriesToMake = 3;

  // ─── Phase 3 闖關教學 ───
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

  // ─── Phase 步驟數 ───
  static const int phase0Slides = 4;
  static const int phase2Slides = 3;
  static const int phase3Battles = 3;

  // ─── Phase 1 步驟定義 ───
  // step 0: 推開店門
  // step 1: 認識方塊（對話 1）
  // step 2: 認識方塊（對話 2 - 五色說明）
  // step 3: 點擊採集 → 等待操作
  // step 4: 點擊成功回饋
  // step 5: 上拖教學 → 等待操作
  // step 6: 上拖成功 → 下拖提示
  // step 7: 下拖教學 → 等待操作
  // step 8: 三連消說明
  // step 9: 三連消 → 等待操作
  // step 10: 三連消成功回饋
  // step 11: 總結 → 完成
  static const int phase1Steps = 12;

  // ─── Phase 4 步驟定義 ───
  // step 0: 隊伍編成
  // step 1: 角色升級
  // step 2: 自動消除
  // step 3: 每日任務
  // step 4: 元氣系統
  // step 5: 教學結束
  static const int phase4Steps = 6;
}
