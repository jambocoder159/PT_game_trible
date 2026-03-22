/// 技能強化靜態數據
/// 5 隻貓各有 5 階技能
import '../core/models/material.dart';
import '../core/models/skill_enhancement.dart';

class SkillTierData {
  SkillTierData._();

  // ─── 阿焰 Blaze — 爆裂爪擊 ───

  static const blazeSkillTiers = <SkillTierDefinition>[
    SkillTierDefinition(
      tier: 1, name: '爆裂爪擊', description: '2.0x 單體傷害',
      multiplierBonus: 0, goldCost: 0, materialCost: {},
    ),
    SkillTierDefinition(
      tier: 2, name: '爪擊升溫', description: '2.3x 傷害，熱量增強',
      multiplierBonus: 0.3,
      goldCost: 300, materialCost: {GameMaterial.commonShard: 5, GameMaterial.skillCore: 1},
    ),
    SkillTierDefinition(
      tier: 3, name: '灼燒爪擊', description: '2.6x 傷害 + 灼燒 2 回合 (15% ATK)',
      multiplierBonus: 0.3, newMechanic: SkillTierMechanic.dot, mechanicValue: 0.15,
      goldCost: 800, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.skillCore: 2},
    ),
    SkillTierDefinition(
      tier: 4, name: '烈焰擴散', description: '3.0x 傷害 + 30% 濺射傷害',
      multiplierBonus: 0.4, newMechanic: SkillTierMechanic.aoeSplash, mechanicValue: 0.3,
      goldCost: 1500, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.skillCore: 3, GameMaterial.rareShard: 1},
    ),
    SkillTierDefinition(
      tier: 5, name: '焚天爪擊', description: '3.5x 傷害 + 破防 (DEF -20%, 2 回合)',
      multiplierBonus: 0.5, newMechanic: SkillTierMechanic.defBreak, mechanicValue: 0.2,
      goldCost: 3000, materialCost: {GameMaterial.rareShard: 3, GameMaterial.skillCore: 5},
    ),
  ];

  // ─── 小波 Tide — 水霧屏障 ───

  static const tideSkillTiers = <SkillTierDefinition>[
    SkillTierDefinition(
      tier: 1, name: '水霧屏障', description: '回復隊伍 20% HP',
      multiplierBonus: 0, goldCost: 0, materialCost: {},
    ),
    SkillTierDefinition(
      tier: 2, name: '霧氣濃縮', description: '回復 22% HP',
      multiplierBonus: 2,
      goldCost: 300, materialCost: {GameMaterial.commonShard: 5, GameMaterial.skillCore: 1},
    ),
    SkillTierDefinition(
      tier: 3, name: '迷霧阻擋', description: '回復 25% HP + 延遲敵人 1 回合',
      multiplierBonus: 3, newMechanic: SkillTierMechanic.delayAdded, mechanicValue: 1,
      goldCost: 800, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.skillCore: 2},
    ),
    SkillTierDefinition(
      tier: 4, name: '生命之泉', description: '回復 28% HP + HoT 5%/回合 2 回合',
      multiplierBonus: 3, newMechanic: SkillTierMechanic.durationExtend, mechanicValue: 0.05,
      goldCost: 1500, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.skillCore: 3, GameMaterial.rareShard: 1},
    ),
    SkillTierDefinition(
      tier: 5, name: '海洋恩賜', description: '回復 32% HP + 退還 2 能量',
      multiplierBonus: 4, newMechanic: SkillTierMechanic.energyRefund, mechanicValue: 2,
      goldCost: 3000, materialCost: {GameMaterial.rareShard: 3, GameMaterial.skillCore: 5},
    ),
  ];

  // ─── 大地 Terra — 鋼鐵毛球 ───

  static const terraSkillTiers = <SkillTierDefinition>[
    SkillTierDefinition(
      tier: 1, name: '鋼鐵毛球', description: '減傷 50%，持續 2 回合',
      multiplierBonus: 0, goldCost: 0, materialCost: {},
    ),
    SkillTierDefinition(
      tier: 2, name: '強化毛球', description: '減傷 55%',
      multiplierBonus: 5,
      goldCost: 300, materialCost: {GameMaterial.commonShard: 5, GameMaterial.skillCore: 1},
    ),
    SkillTierDefinition(
      tier: 3, name: '持久護盾', description: '減傷 60%，持續 3 回合',
      multiplierBonus: 5, newMechanic: SkillTierMechanic.durationExtend, mechanicValue: 1,
      goldCost: 800, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.skillCore: 2},
    ),
    SkillTierDefinition(
      tier: 4, name: '反彈護甲', description: '減傷 65% + 反射 20% 傷害',
      multiplierBonus: 5, newMechanic: SkillTierMechanic.reflect, mechanicValue: 0.2,
      goldCost: 1500, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.skillCore: 3, GameMaterial.rareShard: 1},
    ),
    SkillTierDefinition(
      tier: 5, name: '荊棘鎧甲', description: '減傷 70% + 受擊反擊 10% ATK',
      multiplierBonus: 5, newMechanic: SkillTierMechanic.dot, mechanicValue: 0.1,
      goldCost: 3000, materialCost: {GameMaterial.rareShard: 3, GameMaterial.skillCore: 5},
    ),
  ];

  // ─── 閃光 Flash — 雷光爪 ───

  static const flashSkillTiers = <SkillTierDefinition>[
    SkillTierDefinition(
      tier: 1, name: '雷光爪', description: '1.5x 全體傷害',
      multiplierBonus: 0, goldCost: 0, materialCost: {},
    ),
    SkillTierDefinition(
      tier: 2, name: '電弧強化', description: '1.7x 全體傷害',
      multiplierBonus: 0.2,
      goldCost: 300, materialCost: {GameMaterial.commonShard: 5, GameMaterial.skillCore: 1},
    ),
    SkillTierDefinition(
      tier: 3, name: '雷電破防', description: '1.9x 全體傷害 + 全體破防 -10%',
      multiplierBonus: 0.2, newMechanic: SkillTierMechanic.defBreak, mechanicValue: 0.1,
      goldCost: 800, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.skillCore: 2},
    ),
    SkillTierDefinition(
      tier: 4, name: '連鎖閃電', description: '2.2x 全體 + 隨機追擊 0.5x',
      multiplierBonus: 0.3, newMechanic: SkillTierMechanic.aoeSplash, mechanicValue: 0.5,
      goldCost: 1500, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.skillCore: 3, GameMaterial.rareShard: 1},
    ),
    SkillTierDefinition(
      tier: 5, name: '雷霆審判', description: '2.5x 全體 + 擊殺退 3 能量',
      multiplierBonus: 0.3, newMechanic: SkillTierMechanic.energyRefund, mechanicValue: 3,
      goldCost: 3000, materialCost: {GameMaterial.rareShard: 3, GameMaterial.skillCore: 5},
    ),
  ];

  // ─── 影子 Shadow — 暗殺突襲 ───

  static const shadowSkillTiers = <SkillTierDefinition>[
    SkillTierDefinition(
      tier: 1, name: '暗殺突襲', description: '3.0x 傷害，<30% HP +50%',
      multiplierBonus: 0, goldCost: 0, materialCost: {},
    ),
    SkillTierDefinition(
      tier: 2, name: '暗殺強化', description: '3.3x 傷害',
      multiplierBonus: 0.3,
      goldCost: 300, materialCost: {GameMaterial.commonShard: 5, GameMaterial.skillCore: 1},
    ),
    SkillTierDefinition(
      tier: 3, name: '致命追蹤', description: '3.6x 傷害，斬殺門檻提升至 40%',
      multiplierBonus: 0.3, newMechanic: SkillTierMechanic.executeThresholdUp, mechanicValue: 0.4,
      goldCost: 800, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.skillCore: 2},
    ),
    SkillTierDefinition(
      tier: 4, name: '流血刺殺', description: '4.0x 傷害 + 流血 2 回合 (20% ATK)',
      multiplierBonus: 0.4, newMechanic: SkillTierMechanic.dot, mechanicValue: 0.2,
      goldCost: 1500, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.skillCore: 3, GameMaterial.rareShard: 1},
    ),
    SkillTierDefinition(
      tier: 5, name: '終結暗殺', description: '4.5x 傷害 + 擊殺全額退能量',
      multiplierBonus: 0.5, newMechanic: SkillTierMechanic.energyRefund, mechanicValue: -1,
      goldCost: 3000, materialCost: {GameMaterial.rareShard: 3, GameMaterial.skillCore: 5},
    ),
  ];

  // ─── 查詢方法 ───

  static const Map<String, List<SkillTierDefinition>> _agentSkillTiers = {
    'blaze': blazeSkillTiers,
    'tide': tideSkillTiers,
    'terra': terraSkillTiers,
    'flash': flashSkillTiers,
    'shadow': shadowSkillTiers,
  };

  static List<SkillTierDefinition> getTiersForAgent(String agentId) {
    return _agentSkillTiers[agentId] ?? [];
  }

  static SkillTierDefinition? getTier(String agentId, int tier) {
    final tiers = _agentSkillTiers[agentId];
    if (tiers == null || tier < 1 || tier > tiers.length) return null;
    return tiers[tier - 1];
  }

  /// 取得指定階級的累計倍率加成
  static double getCumulativeMultiplierBonus(String agentId, int currentTier) {
    final tiers = _agentSkillTiers[agentId] ?? [];
    double total = 0;
    for (int i = 0; i < currentTier && i < tiers.length; i++) {
      total += tiers[i].multiplierBonus;
    }
    return total;
  }

  /// 取得當前階級及以下所有已啟用的機制
  static List<SkillTierDefinition> getActiveMechanics(String agentId, int currentTier) {
    final tiers = _agentSkillTiers[agentId] ?? [];
    return tiers
        .where((t) => t.tier <= currentTier && t.newMechanic != null)
        .toList();
  }
}
