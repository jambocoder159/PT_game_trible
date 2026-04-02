/// 遊戲數值配置中心
/// 全局單例，所有遊戲邏輯從這裡讀取數值參數
import 'battle_params.dart';

class BalanceConfig {
  BalanceConfig._();

  static BalanceConfig _instance = BalanceConfig._();
  static BalanceConfig get instance => _instance;

  /// 戰鬥數值參數
  BattleParams battleParams = const BattleParams();

  // Phase 2: 未來在這裡加入更多配置
  // AgentConfigs agentConfigs;
  // StageConfigs stageConfigs;
  // SkillTierConfigs skillTierConfigs;
  // ...

  /// 覆寫整個配置（用於測試或 GM 工具）
  static void override(BalanceConfig config) => _instance = config;

  /// 重置為預設值
  static void reset() => _instance = BalanceConfig._();
}
