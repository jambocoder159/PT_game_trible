/// 技能強化靜態數據
/// 15 隻貓各有 5 階技能
import '../core/models/material.dart';
import '../core/models/skill_enhancement.dart';

class SkillTierData {
  SkillTierData._();

  // ─── 小麥 Wheat — 熱騰騰出爐！ ───

  static const blazeSkillTiers = <SkillTierDefinition>[
    SkillTierDefinition(
      tier: 1, name: '熱騰騰出爐！', description: '2.0x 單體傷害',
      multiplierBonus: 0, goldCost: 0, materialCost: {},
    ),
    SkillTierDefinition(
      tier: 2, name: '加熱發酵', description: '2.3x 傷害，麵團增強',
      multiplierBonus: 0.3,
      goldCost: 300, materialCost: {GameMaterial.commonShard: 5, GameMaterial.skillCore: 1},
    ),
    SkillTierDefinition(
      tier: 3, name: '香酥烘焙', description: '2.6x 傷害 + 烘烤 2 回合 (15% ATK)',
      multiplierBonus: 0.3, newMechanic: SkillTierMechanic.dot, mechanicValue: 0.15,
      goldCost: 800, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.skillCore: 2},
    ),
    SkillTierDefinition(
      tier: 4, name: '麵包擴散', description: '3.0x 傷害 + 30% 濺射傷害',
      multiplierBonus: 0.4, newMechanic: SkillTierMechanic.aoeSplash, mechanicValue: 0.3,
      goldCost: 1500, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.skillCore: 3, GameMaterial.rareShard: 1},
    ),
    SkillTierDefinition(
      tier: 5, name: '極致出爐', description: '3.5x 傷害 + 破防 (DEF -20%, 2 回合)',
      multiplierBonus: 0.5, newMechanic: SkillTierMechanic.defBreak, mechanicValue: 0.2,
      goldCost: 3000, materialCost: {GameMaterial.rareShard: 3, GameMaterial.skillCore: 5},
    ),
  ];

  // ─── 露露 Dew — 果汁補給站～ ───

  static const tideSkillTiers = <SkillTierDefinition>[
    SkillTierDefinition(
      tier: 1, name: '果汁補給站～', description: '回復隊伍 20% HP',
      multiplierBonus: 0, goldCost: 0, materialCost: {},
    ),
    SkillTierDefinition(
      tier: 2, name: '濃縮果汁', description: '回復 22% HP',
      multiplierBonus: 2,
      goldCost: 300, materialCost: {GameMaterial.commonShard: 5, GameMaterial.skillCore: 1},
    ),
    SkillTierDefinition(
      tier: 3, name: '清涼阻擋', description: '回復 25% HP + 延遲敵人 1 回合',
      multiplierBonus: 3, newMechanic: SkillTierMechanic.delayAdded, mechanicValue: 1,
      goldCost: 800, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.skillCore: 2},
    ),
    SkillTierDefinition(
      tier: 4, name: '活力之泉', description: '回復 28% HP + HoT 5%/回合 2 回合',
      multiplierBonus: 3, newMechanic: SkillTierMechanic.durationExtend, mechanicValue: 0.05,
      goldCost: 1500, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.skillCore: 3, GameMaterial.rareShard: 1},
    ),
    SkillTierDefinition(
      tier: 5, name: '甘露恩賜', description: '回復 32% HP + 退還 2 能量',
      multiplierBonus: 4, newMechanic: SkillTierMechanic.energyRefund, mechanicValue: 2,
      goldCost: 3000, materialCost: {GameMaterial.rareShard: 3, GameMaterial.skillCore: 5},
    ),
  ];

  // ─── 抹抹 Matcha — 抹茶結界！ ───

  static const terraSkillTiers = <SkillTierDefinition>[
    SkillTierDefinition(
      tier: 1, name: '抹茶結界！', description: '減傷 50%，持續 2 回合',
      multiplierBonus: 0, goldCost: 0, materialCost: {},
    ),
    SkillTierDefinition(
      tier: 2, name: '濃厚抹茶', description: '減傷 55%',
      multiplierBonus: 5,
      goldCost: 300, materialCost: {GameMaterial.commonShard: 5, GameMaterial.skillCore: 1},
    ),
    SkillTierDefinition(
      tier: 3, name: '持久茶香', description: '減傷 60%，持續 3 回合',
      multiplierBonus: 5, newMechanic: SkillTierMechanic.durationExtend, mechanicValue: 1,
      goldCost: 800, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.skillCore: 2},
    ),
    SkillTierDefinition(
      tier: 4, name: '反彈茶壁', description: '減傷 65% + 反射 20% 傷害',
      multiplierBonus: 5, newMechanic: SkillTierMechanic.reflect, mechanicValue: 0.2,
      goldCost: 1500, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.skillCore: 3, GameMaterial.rareShard: 1},
    ),
    SkillTierDefinition(
      tier: 5, name: '極致抹茶結界', description: '減傷 70% + 受擊反擊 10% ATK',
      multiplierBonus: 5, newMechanic: SkillTierMechanic.dot, mechanicValue: 0.1,
      goldCost: 3000, materialCost: {GameMaterial.rareShard: 3, GameMaterial.skillCore: 5},
    ),
  ];

  // ─── 糖霜 Frosting — 糖霜風暴！ ───

  static const flashSkillTiers = <SkillTierDefinition>[
    SkillTierDefinition(
      tier: 1, name: '糖霜風暴！', description: '1.5x 全體傷害',
      multiplierBonus: 0, goldCost: 0, materialCost: {},
    ),
    SkillTierDefinition(
      tier: 2, name: '糖霜強化', description: '1.7x 全體傷害',
      multiplierBonus: 0.2,
      goldCost: 300, materialCost: {GameMaterial.commonShard: 5, GameMaterial.skillCore: 1},
    ),
    SkillTierDefinition(
      tier: 3, name: '糖霜破防', description: '1.9x 全體傷害 + 全體破防 -10%',
      multiplierBonus: 0.2, newMechanic: SkillTierMechanic.defBreak, mechanicValue: 0.1,
      goldCost: 800, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.skillCore: 2},
    ),
    SkillTierDefinition(
      tier: 4, name: '連鎖糖霜', description: '2.2x 全體 + 隨機追擊 0.5x',
      multiplierBonus: 0.3, newMechanic: SkillTierMechanic.aoeSplash, mechanicValue: 0.5,
      goldCost: 1500, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.skillCore: 3, GameMaterial.rareShard: 1},
    ),
    SkillTierDefinition(
      tier: 5, name: '極致糖霜風暴', description: '2.5x 全體 + 擊殺退 3 能量',
      multiplierBonus: 0.3, newMechanic: SkillTierMechanic.energyRefund, mechanicValue: 3,
      goldCost: 3000, materialCost: {GameMaterial.rareShard: 3, GameMaterial.skillCore: 5},
    ),
  ];

  // ─── 可可 Cocoa — 深夜特製巧克力！ ───

  static const shadowSkillTiers = <SkillTierDefinition>[
    SkillTierDefinition(
      tier: 1, name: '深夜特製巧克力！', description: '3.0x 傷害，<30% HP +50%',
      multiplierBonus: 0, goldCost: 0, materialCost: {},
    ),
    SkillTierDefinition(
      tier: 2, name: '濃醇可可', description: '3.3x 傷害',
      multiplierBonus: 0.3,
      goldCost: 300, materialCost: {GameMaterial.commonShard: 5, GameMaterial.skillCore: 1},
    ),
    SkillTierDefinition(
      tier: 3, name: '深夜追蹤', description: '3.6x 傷害，斬殺門檻提升至 40%',
      multiplierBonus: 0.3, newMechanic: SkillTierMechanic.executeThresholdUp, mechanicValue: 0.4,
      goldCost: 800, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.skillCore: 2},
    ),
    SkillTierDefinition(
      tier: 4, name: '熔岩巧克力', description: '4.0x 傷害 + 灼燒 2 回合 (20% ATK)',
      multiplierBonus: 0.4, newMechanic: SkillTierMechanic.dot, mechanicValue: 0.2,
      goldCost: 1500, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.skillCore: 3, GameMaterial.rareShard: 1},
    ),
    SkillTierDefinition(
      tier: 5, name: '極致深夜巧克力', description: '4.5x 傷害 + 擊殺全額退能量',
      multiplierBonus: 0.5, newMechanic: SkillTierMechanic.energyRefund, mechanicValue: -1,
      goldCost: 3000, materialCost: {GameMaterial.rareShard: 3, GameMaterial.skillCore: 5},
    ),
  ];

  // ─── 窯窯 Kiln — 窯烤大爆發！ (destroyer, AOE) ───

  static const emberSkillTiers = <SkillTierDefinition>[
    SkillTierDefinition(
      tier: 1, name: '窯烤大爆發！', description: '1.6x 全體傷害',
      multiplierBonus: 0, goldCost: 0, materialCost: {},
    ),
    SkillTierDefinition(
      tier: 2, name: '窯火升溫', description: '1.8x 全體傷害',
      multiplierBonus: 0.2,
      goldCost: 300, materialCost: {GameMaterial.commonShard: 5, GameMaterial.skillCore: 1},
    ),
    SkillTierDefinition(
      tier: 3, name: '窯烤破酥', description: '2.0x 全體傷害 + 全體破防 -15%',
      multiplierBonus: 0.2, newMechanic: SkillTierMechanic.defBreak, mechanicValue: 0.15,
      goldCost: 800, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.skillCore: 2},
    ),
    SkillTierDefinition(
      tier: 4, name: '連鎖窯烤', description: '2.3x 全體 + 連鎖灼燒 0.4x',
      multiplierBonus: 0.3, newMechanic: SkillTierMechanic.aoeSplash, mechanicValue: 0.4,
      goldCost: 1500, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.skillCore: 3, GameMaterial.rareShard: 1},
    ),
    SkillTierDefinition(
      tier: 5, name: '極致窯烤', description: '2.6x 全體 + 擊殺退 3 能量',
      multiplierBonus: 0.3, newMechanic: SkillTierMechanic.energyRefund, mechanicValue: 3,
      goldCost: 3000, materialCost: {GameMaterial.rareShard: 3, GameMaterial.skillCore: 5},
    ),
  ];

  // ─── 焦糖 Caramel — 極速外送！ (infiltrator, execute) ───

  static const infernoSkillTiers = <SkillTierDefinition>[
    SkillTierDefinition(
      tier: 1, name: '極速外送！', description: '3.2x 傷害，<30% HP +50%',
      multiplierBonus: 0, goldCost: 0, materialCost: {},
    ),
    SkillTierDefinition(
      tier: 2, name: '焦糖加速', description: '3.5x 傷害',
      multiplierBonus: 0.3,
      goldCost: 300, materialCost: {GameMaterial.commonShard: 5, GameMaterial.skillCore: 1},
    ),
    SkillTierDefinition(
      tier: 3, name: '焦糖追擊', description: '3.8x 傷害，斬殺門檻提升至 40%',
      multiplierBonus: 0.3, newMechanic: SkillTierMechanic.executeThresholdUp, mechanicValue: 0.4,
      goldCost: 800, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.skillCore: 2},
    ),
    SkillTierDefinition(
      tier: 4, name: '焦糖烙印', description: '4.2x 傷害 + 灼燒 2 回合 (20% ATK)',
      multiplierBonus: 0.4, newMechanic: SkillTierMechanic.dot, mechanicValue: 0.2,
      goldCost: 1500, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.skillCore: 3, GameMaterial.rareShard: 1},
    ),
    SkillTierDefinition(
      tier: 5, name: '極致焦糖外送', description: '4.7x 傷害 + 擊殺全額退能量',
      multiplierBonus: 0.5, newMechanic: SkillTierMechanic.energyRefund, mechanicValue: -1,
      goldCost: 3000, materialCost: {GameMaterial.rareShard: 3, GameMaterial.skillCore: 5},
    ),
  ];

  // ─── 薄荷 Mint — 薄荷清風～ (supporter, heal) ───

  static const sproutSkillTiers = <SkillTierDefinition>[
    SkillTierDefinition(
      tier: 1, name: '薄荷清風～', description: '回復隊伍 18% HP',
      multiplierBonus: 0, goldCost: 0, materialCost: {},
    ),
    SkillTierDefinition(
      tier: 2, name: '清涼薄荷', description: '回復 20% HP',
      multiplierBonus: 2,
      goldCost: 300, materialCost: {GameMaterial.commonShard: 5, GameMaterial.skillCore: 1},
    ),
    SkillTierDefinition(
      tier: 3, name: '薄荷蔓延', description: '回復 23% HP + 延遲敵人 1 回合',
      multiplierBonus: 3, newMechanic: SkillTierMechanic.delayAdded, mechanicValue: 1,
      goldCost: 800, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.skillCore: 2},
    ),
    SkillTierDefinition(
      tier: 4, name: '薄荷綻放', description: '回復 26% HP + HoT 5%/回合 2 回合',
      multiplierBonus: 3, newMechanic: SkillTierMechanic.durationExtend, mechanicValue: 0.05,
      goldCost: 1500, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.skillCore: 3, GameMaterial.rareShard: 1},
    ),
    SkillTierDefinition(
      tier: 5, name: '極致薄荷清風', description: '回復 30% HP + 退還 2 能量',
      multiplierBonus: 4, newMechanic: SkillTierMechanic.energyRefund, mechanicValue: 2,
      goldCost: 3000, materialCost: {GameMaterial.rareShard: 3, GameMaterial.skillCore: 5},
    ),
  ];

  // ─── 肉桂 Cinnamon — 肉桂重擊！ (striker, damage) ───

  static const gaiaSkillTiers = <SkillTierDefinition>[
    SkillTierDefinition(
      tier: 1, name: '肉桂重擊！', description: '2.5x 單體傷害',
      multiplierBonus: 0, goldCost: 0, materialCost: {},
    ),
    SkillTierDefinition(
      tier: 2, name: '肉桂強化', description: '2.8x 傷害，香料增幅',
      multiplierBonus: 0.3,
      goldCost: 300, materialCost: {GameMaterial.commonShard: 5, GameMaterial.skillCore: 1},
    ),
    SkillTierDefinition(
      tier: 3, name: '肉桂餘韻', description: '3.1x 傷害 + 香料灼傷 2 回合 (15% ATK)',
      multiplierBonus: 0.3, newMechanic: SkillTierMechanic.dot, mechanicValue: 0.15,
      goldCost: 800, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.skillCore: 2},
    ),
    SkillTierDefinition(
      tier: 4, name: '肉桂擴散', description: '3.5x 傷害 + 30% 濺射傷害',
      multiplierBonus: 0.4, newMechanic: SkillTierMechanic.aoeSplash, mechanicValue: 0.3,
      goldCost: 1500, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.skillCore: 3, GameMaterial.rareShard: 1},
    ),
    SkillTierDefinition(
      tier: 5, name: '極致肉桂重擊', description: '4.0x 傷害 + 破防 (DEF -20%, 2 回合)',
      multiplierBonus: 0.5, newMechanic: SkillTierMechanic.defBreak, mechanicValue: 0.2,
      goldCost: 3000, materialCost: {GameMaterial.rareShard: 3, GameMaterial.skillCore: 5},
    ),
  ];

  // ─── 奶昔 Shake — 冰淇淋護盾！ (defender, shield) ───

  static const frostSkillTiers = <SkillTierDefinition>[
    SkillTierDefinition(
      tier: 1, name: '冰淇淋護盾！', description: '減傷 45%，持續 2 回合',
      multiplierBonus: 0, goldCost: 0, materialCost: {},
    ),
    SkillTierDefinition(
      tier: 2, name: '奶昔強化', description: '減傷 50%',
      multiplierBonus: 5,
      goldCost: 300, materialCost: {GameMaterial.commonShard: 5, GameMaterial.skillCore: 1},
    ),
    SkillTierDefinition(
      tier: 3, name: '冰凍奶昔', description: '減傷 55%，持續 3 回合',
      multiplierBonus: 5, newMechanic: SkillTierMechanic.durationExtend, mechanicValue: 1,
      goldCost: 800, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.skillCore: 2},
    ),
    SkillTierDefinition(
      tier: 4, name: '奶昔反擊', description: '減傷 60% + 反射 20% 傷害',
      multiplierBonus: 5, newMechanic: SkillTierMechanic.reflect, mechanicValue: 0.2,
      goldCost: 1500, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.skillCore: 3, GameMaterial.rareShard: 1},
    ),
    SkillTierDefinition(
      tier: 5, name: '極致冰淇淋護盾', description: '減傷 65% + 受擊凍傷 10% ATK',
      multiplierBonus: 5, newMechanic: SkillTierMechanic.dot, mechanicValue: 0.1,
      goldCost: 3000, materialCost: {GameMaterial.rareShard: 3, GameMaterial.skillCore: 5},
    ),
  ];

  // ─── 蘇打 Soda — 氣泡大爆發！ (destroyer, AOE) ───

  static const tsunamiSkillTiers = <SkillTierDefinition>[
    SkillTierDefinition(
      tier: 1, name: '氣泡大爆發！', description: '1.8x 全體傷害',
      multiplierBonus: 0, goldCost: 0, materialCost: {},
    ),
    SkillTierDefinition(
      tier: 2, name: '氣泡強化', description: '2.0x 全體傷害',
      multiplierBonus: 0.2,
      goldCost: 300, materialCost: {GameMaterial.commonShard: 5, GameMaterial.skillCore: 1},
    ),
    SkillTierDefinition(
      tier: 3, name: '氣泡破防', description: '2.2x 全體傷害 + 全體破防 -15%',
      multiplierBonus: 0.2, newMechanic: SkillTierMechanic.defBreak, mechanicValue: 0.15,
      goldCost: 800, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.skillCore: 2},
    ),
    SkillTierDefinition(
      tier: 4, name: '蘇打連鎖', description: '2.5x 全體 + 氣泡追擊 0.5x',
      multiplierBonus: 0.3, newMechanic: SkillTierMechanic.aoeSplash, mechanicValue: 0.5,
      goldCost: 1500, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.skillCore: 3, GameMaterial.rareShard: 1},
    ),
    SkillTierDefinition(
      tier: 5, name: '極致氣泡爆發', description: '2.8x 全體 + 擊殺退 3 能量',
      multiplierBonus: 0.3, newMechanic: SkillTierMechanic.energyRefund, mechanicValue: 3,
      goldCost: 3000, materialCost: {GameMaterial.rareShard: 3, GameMaterial.skillCore: 5},
    ),
  ];

  // ─── 棉花糖 Cotton — 棉花糖擁抱～ (supporter, heal) ───

  static const sparkSkillTiers = <SkillTierDefinition>[
    SkillTierDefinition(
      tier: 1, name: '棉花糖擁抱～', description: '回復隊伍 16% HP',
      multiplierBonus: 0, goldCost: 0, materialCost: {},
    ),
    SkillTierDefinition(
      tier: 2, name: '棉花糖膨脹', description: '回復 18% HP',
      multiplierBonus: 2,
      goldCost: 300, materialCost: {GameMaterial.commonShard: 5, GameMaterial.skillCore: 1},
    ),
    SkillTierDefinition(
      tier: 3, name: '棉花糖干擾', description: '回復 21% HP + 延遲敵人 1 回合',
      multiplierBonus: 3, newMechanic: SkillTierMechanic.delayAdded, mechanicValue: 1,
      goldCost: 800, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.skillCore: 2},
    ),
    SkillTierDefinition(
      tier: 4, name: '棉花糖再生', description: '回復 24% HP + HoT 5%/回合 2 回合',
      multiplierBonus: 3, newMechanic: SkillTierMechanic.durationExtend, mechanicValue: 0.05,
      goldCost: 1500, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.skillCore: 3, GameMaterial.rareShard: 1},
    ),
    SkillTierDefinition(
      tier: 5, name: '極致棉花糖擁抱', description: '回復 28% HP + 退還 2 能量',
      multiplierBonus: 4, newMechanic: SkillTierMechanic.energyRefund, mechanicValue: 2,
      goldCost: 3000, materialCost: {GameMaterial.rareShard: 3, GameMaterial.skillCore: 5},
    ),
  ];

  // ─── 可頌 Croissant — 可頌重錘！ (striker, damage) ───

  static const thunderSkillTiers = <SkillTierDefinition>[
    SkillTierDefinition(
      tier: 1, name: '可頌重錘！', description: '2.8x 單體傷害',
      multiplierBonus: 0, goldCost: 0, materialCost: {},
    ),
    SkillTierDefinition(
      tier: 2, name: '可頌強化', description: '3.1x 傷害，酥皮增幅',
      multiplierBonus: 0.3,
      goldCost: 300, materialCost: {GameMaterial.commonShard: 5, GameMaterial.skillCore: 1},
    ),
    SkillTierDefinition(
      tier: 3, name: '可頌碎裂', description: '3.4x 傷害 + 酥皮灼傷 2 回合 (15% ATK)',
      multiplierBonus: 0.3, newMechanic: SkillTierMechanic.dot, mechanicValue: 0.15,
      goldCost: 800, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.skillCore: 2},
    ),
    SkillTierDefinition(
      tier: 4, name: '可頌擴散', description: '3.8x 傷害 + 30% 濺射傷害',
      multiplierBonus: 0.4, newMechanic: SkillTierMechanic.aoeSplash, mechanicValue: 0.3,
      goldCost: 1500, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.skillCore: 3, GameMaterial.rareShard: 1},
    ),
    SkillTierDefinition(
      tier: 5, name: '極致可頌重錘', description: '4.3x 傷害 + 破防 (DEF -20%, 2 回合)',
      multiplierBonus: 0.5, newMechanic: SkillTierMechanic.defBreak, mechanicValue: 0.2,
      goldCost: 3000, materialCost: {GameMaterial.rareShard: 3, GameMaterial.skillCore: 5},
    ),
  ];

  // ─── 布丁 Pudding — 布丁彈力盾！ (defender, shield) ───

  static const phantomSkillTiers = <SkillTierDefinition>[
    SkillTierDefinition(
      tier: 1, name: '布丁彈力盾！', description: '減傷 40%，持續 2 回合',
      multiplierBonus: 0, goldCost: 0, materialCost: {},
    ),
    SkillTierDefinition(
      tier: 2, name: '布丁強化', description: '減傷 45%',
      multiplierBonus: 5,
      goldCost: 300, materialCost: {GameMaterial.commonShard: 5, GameMaterial.skillCore: 1},
    ),
    SkillTierDefinition(
      tier: 3, name: '布丁持續', description: '減傷 50%，持續 3 回合',
      multiplierBonus: 5, newMechanic: SkillTierMechanic.durationExtend, mechanicValue: 1,
      goldCost: 800, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.skillCore: 2},
    ),
    SkillTierDefinition(
      tier: 4, name: '布丁彈射', description: '減傷 55% + 反射 20% 傷害',
      multiplierBonus: 5, newMechanic: SkillTierMechanic.reflect, mechanicValue: 0.2,
      goldCost: 1500, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.skillCore: 3, GameMaterial.rareShard: 1},
    ),
    SkillTierDefinition(
      tier: 5, name: '極致布丁彈力盾', description: '減傷 60% + 受擊反彈 10% ATK',
      multiplierBonus: 5, newMechanic: SkillTierMechanic.dot, mechanicValue: 0.1,
      goldCost: 3000, materialCost: {GameMaterial.rareShard: 3, GameMaterial.skillCore: 5},
    ),
  ];

  // ─── 藍莓 Berry — 莓果大轟炸！ (destroyer, AOE) ───

  static const eclipseSkillTiers = <SkillTierDefinition>[
    SkillTierDefinition(
      tier: 1, name: '莓果大轟炸！', description: '1.6x 全體傷害',
      multiplierBonus: 0, goldCost: 0, materialCost: {},
    ),
    SkillTierDefinition(
      tier: 2, name: '莓果增幅', description: '1.8x 全體傷害',
      multiplierBonus: 0.2,
      goldCost: 300, materialCost: {GameMaterial.commonShard: 5, GameMaterial.skillCore: 1},
    ),
    SkillTierDefinition(
      tier: 3, name: '莓果破防', description: '2.0x 全體傷害 + 全體破防 -10%',
      multiplierBonus: 0.2, newMechanic: SkillTierMechanic.defBreak, mechanicValue: 0.1,
      goldCost: 800, materialCost: {GameMaterial.advancedShard: 3, GameMaterial.skillCore: 2},
    ),
    SkillTierDefinition(
      tier: 4, name: '莓果連鎖', description: '2.3x 全體 + 莓果追擊 0.4x',
      multiplierBonus: 0.3, newMechanic: SkillTierMechanic.aoeSplash, mechanicValue: 0.4,
      goldCost: 1500, materialCost: {GameMaterial.advancedShard: 5, GameMaterial.skillCore: 3, GameMaterial.rareShard: 1},
    ),
    SkillTierDefinition(
      tier: 5, name: '極致莓果轟炸', description: '2.6x 全體 + 擊殺退 3 能量',
      multiplierBonus: 0.3, newMechanic: SkillTierMechanic.energyRefund, mechanicValue: 3,
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
    'ember': emberSkillTiers,
    'inferno': infernoSkillTiers,
    'sprout': sproutSkillTiers,
    'gaia': gaiaSkillTiers,
    'frost': frostSkillTiers,
    'tsunami': tsunamiSkillTiers,
    'spark': sparkSkillTiers,
    'thunder': thunderSkillTiers,
    'phantom': phantomSkillTiers,
    'eclipse': eclipseSkillTiers,
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
