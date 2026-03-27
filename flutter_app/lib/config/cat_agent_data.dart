/// 貓咪點心屋角色數據
/// 15 個角色（每屬性 3 個）
import '../core/models/cat_agent.dart';

class CatAgentData {
  CatAgentData._();

  // ═══════════════════════════════════════
  // 屬性A ☀️ (coral) — 太陽系
  // ═══════════════════════════════════════

  static const blazeAgent = CatAgentDefinition(
    id: 'blaze',
    name: '小麥',
    codename: 'Baker Wheat',
    breed: '橘貓',
    attribute: AgentAttribute.attributeA,
    role: AgentRole.striker,
    rarity: AgentRarity.n,
    baseAtk: 25, baseDef: 10, baseHp: 200,
    atkGrowth: 4.0, defGrowth: 1.5, hpGrowth: 12.0,
    baseSpeed: 2, // striker: 快攻
    skill: AgentSkill(
      name: '熱騰騰出爐！',
      description: '新鮮出爐的麵包重擊，造成 ATK×{multiplier} 傷害',
      energyCost: 5, effectType: SkillEffectType.damage,
      baseMultiplier: 2.0, levelScaling: 0.08,
      boardEffect: SkillBoardEffect(
        type: BoardEffectType.convertColor,
        value: 3,
        description: '麵包香氣：轉化 3 個方塊為☀️',
      ),
    ),
    passiveDescription: '收集陽光麥穗時，額外累積 10% 烘焙能量',
    unlockCondition: UnlockCondition.free,
  );

  static const emberAgent = CatAgentDefinition(
    id: 'ember',
    name: '窯窯',
    codename: 'Baker Kiln',
    breed: '孟加拉貓',
    attribute: AgentAttribute.attributeA,
    role: AgentRole.destroyer,
    rarity: AgentRarity.r,
    baseAtk: 24, baseDef: 10, baseHp: 190,
    atkGrowth: 3.8, defGrowth: 1.2, hpGrowth: 11.0,
    skill: AgentSkill(
      name: '窯烤大爆發！',
      description: '窯火全開，對全體搗蛋鬼造成 ATK×{multiplier} 傷害',
      energyCost: 7, effectType: SkillEffectType.aoe,
      baseMultiplier: 1.6, levelScaling: 0.07,
      boardEffect: SkillBoardEffect(
        type: BoardEffectType.eliminateRandom,
        value: 4,
        description: '窯火四散：隨機消除 4 個方塊',
      ),
    ),
    passiveDescription: '大量收集食材時，窯火溫度上升，全體額外 5% ATK 傷害',
    unlockCondition: UnlockCondition(stageRequirement: '1-8', goldCost: 800),
  );

  static const infernoAgent = CatAgentDefinition(
    id: 'inferno',
    name: '焦糖',
    codename: 'Baker Caramel',
    breed: '阿比西尼亞貓',
    attribute: AgentAttribute.attributeA,
    role: AgentRole.infiltrator,
    rarity: AgentRarity.sr,
    baseAtk: 30, baseDef: 8, baseHp: 170,
    atkGrowth: 5.0, defGrowth: 1.0, hpGrowth: 8.0,
    baseSpeed: 2, // infiltrator: 快攻
    skill: AgentSkill(
      name: '極速外送！',
      description: '極速送達的焦糖風暴，造成 ATK×{multiplier} 傷害。搗蛋鬼 HP<30% 時 +50%',
      energyCost: 6, effectType: SkillEffectType.execute,
      baseMultiplier: 3.2, levelScaling: 0.12,
      boardEffect: SkillBoardEffect(
        type: BoardEffectType.eliminateColumn,
        value: 0,
        description: '焦糖瀑布：消除隨機一列方塊',
      ),
    ),
    passiveDescription: '淨化搗蛋鬼後，下次料理技能威力 +20%',
    unlockCondition: UnlockCondition(
      stageRequirement: '2-5', requireAllStars: true, goldCost: 4000,
    ),
  );

  // ═══════════════════════════════════════
  // 屬性B 🍃 (mint) — 葉子系
  // ═══════════════════════════════════════

  static const terraAgent = CatAgentDefinition(
    id: 'terra',
    name: '抹抹',
    codename: 'Herb Matcha',
    breed: '美國短毛貓',
    attribute: AgentAttribute.attributeB,
    role: AgentRole.defender,
    rarity: AgentRarity.r,
    baseAtk: 12, baseDef: 22, baseHp: 300,
    atkGrowth: 1.5, defGrowth: 3.5, hpGrowth: 18.0,
    baseSpeed: 4, // defender: 慢但硬
    skill: AgentSkill(
      name: '抹茶結界！',
      description: '濃郁抹茶形成結界，減少受到的傷害 {multiplier}%，持續 2 回合',
      energyCost: 5, effectType: SkillEffectType.shield,
      baseMultiplier: 50.0, levelScaling: 0.8,
      boardEffect: SkillBoardEffect(
        type: BoardEffectType.convertColor,
        value: 4,
        description: '茶香瀰漫：轉化 4 個方塊為🍃',
      ),
    ),
    passiveDescription: '被搗蛋鬼攻擊後，下次收集香草葉的能量 +20%',
    unlockCondition: UnlockCondition(goldCost: 500),
  );

  static const sproutAgent = CatAgentDefinition(
    id: 'sprout',
    name: '薄荷',
    codename: 'Herb Mint',
    breed: '蘇格蘭摺耳貓',
    attribute: AgentAttribute.attributeB,
    role: AgentRole.supporter,
    rarity: AgentRarity.n,
    baseAtk: 13, baseDef: 16, baseHp: 260,
    atkGrowth: 1.8, defGrowth: 2.8, hpGrowth: 16.0,
    skill: AgentSkill(
      name: '薄荷清風～',
      description: '清涼薄荷風回復夥伴 {multiplier}% HP',
      energyCost: 5, effectType: SkillEffectType.heal,
      baseMultiplier: 18.0, levelScaling: 0.5,
      boardEffect: SkillBoardEffect(
        type: BoardEffectType.convertColor,
        value: 3,
        description: '清新香氣：轉化 3 個方塊為🍃',
      ),
    ),
    passiveDescription: '每 3 回合，薄荷香氣自動恢復夥伴 2% HP',
    unlockCondition: UnlockCondition(stageRequirement: '1-5'),
  );

  static const gaiaAgent = CatAgentDefinition(
    id: 'gaia',
    name: '肉桂',
    codename: 'Herb Cinnamon',
    breed: '挪威森林貓',
    attribute: AgentAttribute.attributeB,
    role: AgentRole.striker,
    rarity: AgentRarity.sr,
    baseAtk: 26, baseDef: 18, baseHp: 280,
    atkGrowth: 4.0, defGrowth: 2.5, hpGrowth: 14.0,
    baseSpeed: 2, // striker: 快攻
    skill: AgentSkill(
      name: '肉桂重擊！',
      description: '肉桂棒全力揮擊，造成 ATK×{multiplier} 傷害',
      energyCost: 6, effectType: SkillEffectType.damage,
      baseMultiplier: 2.5, levelScaling: 0.1,
      boardEffect: SkillBoardEffect(
        type: BoardEffectType.eliminateRow,
        value: -1,
        description: '香料炸裂：消除底部一整排方塊',
      ),
    ),
    passiveDescription: '在抹茶結界保護下，攻擊力 +15%',
    unlockCondition: UnlockCondition(
      stageRequirement: '2-10', goldCost: 5000,
    ),
  );

  // ═══════════════════════════════════════
  // 屬性C 💧 (teal) — 水滴系
  // ═══════════════════════════════════════

  static const tideAgent = CatAgentDefinition(
    id: 'tide',
    name: '露露',
    codename: 'Drink Dew',
    breed: '曼赤肯',
    attribute: AgentAttribute.attributeC,
    role: AgentRole.supporter,
    rarity: AgentRarity.n,
    baseAtk: 15, baseDef: 15, baseHp: 250,
    atkGrowth: 2.0, defGrowth: 2.5, hpGrowth: 15.0,
    skill: AgentSkill(
      name: '果汁補給站～',
      description: '新鮮果汁補給，回復夥伴 {multiplier}% HP，並延遲搗蛋鬼攻擊 1 回合',
      energyCost: 6, effectType: SkillEffectType.heal,
      baseMultiplier: 20.0, levelScaling: 0.5,
      boardEffect: SkillBoardEffect(
        type: BoardEffectType.convertColor,
        value: 3,
        description: '清涼水霧：轉化 3 個方塊為💧',
      ),
    ),
    passiveDescription: '夥伴們疲憊時，露露加快調配飲料，能量累積 +25%',
    unlockCondition: UnlockCondition(stageRequirement: '1-3'),
  );

  static const frostAgent = CatAgentDefinition(
    id: 'frost',
    name: '奶昔',
    codename: 'Drink Shake',
    breed: '布偶貓',
    attribute: AgentAttribute.attributeC,
    role: AgentRole.defender,
    rarity: AgentRarity.r,
    baseAtk: 14, baseDef: 20, baseHp: 290,
    atkGrowth: 1.8, defGrowth: 3.2, hpGrowth: 17.0,
    baseSpeed: 4, // defender: 慢但硬
    skill: AgentSkill(
      name: '冰淇淋護盾！',
      description: '冰涼奶昔凝結護盾，減少受到的傷害 {multiplier}%，持續 2 回合',
      energyCost: 5, effectType: SkillEffectType.shield,
      baseMultiplier: 45.0, levelScaling: 0.7,
      boardEffect: SkillBoardEffect(
        type: BoardEffectType.convertColor,
        value: 4,
        description: '冰霜凝結：轉化 4 個方塊為🔵',
      ),
    ),
    passiveDescription: '護盾生效時，敵人攻擊速度降低 10%',
    unlockCondition: UnlockCondition(stageRequirement: '2-2', goldCost: 1000),
  );

  static const tsunamiAgent = CatAgentDefinition(
    id: 'tsunami',
    name: '海嘯',
    codename: 'Agent Tsunami',
    breed: '俄羅斯藍貓',
    attribute: AgentAttribute.attributeC,
    role: AgentRole.destroyer,
    rarity: AgentRarity.sr,
    baseAtk: 27, baseDef: 12, baseHp: 200,
    atkGrowth: 4.2, defGrowth: 1.5, hpGrowth: 10.0,
    skill: AgentSkill(
      name: '怒濤沖擊',
      description: '掀起海嘯，對全體敵人造成 ATK×{multiplier} 傷害',
      energyCost: 7, effectType: SkillEffectType.aoe,
      baseMultiplier: 1.8, levelScaling: 0.08,
      boardEffect: SkillBoardEffect(
        type: BoardEffectType.eliminateRow,
        value: 0,
        description: '海嘯沖刷：消除頂部一整排方塊',
      ),
    ),
    passiveDescription: '使用技能後，延遲敵人攻擊 1 回合',
    unlockCondition: UnlockCondition(
      stageRequirement: '2-8', requireAllStars: true, goldCost: 4500,
    ),
  );

  // ═══════════════════════════════════════
  // 屬性D 🟡 (gold) — 雷系
  // ═══════════════════════════════════════

  static const flashAgent = CatAgentDefinition(
    id: 'flash',
    name: '閃光',
    codename: 'Agent Flash',
    breed: '暹羅貓',
    attribute: AgentAttribute.attributeD,
    role: AgentRole.destroyer,
    rarity: AgentRarity.r,
    baseAtk: 22, baseDef: 8, baseHp: 180,
    atkGrowth: 3.5, defGrowth: 1.0, hpGrowth: 10.0,
    skill: AgentSkill(
      name: '雷光爪',
      description: '釋放電擊波，對全體敵人造成 ATK×{multiplier} 傷害',
      energyCost: 7, effectType: SkillEffectType.aoe,
      baseMultiplier: 1.5, levelScaling: 0.06,
      boardEffect: SkillBoardEffect(
        type: BoardEffectType.eliminateRandom,
        value: 3,
        description: '落雷擊破：隨機消除 3 個方塊',
      ),
    ),
    passiveDescription: '達成 5 連擊以上時，技能傷害額外 +15%',
    unlockCondition: UnlockCondition(stageRequirement: '3-5'),
  );

  static const sparkAgent = CatAgentDefinition(
    id: 'spark',
    name: '火花',
    codename: 'Agent Spark',
    breed: '日本短尾貓',
    attribute: AgentAttribute.attributeD,
    role: AgentRole.supporter,
    rarity: AgentRarity.n,
    baseAtk: 16, baseDef: 14, baseHp: 230,
    atkGrowth: 2.2, defGrowth: 2.0, hpGrowth: 14.0,
    skill: AgentSkill(
      name: '電弧治療',
      description: '以微弱電流刺激恢復，回復隊伍 {multiplier}% HP',
      energyCost: 5, effectType: SkillEffectType.heal,
      baseMultiplier: 16.0, levelScaling: 0.4,
      boardEffect: SkillBoardEffect(
        type: BoardEffectType.convertColor,
        value: 3,
        description: '電弧充能：轉化 3 個方塊為🟡',
      ),
    ),
    passiveDescription: '隊伍受到傷害時，有 15% 機率恢復 3% HP',
    unlockCondition: UnlockCondition(stageRequirement: '1-6'),
  );

  static const thunderAgent = CatAgentDefinition(
    id: 'thunder',
    name: '雷霆',
    codename: 'Agent Thunder',
    breed: '緬因貓',
    attribute: AgentAttribute.attributeD,
    role: AgentRole.striker,
    rarity: AgentRarity.sr,
    baseAtk: 32, baseDef: 8, baseHp: 175,
    atkGrowth: 5.0, defGrowth: 1.0, hpGrowth: 8.0,
    baseSpeed: 2, // striker: 快攻
    skill: AgentSkill(
      name: '雷神一擊',
      description: '匯聚雷電之力猛擊，造成 ATK×{multiplier} 傷害',
      energyCost: 6, effectType: SkillEffectType.damage,
      baseMultiplier: 2.8, levelScaling: 0.12,
      boardEffect: SkillBoardEffect(
        type: BoardEffectType.eliminateColumn,
        value: 0,
        description: '雷霆貫穿：消除隨機一列方塊',
      ),
    ),
    passiveDescription: '暴擊傷害額外 +20%',
    unlockCondition: UnlockCondition(
      stageRequirement: '4-2', requireAllStars: true, goldCost: 5000,
    ),
  );

  // ═══════════════════════════════════════
  // 屬性E 🟣 (rose) — 暗系
  // ═══════════════════════════════════════

  static const shadowAgent = CatAgentDefinition(
    id: 'shadow',
    name: '影子',
    codename: 'Agent Shadow',
    breed: '黑貓',
    attribute: AgentAttribute.attributeE,
    role: AgentRole.infiltrator,
    rarity: AgentRarity.sr,
    baseAtk: 28, baseDef: 10, baseHp: 180,
    atkGrowth: 4.5, defGrowth: 1.5, hpGrowth: 8.0,
    baseSpeed: 2, // infiltrator: 快攻
    skill: AgentSkill(
      name: '暗殺突襲',
      description: '從暗處突襲，造成 ATK×{multiplier} 傷害。敵人 HP 低於 30% 時額外 +50%',
      energyCost: 6, effectType: SkillEffectType.execute,
      baseMultiplier: 3.0, levelScaling: 0.1,
      boardEffect: SkillBoardEffect(
        type: BoardEffectType.convertColor,
        value: 4,
        description: '暗影侵蝕：轉化 4 個方塊為🟣',
      ),
    ),
    passiveDescription: '首次攻擊必定暴擊（傷害 ×1.5）',
    unlockCondition: UnlockCondition(
      stageRequirement: '1-10', requireAllStars: true, goldCost: 3000,
    ),
  );

  static const phantomAgent = CatAgentDefinition(
    id: 'phantom',
    name: '幻影',
    codename: 'Agent Phantom',
    breed: '科拉特貓',
    attribute: AgentAttribute.attributeE,
    role: AgentRole.defender,
    rarity: AgentRarity.n,
    baseAtk: 14, baseDef: 18, baseHp: 270,
    atkGrowth: 2.0, defGrowth: 3.0, hpGrowth: 16.0,
    baseSpeed: 4, // defender: 慢但硬
    skill: AgentSkill(
      name: '暗影壁壘',
      description: '以暗影凝聚護盾，減少受到的傷害 {multiplier}%，持續 2 回合',
      energyCost: 5, effectType: SkillEffectType.shield,
      baseMultiplier: 40.0, levelScaling: 0.6,
      boardEffect: SkillBoardEffect(
        type: BoardEffectType.shuffleBoard,
        value: 0,
        description: '幻影錯亂：重新排列所有方塊',
      ),
    ),
    passiveDescription: '護盾期間受到攻擊時，有 10% 機率使敵人攻擊延遲 1 回合',
    unlockCondition: UnlockCondition(stageRequirement: '1-7'),
  );

  static const eclipseAgent = CatAgentDefinition(
    id: 'eclipse',
    name: '蝕月',
    codename: 'Agent Eclipse',
    breed: '孟買貓',
    attribute: AgentAttribute.attributeE,
    role: AgentRole.destroyer,
    rarity: AgentRarity.r,
    baseAtk: 24, baseDef: 10, baseHp: 195,
    atkGrowth: 3.8, defGrowth: 1.2, hpGrowth: 11.0,
    skill: AgentSkill(
      name: '蝕月陰影',
      description: '釋放暗月之力，對全體敵人造成 ATK×{multiplier} 傷害',
      energyCost: 7, effectType: SkillEffectType.aoe,
      baseMultiplier: 1.6, levelScaling: 0.07,
      boardEffect: SkillBoardEffect(
        type: BoardEffectType.eliminateRandom,
        value: 5,
        description: '蝕月吞噬：隨機消除 5 個方塊',
      ),
    ),
    passiveDescription: '敵人 HP 越低，造成的傷害越高（最高 +15%）',
    unlockCondition: UnlockCondition(stageRequirement: '3-8', goldCost: 1200),
  );

  // ─── 全角色列表 ───

  static const List<CatAgentDefinition> allAgents = [
    // 🔴 火系
    blazeAgent, emberAgent, infernoAgent,
    // 🟢 大地系
    terraAgent, sproutAgent, gaiaAgent,
    // 🔵 水系
    tideAgent, frostAgent, tsunamiAgent,
    // 🟡 雷系
    flashAgent, sparkAgent, thunderAgent,
    // 🟣 暗系
    shadowAgent, phantomAgent, eclipseAgent,
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
