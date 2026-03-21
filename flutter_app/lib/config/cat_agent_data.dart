/// 貓咪特工靜態數據
/// MVP 版本：5 個角色
import '../core/models/cat_agent.dart';

class CatAgentData {
  CatAgentData._();

  // ─── MVP 角色定義 ───

  static const blazeAgent = CatAgentDefinition(
    id: 'blaze',
    name: '阿焰',
    codename: 'Agent Blaze',
    breed: '橘貓',
    attribute: AgentAttribute.attributeA,
    role: AgentRole.striker,
    rarity: AgentRarity.n,
    baseAtk: 25,
    baseDef: 10,
    baseHp: 200,
    atkGrowth: 4.0,
    defGrowth: 1.5,
    hpGrowth: 12.0,
    skill: AgentSkill(
      name: '爆裂爪擊',
      description: '以燃燒的爪子猛擊敵人，造成 ATK×{multiplier} 傷害',
      energyCost: 5,
      effectType: SkillEffectType.damage,
      baseMultiplier: 2.0,
      levelScaling: 0.08,
    ),
    passiveDescription: '消除🔴方塊時，額外累積 10% 能量',
    unlockCondition: UnlockCondition.free,
  );

  static const tideAgent = CatAgentDefinition(
    id: 'tide',
    name: '小波',
    codename: 'Agent Tide',
    breed: '曼赤肯',
    attribute: AgentAttribute.attributeC,
    role: AgentRole.supporter,
    rarity: AgentRarity.n,
    baseAtk: 15,
    baseDef: 15,
    baseHp: 250,
    atkGrowth: 2.0,
    defGrowth: 2.5,
    hpGrowth: 15.0,
    skill: AgentSkill(
      name: '水霧屏障',
      description: '釋放水霧回復隊伍 {multiplier}% HP，並延遲敵人攻擊 1 回合',
      energyCost: 6,
      effectType: SkillEffectType.heal,
      baseMultiplier: 20.0,
      levelScaling: 0.5,
    ),
    passiveDescription: '隊伍 HP 低於 30% 時，能量累積速度 +25%',
    unlockCondition: UnlockCondition(
      stageRequirement: '1-3',
    ),
  );

  static const terraAgent = CatAgentDefinition(
    id: 'terra',
    name: '大地',
    codename: 'Agent Terra',
    breed: '美國短毛貓',
    attribute: AgentAttribute.attributeB,
    role: AgentRole.defender,
    rarity: AgentRarity.r,
    baseAtk: 12,
    baseDef: 22,
    baseHp: 300,
    atkGrowth: 1.5,
    defGrowth: 3.5,
    hpGrowth: 18.0,
    skill: AgentSkill(
      name: '鋼鐵毛球',
      description: '捲成毛球形成護盾，減少受到的傷害 {multiplier}%，持續 2 回合',
      energyCost: 5,
      effectType: SkillEffectType.shield,
      baseMultiplier: 50.0,
      levelScaling: 0.8,
    ),
    passiveDescription: '每次被攻擊後，下次消除🟢方塊的能量 +20%',
    unlockCondition: UnlockCondition(
      goldCost: 500,
    ),
  );

  static const flashAgent = CatAgentDefinition(
    id: 'flash',
    name: '閃光',
    codename: 'Agent Flash',
    breed: '暹羅貓',
    attribute: AgentAttribute.attributeD,
    role: AgentRole.destroyer,
    rarity: AgentRarity.r,
    baseAtk: 22,
    baseDef: 8,
    baseHp: 180,
    atkGrowth: 3.5,
    defGrowth: 1.0,
    hpGrowth: 10.0,
    skill: AgentSkill(
      name: '雷光爪',
      description: '釋放電擊波，對全體敵人造成 ATK×{multiplier} 傷害',
      energyCost: 7,
      effectType: SkillEffectType.aoe,
      baseMultiplier: 1.5,
      levelScaling: 0.06,
    ),
    passiveDescription: '達成 5 連擊以上時，技能傷害額外 +15%',
    unlockCondition: UnlockCondition(
      stageRequirement: '1-15',
    ),
  );

  static const shadowAgent = CatAgentDefinition(
    id: 'shadow',
    name: '影子',
    codename: 'Agent Shadow',
    breed: '黑貓',
    attribute: AgentAttribute.attributeE,
    role: AgentRole.infiltrator,
    rarity: AgentRarity.sr,
    baseAtk: 28,
    baseDef: 10,
    baseHp: 180,
    atkGrowth: 4.5,
    defGrowth: 1.5,
    hpGrowth: 8.0,
    skill: AgentSkill(
      name: '暗殺突襲',
      description: '從暗處突襲，造成 ATK×{multiplier} 傷害。敵人 HP 低於 30% 時額外 +50%',
      energyCost: 6,
      effectType: SkillEffectType.execute,
      baseMultiplier: 3.0,
      levelScaling: 0.1,
    ),
    passiveDescription: '首次攻擊必定暴擊（傷害 ×1.5）',
    unlockCondition: UnlockCondition(
      stageRequirement: '1-10',
      requireAllStars: true,
      goldCost: 3000,
    ),
  );

  // ─── 全角色列表 ───

  static const List<CatAgentDefinition> allAgents = [
    blazeAgent,
    tideAgent,
    terraAgent,
    flashAgent,
    shadowAgent,
  ];

  /// 根據 ID 查找角色定義
  static CatAgentDefinition? getById(String id) {
    try {
      return allAgents.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 根據屬性查找角色
  static List<CatAgentDefinition> getByAttribute(AgentAttribute attr) {
    return allAgents.where((a) => a.attribute == attr).toList();
  }

  /// 初始免費角色
  static List<CatAgentDefinition> get starterAgents {
    return allAgents
        .where((a) => a.unlockCondition.isFree)
        .toList();
  }
}
