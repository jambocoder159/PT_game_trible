/// 關卡數據
/// MVP：第 1 章（麵包店）10 關 + 第 2 章（冰淇淋舖）10 關 + 第 3 章（巧克力工坊）10 關
import '../core/models/enemy.dart';
import '../core/models/cat_agent.dart';

/// 關卡定義
class StageDefinition {
  final String id; // 例如 "1-1"
  final String name;
  final int chapter;
  final int stageNumber;
  final int staminaCost;
  final int moveLimit; // 行動上限（0 = 無限）
  final List<EnemyDefinition> enemies;
  final StageReward reward;

  // 三星條件
  final int twoStarScore; // 達到此分數 = 2 星
  final int threeStarScore; // 達到此分數 = 3 星

  const StageDefinition({
    required this.id,
    required this.name,
    required this.chapter,
    required this.stageNumber,
    this.staminaCost = 5,
    this.moveLimit = 15,
    required this.enemies,
    required this.reward,
    this.twoStarScore = 500,
    this.threeStarScore = 1000,
  });
}

/// 關卡獎勵
class StageReward {
  final int gold;
  final int exp;
  final String? unlockAgentId; // 通關解鎖角色

  const StageReward({
    required this.gold,
    required this.exp,
    this.unlockAgentId,
  });
}

/// 章節資訊
class ChapterInfo {
  final int number;
  final String name;
  final String location;
  final String description;

  const ChapterInfo({
    required this.number,
    required this.name,
    required this.location,
    required this.description,
  });
}

class StageData {
  StageData._();

  // ─── 章節資訊 ───

  static const chapters = [
    ChapterInfo(
      number: 1,
      name: '爺爺的老麵包店',
      location: '甜點街上爺爺留下的老麵包店',
      description: '初次踏入地下室，清理發霉的麵包精靈',
    ),
    ChapterInfo(
      number: 2,
      name: '冰淇淋小舖',
      location: '甜點街上的冰品專賣店',
      description: '冷凍庫失控，地下室變成了冰晶洞窟',
    ),
    ChapterInfo(
      number: 3,
      name: '巧克力工坊',
      location: '甜點街上的可可巧克力工坊',
      description: '過熱的可可倉庫變成了焦糖熔岩地帶',
    ),
    ChapterInfo(
      number: 4,
      name: '蛋糕塔',
      location: '甜點街最高的建築——蛋糕塔',
      description: '堆滿硬邦邦老蛋糕的巨塔',
    ),
    ChapterInfo(
      number: 5,
      name: '和菓子茶屋',
      location: '甜點街尾的古風和菓子茶屋',
      description: '瀰漫過期茶葉氣息的神秘地下室',
    ),
    ChapterInfo(
      number: 6,
      name: '甜點街大廣場',
      location: '甜點街中心廣場下方的神秘地窖',
      description: '最終決戰 — 淨化黑暗料理王',
    ),
  ];

  // ─── 敵人定義（含技能配置）───

  // 第 1 章：爺爺的老麵包店（無技能）
  static const _rat = EnemyDefinition(
    id: 'rat', name: '發霉小餐包', emoji: '🍞',
    attribute: AgentAttribute.attributeB, baseHp: 160, baseAtk: 8, attackInterval: 3,
  );
  static const _bigRat = EnemyDefinition(
    id: 'big_rat', name: '焦黑法棍', emoji: '🥖',
    attribute: AgentAttribute.attributeB, baseHp: 320, baseAtk: 15, attackInterval: 3,
  );
  static const _wetBread = EnemyDefinition(
    id: 'wet_bread', name: '濕軟吐司', emoji: '🍞',
    attribute: AgentAttribute.attributeC, baseHp: 190, baseAtk: 12, attackInterval: 4,
  );
  static const _strayDog = EnemyDefinition(
    id: 'stray_dog', name: '酸掉牛角包', emoji: '🥐',
    attribute: AgentAttribute.attributeA, baseHp: 400, baseAtk: 20, attackInterval: 4,
  );
  static const _ratBoss = EnemyDefinition(
    id: 'rat_boss', name: '黴菌麵包王', emoji: '👑',
    attribute: AgentAttribute.attributeB, baseHp: 800, baseAtk: 25, attackInterval: 3,
    skills: [EnemySkillDefinition.shield(percent: 0.2)],
  );

  // 第 2 章：冰淇淋小舖（障礙方塊）
  static const _petShopGuard = EnemyDefinition(
    id: 'pet_shop_guard', name: '融化冰棒', emoji: '🍦',
    attribute: AgentAttribute.attributeC, baseHp: 320, baseAtk: 15, attackInterval: 3,
  );
  static const _trapDevice = EnemyDefinition(
    id: 'trap_device', name: '結冰糖漿', emoji: '🧊',
    attribute: AgentAttribute.attributeD, baseHp: 240, baseAtk: 25, attackInterval: 4,
    skills: [EnemySkillDefinition.obstacle(count: 2, cooldown: 4)],
  );
  static const _trapDeviceV2 = EnemyDefinition(
    id: 'trap_device_v2', name: '結冰糖漿', emoji: '🧊',
    attribute: AgentAttribute.attributeD, baseHp: 240, baseAtk: 25, attackInterval: 4,
    skills: [EnemySkillDefinition.obstacle(count: 3, cooldown: 4)],
  );
  static const _shopOwner = EnemyDefinition(
    id: 'shop_owner', name: '融化冰淇淋怪', emoji: '🍨',
    attribute: AgentAttribute.attributeE, baseHp: 960, baseAtk: 22, attackInterval: 3,
    skills: [
      EnemySkillDefinition.shield(percent: 0.25),
      EnemySkillDefinition.obstacle(count: 3, cooldown: 3),
    ],
  );

  // 第 3 章：巧克力工坊（蓄力重擊 + 倒數毒格 + 回血）
  static const _dockWorker = EnemyDefinition(
    id: 'dock_worker', name: '烤焦可可豆', emoji: '🫘',
    attribute: AgentAttribute.attributeA, baseHp: 480, baseAtk: 20, attackInterval: 3,
  );
  static const _dockWorkerPoison = EnemyDefinition(
    id: 'dock_worker_poison', name: '烤焦可可豆', emoji: '🫘',
    attribute: AgentAttribute.attributeA, baseHp: 480, baseAtk: 20, attackInterval: 3,
    skills: [EnemySkillDefinition.poison(count: 2, countdown: 3, cooldown: 4)],
  );
  static const _dockWorkerPoisonHeal = EnemyDefinition(
    id: 'dock_worker_ph', name: '烤焦可可豆', emoji: '🫘',
    attribute: AgentAttribute.attributeA, baseHp: 480, baseAtk: 20, attackInterval: 3,
    skills: [
      EnemySkillDefinition.poison(count: 2, countdown: 2, cooldown: 4),
      EnemySkillDefinition.heal(percent: 0.05, cooldown: 5),
    ],
  );
  static const _seagull = EnemyDefinition(
    id: 'seagull', name: '爆裂糖果', emoji: '🍬',
    attribute: AgentAttribute.attributeD, baseHp: 290, baseAtk: 30, attackInterval: 2,
    skills: [EnemySkillDefinition.charge()],
  );
  static const _seagullBoss = EnemyDefinition(
    id: 'seagull_boss', name: '烤焦巧克力魔', emoji: '🍫',
    attribute: AgentAttribute.attributeD, baseHp: 1280, baseAtk: 35, attackInterval: 3,
    skills: [
      EnemySkillDefinition.poison(count: 3, countdown: 2, cooldown: 3),
      EnemySkillDefinition.heal(percent: 0.08, cooldown: 4),
      EnemySkillDefinition.charge(),
    ],
  );

  // 第 4 章：蛋糕塔（弱化標記 + 狂暴）
  static const _securityBot = EnemyDefinition(
    id: 'security_bot', name: '硬掉的蛋糕', emoji: '🎂',
    attribute: AgentAttribute.attributeD, baseHp: 560, baseAtk: 28, attackInterval: 3,
  );
  static const _securityBotWeaken = EnemyDefinition(
    id: 'security_bot_w', name: '硬掉的蛋糕', emoji: '🎂',
    attribute: AgentAttribute.attributeD, baseHp: 560, baseAtk: 28, attackInterval: 3,
    skills: [EnemySkillDefinition.weaken(count: 3, cooldown: 4)],
  );
  static const _securityBotRage = EnemyDefinition(
    id: 'security_bot_r', name: '硬掉的蛋糕', emoji: '🎂',
    attribute: AgentAttribute.attributeD, baseHp: 560, baseAtk: 28, attackInterval: 3,
    skills: [EnemySkillDefinition.rage()],
  );
  static const _laserTrap = EnemyDefinition(
    id: 'laser_trap', name: '噴射鮮奶油', emoji: '🧁',
    attribute: AgentAttribute.attributeD, baseHp: 320, baseAtk: 40, attackInterval: 4,
    skills: [EnemySkillDefinition.obstacle(count: 3, cooldown: 4)],
  );
  static const _eliteSecurity = EnemyDefinition(
    id: 'elite_security', name: '結塊奶油怪', emoji: '🧈',
    attribute: AgentAttribute.attributeC, baseHp: 800, baseAtk: 30, attackInterval: 3,
    skills: [
      EnemySkillDefinition.shield(percent: 0.25),
      EnemySkillDefinition.rage(),
    ],
  );
  static const _ceo = EnemyDefinition(
    id: 'ceo', name: '酸掉鮮奶油怪', emoji: '🎂',
    attribute: AgentAttribute.attributeE, baseHp: 1600, baseAtk: 35, attackInterval: 3,
    skills: [
      EnemySkillDefinition.shield(percent: 0.35),
      EnemySkillDefinition.rage(),
      EnemySkillDefinition.charge(),
    ],
  );

  // 第 5 章：和菓子茶屋（屬性壓制 + 召喚）
  static const _shadowAgent = EnemyDefinition(
    id: 'shadow_agent_enemy', name: '變硬麻糬', emoji: '🍡',
    attribute: AgentAttribute.attributeE, baseHp: 640, baseAtk: 32, attackInterval: 3,
  );
  static const _shadowAgentAura = EnemyDefinition(
    id: 'shadow_agent_aura', name: '變硬麻糬', emoji: '🍡',
    attribute: AgentAttribute.attributeE, baseHp: 640, baseAtk: 32, attackInterval: 3,
    skills: [EnemySkillDefinition.aura(suppressed: AgentAttribute.attributeB)],
  );
  static const _shadowAgentWeaken = EnemyDefinition(
    id: 'shadow_agent_w', name: '變硬麻糬', emoji: '🍡',
    attribute: AgentAttribute.attributeE, baseHp: 640, baseAtk: 32, attackInterval: 3,
    skills: [EnemySkillDefinition.weaken(count: 3, cooldown: 4)],
  );
  static const _shadowSniper = EnemyDefinition(
    id: 'shadow_sniper', name: '爆炸紅豆', emoji: '🫘',
    attribute: AgentAttribute.attributeA, baseHp: 450, baseAtk: 45, attackInterval: 4,
    skills: [
      EnemySkillDefinition.charge(),
      EnemySkillDefinition.poison(count: 2, countdown: 3, cooldown: 4),
    ],
  );
  static const _shadowCommander = EnemyDefinition(
    id: 'shadow_commander', name: '變硬麻糬大王', emoji: '🍡',
    attribute: AgentAttribute.attributeE, baseHp: 1280, baseAtk: 38, attackInterval: 3,
    skills: [
      EnemySkillDefinition.shield(percent: 0.30),
      EnemySkillDefinition.summon(cooldown: 6, enemy: _shadowAgent),
    ],
  );
  static const _shadowCommanderBoss = EnemyDefinition(
    id: 'shadow_commander_boss', name: '變硬麻糬大王', emoji: '🍡',
    attribute: AgentAttribute.attributeE, baseHp: 1280, baseAtk: 38, attackInterval: 3,
    skills: [
      EnemySkillDefinition.shield(percent: 0.35),
      EnemySkillDefinition.aura(suppressed: AgentAttribute.attributeC),
      EnemySkillDefinition.heal(percent: 0.08, cooldown: 4),
      EnemySkillDefinition.summon(cooldown: 5, enemy: _shadowAgent),
    ],
  );

  // 第 6 章：甜點街大廣場（全機制混搭）
  static const _eliteGuard = EnemyDefinition(
    id: 'elite_guard', name: '腐壞水果塔', emoji: '🥧',
    attribute: AgentAttribute.attributeB, baseHp: 800, baseAtk: 35, attackInterval: 3,
    skills: [EnemySkillDefinition.obstacle(count: 3, cooldown: 4)],
  );
  static const _eliteGuardAura = EnemyDefinition(
    id: 'elite_guard_aura', name: '腐壞水果塔', emoji: '🥧',
    attribute: AgentAttribute.attributeB, baseHp: 800, baseAtk: 35, attackInterval: 3,
    skills: [
      EnemySkillDefinition.aura(suppressed: AgentAttribute.attributeB),
      EnemySkillDefinition.weaken(count: 4, cooldown: 4),
    ],
  );
  static const _heavyBot = EnemyDefinition(
    id: 'heavy_bot', name: '石化千層派', emoji: '🧱',
    attribute: AgentAttribute.attributeC, baseHp: 1120, baseAtk: 40, attackInterval: 4,
    skills: [
      EnemySkillDefinition.shield(percent: 0.25),
      EnemySkillDefinition.heal(percent: 0.05, cooldown: 5),
    ],
  );
  static const _heavyBotRage = EnemyDefinition(
    id: 'heavy_bot_rage', name: '石化千層派', emoji: '🧱',
    attribute: AgentAttribute.attributeC, baseHp: 1120, baseAtk: 40, attackInterval: 4,
    skills: [
      EnemySkillDefinition.shield(percent: 0.25),
      EnemySkillDefinition.heal(percent: 0.05, cooldown: 5),
      EnemySkillDefinition.rage(),
    ],
  );
  static const _finalBoss = EnemyDefinition(
    id: 'final_boss', name: '黑暗料理王', emoji: '😈',
    attribute: AgentAttribute.attributeE, baseHp: 2400, baseAtk: 45, attackInterval: 3,
    skills: [
      EnemySkillDefinition.shield(percent: 0.40),
      EnemySkillDefinition.obstacle(count: 4, cooldown: 3),
      EnemySkillDefinition.poison(count: 3, countdown: 2, cooldown: 3),
      EnemySkillDefinition.weaken(count: 4, cooldown: 4),
      EnemySkillDefinition.heal(percent: 0.10, cooldown: 3),
      EnemySkillDefinition.rage(),
      EnemySkillDefinition.charge(),
      EnemySkillDefinition.summon(cooldown: 5, enemy: _shadowAgent),
    ],
  );

  // ─── 關卡定義 ───

  static final List<StageDefinition> allStages = [
    // ═══ 第 1 章：爺爺的老麵包店（無技能教學）═══
    StageDefinition(id: '1-1', name: '推開店門', chapter: 1, stageNumber: 1,
      staminaCost: 4, moveLimit: 20, enemies: [_rat],
      reward: const StageReward(gold: 30, exp: 10),
      twoStarScore: 400, threeStarScore: 800),
    StageDefinition(id: '1-2', name: '麵粉倉巡查', chapter: 1, stageNumber: 2,
      staminaCost: 4, moveLimit: 20, enemies: [_rat, _rat],
      reward: const StageReward(gold: 40, exp: 15),
      twoStarScore: 500, threeStarScore: 1050),
    StageDefinition(id: '1-3', name: '發現第一位夥伴', chapter: 1, stageNumber: 3,
      staminaCost: 5, moveLimit: 16, enemies: [_wetBread, _bigRat],
      reward: const StageReward(gold: 50, exp: 20, unlockAgentId: 'tide'),
      twoStarScore: 650, threeStarScore: 1300),
    StageDefinition(id: '1-4', name: '清理烤箱', chapter: 1, stageNumber: 4,
      staminaCost: 5, moveLimit: 18, enemies: [_bigRat, _bigRat],
      reward: const StageReward(gold: 50, exp: 20),
      twoStarScore: 800, threeStarScore: 1550),
    // 修正：原本只有牛角包(400)比1-4低，改為小餐包+牛角包(560)
    StageDefinition(id: '1-5', name: '酸麵團來了！', chapter: 1, stageNumber: 5,
      staminaCost: 5, moveLimit: 18, enemies: [_rat, _strayDog],
      reward: const StageReward(gold: 60, exp: 25),
      twoStarScore: 800, threeStarScore: 1550),
    StageDefinition(id: '1-6', name: '追蹤黴菌源頭', chapter: 1, stageNumber: 6,
      staminaCost: 5, moveLimit: 16, enemies: [_rat, _strayDog],
      reward: const StageReward(gold: 60, exp: 25),
      twoStarScore: 900, threeStarScore: 1800),
    StageDefinition(id: '1-7', name: '地下室深處', chapter: 1, stageNumber: 7,
      staminaCost: 6, moveLimit: 16, enemies: [_bigRat, _strayDog],
      reward: const StageReward(gold: 70, exp: 30),
      twoStarScore: 1050, threeStarScore: 2100),
    StageDefinition(id: '1-8', name: '麵包堆裡的陷阱', chapter: 1, stageNumber: 8,
      staminaCost: 6, moveLimit: 15, enemies: [_bigRat, _bigRat, _rat],
      reward: const StageReward(gold: 70, exp: 30),
      twoStarScore: 1150, threeStarScore: 2350),
    StageDefinition(id: '1-9', name: '穀倉最深處', chapter: 1, stageNumber: 9,
      staminaCost: 6, moveLimit: 15, enemies: [_bigRat, _strayDog, _bigRat],
      reward: const StageReward(gold: 80, exp: 35),
      twoStarScore: 1300, threeStarScore: 2600),
    // Boss: 護盾教學
    StageDefinition(id: '1-10', name: '黴菌麵包王！', chapter: 1, stageNumber: 10,
      staminaCost: 8, moveLimit: 20, enemies: [_bigRat, _ratBoss],
      reward: const StageReward(gold: 150, exp: 50),
      twoStarScore: 1950, threeStarScore: 3900),

    // ═══ 第 2 章：冰淇淋小舖（障礙方塊）═══
    StageDefinition(id: '2-1', name: '冰櫃打開了', chapter: 2, stageNumber: 1,
      staminaCost: 5, moveLimit: 18, enemies: [_petShopGuard],
      reward: const StageReward(gold: 50, exp: 25),
      twoStarScore: 800, threeStarScore: 1550),
    StageDefinition(id: '2-2', name: '冷凍庫入口', chapter: 2, stageNumber: 2,
      staminaCost: 5, moveLimit: 18, enemies: [_petShopGuard, _petShopGuard],
      reward: const StageReward(gold: 60, exp: 30),
      twoStarScore: 900, threeStarScore: 1800),
    // 首次障礙教學（1隻糖漿帶障礙）
    StageDefinition(id: '2-3', name: '滑溜溜的走道', chapter: 2, stageNumber: 3,
      staminaCost: 6, moveLimit: 16, enemies: [_trapDevice, _petShopGuard],
      reward: const StageReward(gold: 60, exp: 30),
      twoStarScore: 900, threeStarScore: 1800),
    StageDefinition(id: '2-4', name: '冰晶洞窟探索', chapter: 2, stageNumber: 4,
      staminaCost: 6, moveLimit: 16, enemies: [_petShopGuard, _petShopGuard],
      reward: const StageReward(gold: 70, exp: 35),
      twoStarScore: 1050, threeStarScore: 2100),
    StageDefinition(id: '2-5', name: '追著融化的冰棒跑', chapter: 2, stageNumber: 5,
      staminaCost: 6, moveLimit: 16, enemies: [_petShopGuard, _trapDevice, _petShopGuard],
      reward: const StageReward(gold: 80, exp: 35),
      twoStarScore: 1150, threeStarScore: 2350),
    // 雙障礙源（HP低用技能補）
    StageDefinition(id: '2-6', name: '冰霜結界', chapter: 2, stageNumber: 6,
      staminaCost: 6, moveLimit: 15, enemies: [_trapDevice, _petShopGuard, _trapDevice],
      reward: const StageReward(gold: 80, exp: 35),
      twoStarScore: 1150, threeStarScore: 2350),
    StageDefinition(id: '2-7', name: '冰箱最裡層', chapter: 2, stageNumber: 7,
      staminaCost: 7, moveLimit: 15, enemies: [_petShopGuard, _petShopGuard, _petShopGuard],
      reward: const StageReward(gold: 90, exp: 40),
      twoStarScore: 1300, threeStarScore: 2600),
    // 障礙升級版（3格）
    StageDefinition(id: '2-8', name: '融化的甜筒河', chapter: 2, stageNumber: 8,
      staminaCost: 7, moveLimit: 15, enemies: [_trapDeviceV2, _trapDeviceV2, _petShopGuard],
      reward: const StageReward(gold: 90, exp: 40),
      twoStarScore: 1300, threeStarScore: 2600),
    StageDefinition(id: '2-9', name: '搶救最後的食材', chapter: 2, stageNumber: 9,
      staminaCost: 7, moveLimit: 15, enemies: [_petShopGuard, _trapDeviceV2, _petShopGuard, _trapDeviceV2],
      reward: const StageReward(gold: 100, exp: 45),
      twoStarScore: 1550, threeStarScore: 3100),
    // Boss: 護盾+障礙組合
    StageDefinition(id: '2-10', name: '融化冰淇淋怪！', chapter: 2, stageNumber: 10,
      staminaCost: 8, moveLimit: 20, enemies: [_petShopGuard, _shopOwner],
      reward: const StageReward(gold: 200, exp: 60),
      twoStarScore: 2350, threeStarScore: 4700),

    // ═══ 第 3 章：巧克力工坊（蓄力重擊 + 倒數毒格）═══
    StageDefinition(id: '3-1', name: '可可倉庫門口', chapter: 3, stageNumber: 1,
      staminaCost: 6, moveLimit: 18, enemies: [_dockWorker],
      reward: const StageReward(gold: 70, exp: 35),
      twoStarScore: 1050, threeStarScore: 2100),
    // 首次蓄力教學
    StageDefinition(id: '3-2', name: '可可豆迷宮', chapter: 3, stageNumber: 2,
      staminaCost: 6, moveLimit: 16, enemies: [_dockWorker, _seagull],
      reward: const StageReward(gold: 80, exp: 40),
      twoStarScore: 1150, threeStarScore: 2350),
    // 高壓：3隻蓄力快攻
    StageDefinition(id: '3-3', name: '跳跳糖大亂鬥', chapter: 3, stageNumber: 3,
      staminaCost: 6, moveLimit: 16, enemies: [_seagull, _seagull, _seagull],
      reward: const StageReward(gold: 80, exp: 40),
      twoStarScore: 1150, threeStarScore: 2350),
    // 首次毒格教學
    StageDefinition(id: '3-4', name: '焦糖熔岩區', chapter: 3, stageNumber: 4,
      staminaCost: 7, moveLimit: 16, enemies: [_dockWorkerPoison, _dockWorker],
      reward: const StageReward(gold: 90, exp: 45),
      twoStarScore: 1300, threeStarScore: 2600),
    // 雙機制混搭
    StageDefinition(id: '3-5', name: '深夜的工坊', chapter: 3, stageNumber: 5,
      staminaCost: 7, moveLimit: 15, enemies: [_dockWorkerPoison, _seagull, _dockWorker],
      reward: const StageReward(gold: 100, exp: 45),
      twoStarScore: 1450, threeStarScore: 2850),
    StageDefinition(id: '3-6', name: '巧克力瀑布', chapter: 3, stageNumber: 6,
      staminaCost: 7, moveLimit: 15, enemies: [_dockWorkerPoison, _dockWorkerPoison, _seagull],
      reward: const StageReward(gold: 100, exp: 50),
      twoStarScore: 1550, threeStarScore: 3100),
    StageDefinition(id: '3-7', name: '可可熔爐旁', chapter: 3, stageNumber: 7,
      staminaCost: 7, moveLimit: 15, enemies: [_seagull, _dockWorkerPoison, _seagull, _dockWorker],
      reward: const StageReward(gold: 110, exp: 50),
      twoStarScore: 1700, threeStarScore: 3400),
    // 首見回血（HP低用技能補）
    StageDefinition(id: '3-8', name: '烘焙爐深處', chapter: 3, stageNumber: 8,
      staminaCost: 8, moveLimit: 15, enemies: [_dockWorkerPoisonHeal, _dockWorkerPoisonHeal, _dockWorkerPoisonHeal],
      reward: const StageReward(gold: 110, exp: 50),
      twoStarScore: 1800, threeStarScore: 3650),
    StageDefinition(id: '3-9', name: '搶救可可原料', chapter: 3, stageNumber: 9,
      staminaCost: 8, moveLimit: 15, enemies: [_dockWorkerPoison, _seagull, _seagull, _dockWorkerPoison],
      reward: const StageReward(gold: 120, exp: 55),
      twoStarScore: 1950, threeStarScore: 3900),
    // Boss: 毒+回血+蓄力持久戰
    StageDefinition(id: '3-10', name: '烤焦巧克力魔！', chapter: 3, stageNumber: 10,
      staminaCost: 10, moveLimit: 22, enemies: [_dockWorkerPoison, _seagull, _seagullBoss],
      reward: const StageReward(gold: 300, exp: 80),
      twoStarScore: 3250, threeStarScore: 6500),

    // ═══ 第 4 章：蛋糕塔（弱化標記 + 狂暴）═══
    StageDefinition(id: '4-1', name: '蛋糕塔入口', chapter: 4, stageNumber: 1,
      staminaCost: 7, moveLimit: 18, enemies: [_securityBot],
      reward: const StageReward(gold: 90, exp: 45),
      twoStarScore: 1300, threeStarScore: 2600),
    // 舊機制複習：障礙
    StageDefinition(id: '4-2', name: '奶油電梯', chapter: 4, stageNumber: 2,
      staminaCost: 7, moveLimit: 16, enemies: [_securityBot, _laserTrap],
      reward: const StageReward(gold: 100, exp: 50),
      twoStarScore: 1450, threeStarScore: 2850),
    // 首次弱化教學
    StageDefinition(id: '4-3', name: '第二層蛋糕', chapter: 4, stageNumber: 3,
      staminaCost: 7, moveLimit: 16, enemies: [_securityBotWeaken, _securityBot],
      reward: const StageReward(gold: 100, exp: 50),
      twoStarScore: 1550, threeStarScore: 3100),
    // 障礙+弱化雙棋盤
    StageDefinition(id: '4-4', name: '鮮奶油陷阱房', chapter: 4, stageNumber: 4,
      staminaCost: 8, moveLimit: 16, enemies: [_laserTrap, _securityBotWeaken, _laserTrap],
      reward: const StageReward(gold: 110, exp: 55),
      twoStarScore: 1700, threeStarScore: 3400),
    // 首次狂暴！
    StageDefinition(id: '4-5', name: '奶油攪拌室', chapter: 4, stageNumber: 5,
      staminaCost: 8, moveLimit: 15, enemies: [_securityBot, _eliteSecurity],
      reward: const StageReward(gold: 120, exp: 55, unlockAgentId: 'flash'),
      twoStarScore: 1800, threeStarScore: 3650),
    // 障礙+弱化（HP低用棋盤壓力補）
    StageDefinition(id: '4-6', name: '糖霜管道', chapter: 4, stageNumber: 6,
      staminaCost: 8, moveLimit: 15, enemies: [_laserTrap, _laserTrap, _securityBotWeaken],
      reward: const StageReward(gold: 120, exp: 55),
      twoStarScore: 1950, threeStarScore: 3900),
    StageDefinition(id: '4-7', name: '蛋糕裝飾間', chapter: 4, stageNumber: 7,
      staminaCost: 8, moveLimit: 15, enemies: [_eliteSecurity, _securityBotWeaken, _securityBotWeaken],
      reward: const StageReward(gold: 130, exp: 60),
      twoStarScore: 2100, threeStarScore: 4150),
    // 雙狂暴
    StageDefinition(id: '4-8', name: '塔頂花園蛋糕', chapter: 4, stageNumber: 8,
      staminaCost: 9, moveLimit: 15, enemies: [_eliteSecurity, _laserTrap, _eliteSecurity],
      reward: const StageReward(gold: 130, exp: 60),
      twoStarScore: 2200, threeStarScore: 4400),
    StageDefinition(id: '4-9', name: '蛋糕塔頂端', chapter: 4, stageNumber: 9,
      staminaCost: 9, moveLimit: 15, enemies: [_securityBotRage, _eliteSecurity, _securityBotWeaken, _laserTrap],
      reward: const StageReward(gold: 140, exp: 65),
      twoStarScore: 2350, threeStarScore: 4700),
    // Boss: 護盾+狂暴+蓄力 階段轉換
    StageDefinition(id: '4-10', name: '酸掉鮮奶油怪！', chapter: 4, stageNumber: 10,
      staminaCost: 10, moveLimit: 22, enemies: [_eliteSecurity, _ceo],
      reward: const StageReward(gold: 350, exp: 100),
      twoStarScore: 3900, threeStarScore: 7800),

    // ═══ 第 5 章：和菓子茶屋（屬性壓制 + 召喚）═══
    StageDefinition(id: '5-1', name: '茶屋地下入口', chapter: 5, stageNumber: 1,
      staminaCost: 8, moveLimit: 18, enemies: [_shadowAgent],
      reward: const StageReward(gold: 110, exp: 55),
      twoStarScore: 1550, threeStarScore: 3100),
    // 舊機制複習：蓄力+毒
    StageDefinition(id: '5-2', name: '抹茶溪流旁', chapter: 5, stageNumber: 2,
      staminaCost: 8, moveLimit: 16, enemies: [_shadowAgent, _shadowSniper],
      reward: const StageReward(gold: 120, exp: 60),
      twoStarScore: 1700, threeStarScore: 3400),
    StageDefinition(id: '5-3', name: '紅豆伏擊！', chapter: 5, stageNumber: 3,
      staminaCost: 8, moveLimit: 16, enemies: [_shadowSniper, _shadowAgent, _shadowSniper],
      reward: const StageReward(gold: 120, exp: 60),
      twoStarScore: 1800, threeStarScore: 3650),
    // 首次屬性壓制
    StageDefinition(id: '5-4', name: '麻糬堆山', chapter: 5, stageNumber: 4,
      staminaCost: 9, moveLimit: 16, enemies: [_shadowAgentAura, _shadowAgent, _shadowAgent],
      reward: const StageReward(gold: 130, exp: 65),
      twoStarScore: 1950, threeStarScore: 3900),
    // 壓制+蓄力
    StageDefinition(id: '5-5', name: '茶道修練場', chapter: 5, stageNumber: 5,
      staminaCost: 9, moveLimit: 15, enemies: [_shadowSniper, _shadowAgentAura, _shadowSniper],
      reward: const StageReward(gold: 140, exp: 65),
      twoStarScore: 2100, threeStarScore: 4150),
    // 4敵全技能
    StageDefinition(id: '5-6', name: '和菓子迷宮', chapter: 5, stageNumber: 6,
      staminaCost: 9, moveLimit: 15, enemies: [_shadowAgentAura, _shadowSniper, _shadowAgentWeaken, _shadowSniper],
      reward: const StageReward(gold: 140, exp: 70),
      twoStarScore: 2200, threeStarScore: 4400),
    // 首次召喚
    StageDefinition(id: '5-7', name: '古老茶室', chapter: 5, stageNumber: 7,
      staminaCost: 9, moveLimit: 15, enemies: [_shadowAgentWeaken, _shadowAgent, _shadowCommander],
      reward: const StageReward(gold: 150, exp: 70),
      twoStarScore: 2350, threeStarScore: 4700),
    StageDefinition(id: '5-8', name: '紅豆炸彈倒數', chapter: 5, stageNumber: 8,
      staminaCost: 10, moveLimit: 14, enemies: [_shadowSniper, _shadowCommander, _shadowSniper],
      reward: const StageReward(gold: 150, exp: 75),
      twoStarScore: 2600, threeStarScore: 5200),
    StageDefinition(id: '5-9', name: '茶屋最深處', chapter: 5, stageNumber: 9,
      staminaCost: 10, moveLimit: 14, enemies: [_shadowAgentAura, _shadowSniper, _shadowAgent, _shadowCommander],
      reward: const StageReward(gold: 160, exp: 75),
      twoStarScore: 2850, threeStarScore: 5700),
    // Boss: 護盾+壓制+回血+召喚
    StageDefinition(id: '5-10', name: '變硬麻糬大王！', chapter: 5, stageNumber: 10,
      staminaCost: 12, moveLimit: 22, enemies: [_shadowAgent, _shadowSniper, _shadowCommanderBoss],
      reward: const StageReward(gold: 400, exp: 120),
      twoStarScore: 4550, threeStarScore: 9100),

    // ═══ 第 6 章：甜點街大廣場（全機制總匯）═══
    StageDefinition(id: '6-1', name: '大廣場地窖入口', chapter: 6, stageNumber: 1,
      staminaCost: 9, moveLimit: 18, enemies: [_eliteGuard, _eliteGuard],
      reward: const StageReward(gold: 130, exp: 65),
      twoStarScore: 1950, threeStarScore: 3900),
    StageDefinition(id: '6-2', name: '黑暗甜點走廊', chapter: 6, stageNumber: 2,
      staminaCost: 9, moveLimit: 16, enemies: [_eliteGuard, _heavyBot],
      reward: const StageReward(gold: 140, exp: 70),
      twoStarScore: 2200, threeStarScore: 4400),
    StageDefinition(id: '6-3', name: '壞掉的食材庫', chapter: 6, stageNumber: 3,
      staminaCost: 10, moveLimit: 16, enemies: [_heavyBot, _eliteGuard, _heavyBot],
      reward: const StageReward(gold: 150, exp: 75),
      twoStarScore: 2450, threeStarScore: 4950),
    // 壓制+護盾+弱化
    StageDefinition(id: '6-4', name: '黑暗料理實驗室', chapter: 6, stageNumber: 4,
      staminaCost: 10, moveLimit: 16, enemies: [_securityBotWeaken, _heavyBot, _eliteGuardAura],
      reward: const StageReward(gold: 150, exp: 75),
      twoStarScore: 2600, threeStarScore: 5200),
    // 狂暴坦克
    StageDefinition(id: '6-5', name: '腐敗能量核心', chapter: 6, stageNumber: 5,
      staminaCost: 10, moveLimit: 15, enemies: [_heavyBotRage, _heavyBotRage, _eliteGuardAura],
      reward: const StageReward(gold: 160, exp: 80),
      twoStarScore: 2850, threeStarScore: 5700),
    // 跨章機制混搭
    StageDefinition(id: '6-6', name: '食物精靈祭壇', chapter: 6, stageNumber: 6,
      staminaCost: 10, moveLimit: 15, enemies: [_eliteGuard, _shadowAgentAura, _heavyBot, _shadowAgentWeaken],
      reward: const StageReward(gold: 170, exp: 80),
      twoStarScore: 3100, threeStarScore: 6250),
    // 棋盤+戰鬥雙壓
    StageDefinition(id: '6-7', name: '最後的考驗', chapter: 6, stageNumber: 7,
      staminaCost: 11, moveLimit: 15, enemies: [_laserTrap, _heavyBotRage, _laserTrap, _eliteGuardAura],
      reward: const StageReward(gold: 170, exp: 85),
      twoStarScore: 3250, threeStarScore: 6500),
    // Boss級前哨
    StageDefinition(id: '6-8', name: '黑暗料理王的前廳', chapter: 6, stageNumber: 8,
      staminaCost: 11, moveLimit: 14, enemies: [_shadowCommander, _eliteGuardAura, _heavyBotRage],
      reward: const StageReward(gold: 180, exp: 85),
      twoStarScore: 3500, threeStarScore: 7000),
    // 最後防線
    StageDefinition(id: '6-9', name: '最後的防線', chapter: 6, stageNumber: 9,
      staminaCost: 12, moveLimit: 14, enemies: [_heavyBotRage, _shadowCommander, _heavyBot, _eliteGuardAura],
      reward: const StageReward(gold: 200, exp: 90),
      twoStarScore: 3900, threeStarScore: 7800),
    // 最終Boss: 三階段黑暗料理王
    StageDefinition(id: '6-10', name: '黑暗料理王！', chapter: 6, stageNumber: 10,
      staminaCost: 15, moveLimit: 25, enemies: [_shadowCommander, _heavyBot, _finalBoss],
      reward: const StageReward(gold: 500, exp: 150),
      twoStarScore: 6500, threeStarScore: 13000),
  ];

  /// 取得指定章節的關卡
  static List<StageDefinition> getChapterStages(int chapter) {
    return allStages.where((s) => s.chapter == chapter).toList();
  }

  /// 根據 ID 查找關卡
  static StageDefinition? getById(String id) {
    try {
      return allStages.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }
}
