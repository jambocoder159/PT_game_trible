/// 戰鬥數值參數
/// 集中管理所有戰鬥引擎中的數值常數，方便調整平衡
import '../core/models/cat_agent.dart';

class BattleParams {
  // ── 消除與連擊 ──
  final double matchDamageBonusPerBlock;       // 每多消 1 個方塊增加的傷害比例
  final double comboBonusPerCombo;             // 每 combo 增加的傷害比例
  final double matchDamageCoefficient;         // 消除傷害係數（atk * matchCount * 屬性 * 此值）
  final int noAgentMatchDamage;                // 無對應角色時，每個方塊造成的固定傷害

  // ── 反擊與斬殺 ──
  final double counterDamageMultiplier;        // 反擊傷害倍率（atk * 此值）
  final double executeThresholdBase;           // 斬殺基礎門檻（敵人血量百分比）
  final double executeBonusMultiplier;         // 斬殺額外傷害倍率

  // ── 混合攻擊系統 ──
  final double baseAttackCoefficient;          // 非配對角色的傷害係數
  final double colorMatchBonus;                // 配對角色的傷害倍率
  final double baseAttackComboCap;             // 基礎攻擊的 combo 倍率上限

  // ── 屬性剋制 ──
  final double attributeAdvantageMultiplier;   // 剋制時的傷害倍率
  final double attributeDisadvantageMultiplier; // 被剋時的傷害倍率

  // ── 效果持續時間 ──
  final int shieldDefaultDuration;             // 護盾預設持續回合
  final int dotDefaultDuration;                // DoT 預設持續回合
  final int defBreakDefaultDuration;           // 破防預設持續回合
  final int delaySkillTurns;                   // 延遲技能增加的回合數

  // ── 被動門檻 ──
  final double lowHpThreshold;                 // 低血量增傷觸發門檻
  final double lowEnemyHpThreshold;            // 攻擊低血敵人加成門檻
  final double emergencyHealThreshold;         // 急救觸發門檻
  final int longChainThreshold;                // 長連鎖加成門檻（方塊數）

  // ── 經驗曲線 ──
  final int expBasePerLevel;                   // 每級基礎 EXP
  final int expGrowthPerLevel;                 // 每級 EXP 增量

  // ── 等級上限 ──
  final Map<AgentRarity, int> maxLevelByRarity;

  // ── 技能預設 ──
  final double defaultLevelScaling;            // 技能每級倍率增量預設值

  const BattleParams({
    this.matchDamageBonusPerBlock = 0.2,
    this.comboBonusPerCombo = 0.1,
    this.matchDamageCoefficient = 0.5,
    this.noAgentMatchDamage = 5,
    this.baseAttackCoefficient = 0.5,
    this.colorMatchBonus = 1.8,
    this.baseAttackComboCap = 1.3,
    this.counterDamageMultiplier = 0.5,
    this.executeThresholdBase = 0.3,
    this.executeBonusMultiplier = 1.5,
    this.attributeAdvantageMultiplier = 1.5,
    this.attributeDisadvantageMultiplier = 0.75,
    this.shieldDefaultDuration = 2,
    this.dotDefaultDuration = 2,
    this.defBreakDefaultDuration = 2,
    this.delaySkillTurns = 2,
    this.lowHpThreshold = 0.25,
    this.lowEnemyHpThreshold = 0.5,
    this.emergencyHealThreshold = 0.4,
    this.longChainThreshold = 5,
    this.expBasePerLevel = 10,
    this.expGrowthPerLevel = 5,
    this.maxLevelByRarity = const {
      AgentRarity.n: 30,
      AgentRarity.r: 40,
      AgentRarity.sr: 50,
      AgentRarity.ssr: 50,
    },
    this.defaultLevelScaling = 0.05,
  });

  factory BattleParams.fromJson(Map<String, dynamic> json) {
    return BattleParams(
      matchDamageBonusPerBlock: (json['matchDamageBonusPerBlock'] as num?)?.toDouble() ?? 0.2,
      comboBonusPerCombo: (json['comboBonusPerCombo'] as num?)?.toDouble() ?? 0.1,
      matchDamageCoefficient: (json['matchDamageCoefficient'] as num?)?.toDouble() ?? 0.5,
      noAgentMatchDamage: (json['noAgentMatchDamage'] as num?)?.toInt() ?? 5,
      baseAttackCoefficient: (json['baseAttackCoefficient'] as num?)?.toDouble() ?? 0.5,
      colorMatchBonus: (json['colorMatchBonus'] as num?)?.toDouble() ?? 1.8,
      baseAttackComboCap: (json['baseAttackComboCap'] as num?)?.toDouble() ?? 1.3,
      counterDamageMultiplier: (json['counterDamageMultiplier'] as num?)?.toDouble() ?? 0.5,
      executeThresholdBase: (json['executeThresholdBase'] as num?)?.toDouble() ?? 0.3,
      executeBonusMultiplier: (json['executeBonusMultiplier'] as num?)?.toDouble() ?? 1.5,
      attributeAdvantageMultiplier: (json['attributeAdvantageMultiplier'] as num?)?.toDouble() ?? 1.5,
      attributeDisadvantageMultiplier: (json['attributeDisadvantageMultiplier'] as num?)?.toDouble() ?? 0.75,
      shieldDefaultDuration: (json['shieldDefaultDuration'] as num?)?.toInt() ?? 2,
      dotDefaultDuration: (json['dotDefaultDuration'] as num?)?.toInt() ?? 2,
      defBreakDefaultDuration: (json['defBreakDefaultDuration'] as num?)?.toInt() ?? 2,
      delaySkillTurns: (json['delaySkillTurns'] as num?)?.toInt() ?? 2,
      lowHpThreshold: (json['lowHpThreshold'] as num?)?.toDouble() ?? 0.25,
      lowEnemyHpThreshold: (json['lowEnemyHpThreshold'] as num?)?.toDouble() ?? 0.5,
      emergencyHealThreshold: (json['emergencyHealThreshold'] as num?)?.toDouble() ?? 0.4,
      longChainThreshold: (json['longChainThreshold'] as num?)?.toInt() ?? 5,
      expBasePerLevel: (json['expBasePerLevel'] as num?)?.toInt() ?? 10,
      expGrowthPerLevel: (json['expGrowthPerLevel'] as num?)?.toInt() ?? 5,
      maxLevelByRarity: _parseMaxLevels(json['maxLevelByRarity'] as Map<String, dynamic>?),
      defaultLevelScaling: (json['defaultLevelScaling'] as num?)?.toDouble() ?? 0.05,
    );
  }

  static Map<AgentRarity, int> _parseMaxLevels(Map<String, dynamic>? json) {
    if (json == null) {
      return const {
        AgentRarity.n: 30,
        AgentRarity.r: 40,
        AgentRarity.sr: 50,
        AgentRarity.ssr: 50,
      };
    }
    return {
      AgentRarity.n: (json['n'] as num?)?.toInt() ?? 30,
      AgentRarity.r: (json['r'] as num?)?.toInt() ?? 40,
      AgentRarity.sr: (json['sr'] as num?)?.toInt() ?? 50,
      AgentRarity.ssr: (json['ssr'] as num?)?.toInt() ?? 50,
    };
  }

  Map<String, dynamic> toJson() => {
    'matchDamageBonusPerBlock': matchDamageBonusPerBlock,
    'comboBonusPerCombo': comboBonusPerCombo,
    'matchDamageCoefficient': matchDamageCoefficient,
    'noAgentMatchDamage': noAgentMatchDamage,
    'baseAttackCoefficient': baseAttackCoefficient,
    'colorMatchBonus': colorMatchBonus,
    'baseAttackComboCap': baseAttackComboCap,
    'counterDamageMultiplier': counterDamageMultiplier,
    'executeThresholdBase': executeThresholdBase,
    'executeBonusMultiplier': executeBonusMultiplier,
    'attributeAdvantageMultiplier': attributeAdvantageMultiplier,
    'attributeDisadvantageMultiplier': attributeDisadvantageMultiplier,
    'shieldDefaultDuration': shieldDefaultDuration,
    'dotDefaultDuration': dotDefaultDuration,
    'defBreakDefaultDuration': defBreakDefaultDuration,
    'delaySkillTurns': delaySkillTurns,
    'lowHpThreshold': lowHpThreshold,
    'lowEnemyHpThreshold': lowEnemyHpThreshold,
    'emergencyHealThreshold': emergencyHealThreshold,
    'longChainThreshold': longChainThreshold,
    'expBasePerLevel': expBasePerLevel,
    'expGrowthPerLevel': expGrowthPerLevel,
    'maxLevelByRarity': {
      'n': maxLevelByRarity[AgentRarity.n],
      'r': maxLevelByRarity[AgentRarity.r],
      'sr': maxLevelByRarity[AgentRarity.sr],
      'ssr': maxLevelByRarity[AgentRarity.ssr],
    },
    'defaultLevelScaling': defaultLevelScaling,
  };

  static const defaults = BattleParams();
}
