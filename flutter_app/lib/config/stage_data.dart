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

  // ─── 敵人定義 ───

  // 第 1 章：爺爺的老麵包店
  static const _rat = EnemyDefinition(
    id: 'rat',
    name: '發霉小餐包',
    emoji: '🍞',
    attribute: AgentAttribute.attributeB,
    baseHp: 100,
    baseAtk: 8,
    attackInterval: 3,
  );

  static const _bigRat = EnemyDefinition(
    id: 'big_rat',
    name: '焦黑法棍',
    emoji: '🥖',
    attribute: AgentAttribute.attributeB,
    baseHp: 200,
    baseAtk: 15,
    attackInterval: 3,
  );

  static const _strayDog = EnemyDefinition(
    id: 'stray_dog',
    name: '酸掉牛角包',
    emoji: '🥐',
    attribute: AgentAttribute.attributeA,
    baseHp: 250,
    baseAtk: 20,
    attackInterval: 4,
  );

  static const _ratBoss = EnemyDefinition(
    id: 'rat_boss',
    name: '黴菌麵包王',
    emoji: '👑',
    attribute: AgentAttribute.attributeB,
    baseHp: 500,
    baseAtk: 25,
    attackInterval: 3,
  );

  // 第 2 章：冰淇淋小舖
  static const _petShopGuard = EnemyDefinition(
    id: 'pet_shop_guard',
    name: '融化冰棒',
    emoji: '🍦',
    attribute: AgentAttribute.attributeC,
    baseHp: 200,
    baseAtk: 15,
    attackInterval: 3,
  );

  static const _trapDevice = EnemyDefinition(
    id: 'trap_device',
    name: '結冰糖漿',
    emoji: '🧊',
    attribute: AgentAttribute.attributeD,
    baseHp: 150,
    baseAtk: 25,
    attackInterval: 4,
  );

  static const _shopOwner = EnemyDefinition(
    id: 'shop_owner',
    name: '融化冰淇淋怪',
    emoji: '🍨',
    attribute: AgentAttribute.attributeE,
    baseHp: 600,
    baseAtk: 22,
    attackInterval: 3,
  );

  // 第 3 章：巧克力工坊
  static const _dockWorker = EnemyDefinition(
    id: 'dock_worker',
    name: '烤焦可可豆',
    emoji: '🫘',
    attribute: AgentAttribute.attributeA,
    baseHp: 300,
    baseAtk: 20,
    attackInterval: 3,
  );

  static const _seagull = EnemyDefinition(
    id: 'seagull',
    name: '爆裂糖果',
    emoji: '🍬',
    attribute: AgentAttribute.attributeD,
    baseHp: 180,
    baseAtk: 30,
    attackInterval: 2,
  );

  static const _seagullBoss = EnemyDefinition(
    id: 'seagull_boss',
    name: '烤焦巧克力魔',
    emoji: '🍫',
    attribute: AgentAttribute.attributeD,
    baseHp: 800,
    baseAtk: 35,
    attackInterval: 3,
  );

  // 第 4 章：蛋糕塔
  static const _securityBot = EnemyDefinition(
    id: 'security_bot',
    name: '硬掉的蛋糕',
    emoji: '🎂',
    attribute: AgentAttribute.attributeD,
    baseHp: 350,
    baseAtk: 28,
    attackInterval: 3,
  );

  static const _laserTrap = EnemyDefinition(
    id: 'laser_trap',
    name: '噴射鮮奶油',
    emoji: '🧁',
    attribute: AgentAttribute.attributeD,
    baseHp: 200,
    baseAtk: 40,
    attackInterval: 4,
  );

  static const _eliteSecurity = EnemyDefinition(
    id: 'elite_security',
    name: '結塊奶油怪',
    emoji: '🧈',
    attribute: AgentAttribute.attributeC,
    baseHp: 500,
    baseAtk: 30,
    attackInterval: 3,
  );

  static const _ceo = EnemyDefinition(
    id: 'ceo',
    name: '酸掉鮮奶油怪',
    emoji: '🎂',
    attribute: AgentAttribute.attributeE,
    baseHp: 1000,
    baseAtk: 35,
    attackInterval: 3,
  );

  // 第 5 章：和菓子茶屋
  static const _shadowAgent = EnemyDefinition(
    id: 'shadow_agent_enemy',
    name: '變硬麻糬',
    emoji: '🍡',
    attribute: AgentAttribute.attributeE,
    baseHp: 400,
    baseAtk: 32,
    attackInterval: 3,
  );

  static const _shadowSniper = EnemyDefinition(
    id: 'shadow_sniper',
    name: '爆炸紅豆',
    emoji: '🫘',
    attribute: AgentAttribute.attributeA,
    baseHp: 280,
    baseAtk: 45,
    attackInterval: 4,
  );

  static const _shadowCommander = EnemyDefinition(
    id: 'shadow_commander',
    name: '變硬麻糬大王',
    emoji: '🍡',
    attribute: AgentAttribute.attributeE,
    baseHp: 800,
    baseAtk: 38,
    attackInterval: 3,
  );

  // 第 6 章：甜點街大廣場
  static const _eliteGuard = EnemyDefinition(
    id: 'elite_guard',
    name: '腐壞水果塔',
    emoji: '🥧',
    attribute: AgentAttribute.attributeB,
    baseHp: 500,
    baseAtk: 35,
    attackInterval: 3,
  );

  static const _heavyBot = EnemyDefinition(
    id: 'heavy_bot',
    name: '石化千層派',
    emoji: '🧱',
    attribute: AgentAttribute.attributeC,
    baseHp: 700,
    baseAtk: 40,
    attackInterval: 4,
  );

  static const _finalBoss = EnemyDefinition(
    id: 'final_boss',
    name: '黑暗料理王',
    emoji: '😈',
    attribute: AgentAttribute.attributeE,
    baseHp: 1500,
    baseAtk: 45,
    attackInterval: 3,
  );

  // ─── 關卡定義 ───

  static final List<StageDefinition> allStages = [
    // ═══ 第 1 章：爺爺的老麵包店 ═══
    StageDefinition(
      id: '1-1',
      name: '推開店門',
      chapter: 1,
      stageNumber: 1,
      staminaCost: 4,
      moveLimit: 20,
      enemies: [_rat],
      reward: const StageReward(gold: 30, exp: 10),
      twoStarScore: 300,
      threeStarScore: 600,
    ),
    StageDefinition(
      id: '1-2',
      name: '麵粉倉巡查',
      chapter: 1,
      stageNumber: 2,
      staminaCost: 4,
      moveLimit: 20,
      enemies: [_rat, _rat],
      reward: const StageReward(gold: 40, exp: 15),
      twoStarScore: 400,
      threeStarScore: 800,
    ),
    StageDefinition(
      id: '1-3',
      name: '發現第一位夥伴',
      chapter: 1,
      stageNumber: 3,
      staminaCost: 5,
      moveLimit: 18,
      enemies: [_rat, _bigRat],
      reward: const StageReward(gold: 50, exp: 20, unlockAgentId: 'tide'),
      twoStarScore: 500,
      threeStarScore: 1000,
    ),
    StageDefinition(
      id: '1-4',
      name: '清理烤箱',
      chapter: 1,
      stageNumber: 4,
      staminaCost: 5,
      moveLimit: 18,
      enemies: [_bigRat, _bigRat],
      reward: const StageReward(gold: 50, exp: 20),
      twoStarScore: 600,
      threeStarScore: 1200,
    ),
    StageDefinition(
      id: '1-5',
      name: '酸麵團來了！',
      chapter: 1,
      stageNumber: 5,
      staminaCost: 5,
      moveLimit: 18,
      enemies: [_strayDog],
      reward: const StageReward(gold: 60, exp: 25),
      twoStarScore: 600,
      threeStarScore: 1200,
    ),
    StageDefinition(
      id: '1-6',
      name: '追蹤黴菌源頭',
      chapter: 1,
      stageNumber: 6,
      staminaCost: 5,
      moveLimit: 16,
      enemies: [_rat, _strayDog],
      reward: const StageReward(gold: 60, exp: 25),
      twoStarScore: 700,
      threeStarScore: 1400,
    ),
    StageDefinition(
      id: '1-7',
      name: '地下室深處',
      chapter: 1,
      stageNumber: 7,
      staminaCost: 6,
      moveLimit: 16,
      enemies: [_bigRat, _strayDog],
      reward: const StageReward(gold: 70, exp: 30),
      twoStarScore: 800,
      threeStarScore: 1600,
    ),
    StageDefinition(
      id: '1-8',
      name: '麵包堆裡的陷阱',
      chapter: 1,
      stageNumber: 8,
      staminaCost: 6,
      moveLimit: 15,
      enemies: [_bigRat, _bigRat, _rat],
      reward: const StageReward(gold: 70, exp: 30),
      twoStarScore: 900,
      threeStarScore: 1800,
    ),
    StageDefinition(
      id: '1-9',
      name: '穀倉最深處',
      chapter: 1,
      stageNumber: 9,
      staminaCost: 6,
      moveLimit: 15,
      enemies: [_bigRat, _strayDog, _bigRat],
      reward: const StageReward(gold: 80, exp: 35),
      twoStarScore: 1000,
      threeStarScore: 2000,
    ),
    StageDefinition(
      id: '1-10',
      name: '黴菌麵包王！',
      chapter: 1,
      stageNumber: 10,
      staminaCost: 8,
      moveLimit: 20,
      enemies: [_bigRat, _ratBoss],
      reward: const StageReward(gold: 150, exp: 50),
      twoStarScore: 1500,
      threeStarScore: 3000,
    ),

    // ═══ 第 2 章：冰淇淋小舖 ═══
    StageDefinition(
      id: '2-1',
      name: '冰櫃打開了',
      chapter: 2,
      stageNumber: 1,
      staminaCost: 5,
      moveLimit: 18,
      enemies: [_petShopGuard],
      reward: const StageReward(gold: 50, exp: 25),
      twoStarScore: 600,
      threeStarScore: 1200,
    ),
    StageDefinition(
      id: '2-2',
      name: '冷凍庫入口',
      chapter: 2,
      stageNumber: 2,
      staminaCost: 5,
      moveLimit: 18,
      enemies: [_petShopGuard, _trapDevice],
      reward: const StageReward(gold: 60, exp: 30),
      twoStarScore: 700,
      threeStarScore: 1400,
    ),
    StageDefinition(
      id: '2-3',
      name: '滑溜溜的走道',
      chapter: 2,
      stageNumber: 3,
      staminaCost: 6,
      moveLimit: 16,
      enemies: [_trapDevice, _trapDevice],
      reward: const StageReward(gold: 60, exp: 30),
      twoStarScore: 700,
      threeStarScore: 1400,
    ),
    StageDefinition(
      id: '2-4',
      name: '冰晶洞窟探索',
      chapter: 2,
      stageNumber: 4,
      staminaCost: 6,
      moveLimit: 16,
      enemies: [_petShopGuard, _petShopGuard],
      reward: const StageReward(gold: 70, exp: 35),
      twoStarScore: 800,
      threeStarScore: 1600,
    ),
    StageDefinition(
      id: '2-5',
      name: '追著融化的冰棒跑',
      chapter: 2,
      stageNumber: 5,
      staminaCost: 6,
      moveLimit: 16,
      enemies: [_petShopGuard, _trapDevice, _petShopGuard],
      reward: const StageReward(gold: 80, exp: 35),
      twoStarScore: 900,
      threeStarScore: 1800,
    ),
    StageDefinition(
      id: '2-6',
      name: '冰霜結界',
      chapter: 2,
      stageNumber: 6,
      staminaCost: 6,
      moveLimit: 15,
      enemies: [_trapDevice, _petShopGuard, _trapDevice],
      reward: const StageReward(gold: 80, exp: 35),
      twoStarScore: 900,
      threeStarScore: 1800,
    ),
    StageDefinition(
      id: '2-7',
      name: '冰箱最裡層',
      chapter: 2,
      stageNumber: 7,
      staminaCost: 7,
      moveLimit: 15,
      enemies: [_petShopGuard, _petShopGuard, _petShopGuard],
      reward: const StageReward(gold: 90, exp: 40),
      twoStarScore: 1000,
      threeStarScore: 2000,
    ),
    StageDefinition(
      id: '2-8',
      name: '融化的甜筒河',
      chapter: 2,
      stageNumber: 8,
      staminaCost: 7,
      moveLimit: 15,
      enemies: [_trapDevice, _trapDevice, _petShopGuard],
      reward: const StageReward(gold: 90, exp: 40),
      twoStarScore: 1000,
      threeStarScore: 2000,
    ),
    StageDefinition(
      id: '2-9',
      name: '搶救最後的食材',
      chapter: 2,
      stageNumber: 9,
      staminaCost: 7,
      moveLimit: 15,
      enemies: [_petShopGuard, _trapDevice, _petShopGuard, _trapDevice],
      reward: const StageReward(gold: 100, exp: 45),
      twoStarScore: 1200,
      threeStarScore: 2400,
    ),
    StageDefinition(
      id: '2-10',
      name: '融化冰淇淋怪！',
      chapter: 2,
      stageNumber: 10,
      staminaCost: 8,
      moveLimit: 20,
      enemies: [_petShopGuard, _shopOwner],
      reward: const StageReward(gold: 200, exp: 60),
      twoStarScore: 1800,
      threeStarScore: 3600,
    ),

    // ═══ 第 3 章：巧克力工坊 ═══
    StageDefinition(
      id: '3-1',
      name: '可可倉庫門口',
      chapter: 3,
      stageNumber: 1,
      staminaCost: 6,
      moveLimit: 18,
      enemies: [_dockWorker],
      reward: const StageReward(gold: 70, exp: 35),
      twoStarScore: 800,
      threeStarScore: 1600,
    ),
    StageDefinition(
      id: '3-2',
      name: '可可豆迷宮',
      chapter: 3,
      stageNumber: 2,
      staminaCost: 6,
      moveLimit: 16,
      enemies: [_dockWorker, _seagull],
      reward: const StageReward(gold: 80, exp: 40),
      twoStarScore: 900,
      threeStarScore: 1800,
    ),
    StageDefinition(
      id: '3-3',
      name: '跳跳糖大亂鬥',
      chapter: 3,
      stageNumber: 3,
      staminaCost: 6,
      moveLimit: 16,
      enemies: [_seagull, _seagull, _seagull],
      reward: const StageReward(gold: 80, exp: 40),
      twoStarScore: 900,
      threeStarScore: 1800,
    ),
    StageDefinition(
      id: '3-4',
      name: '走私倉庫',
      chapter: 3,
      stageNumber: 4,
      staminaCost: 7,
      moveLimit: 16,
      enemies: [_dockWorker, _dockWorker],
      reward: const StageReward(gold: 90, exp: 45),
      twoStarScore: 1000,
      threeStarScore: 2000,
    ),
    StageDefinition(
      id: '3-5',
      name: '夜間行動',
      chapter: 3,
      stageNumber: 5,
      staminaCost: 7,
      moveLimit: 15,
      enemies: [_dockWorker, _seagull, _dockWorker],
      reward: const StageReward(gold: 100, exp: 45),
      twoStarScore: 1100,
      threeStarScore: 2200,
    ),
    StageDefinition(
      id: '3-6',
      name: '船艙搜查',
      chapter: 3,
      stageNumber: 6,
      staminaCost: 7,
      moveLimit: 15,
      enemies: [_dockWorker, _dockWorker, _seagull],
      reward: const StageReward(gold: 100, exp: 50),
      twoStarScore: 1200,
      threeStarScore: 2400,
    ),
    StageDefinition(
      id: '3-7',
      name: '甲板戰鬥',
      chapter: 3,
      stageNumber: 7,
      staminaCost: 7,
      moveLimit: 15,
      enemies: [_seagull, _dockWorker, _seagull, _dockWorker],
      reward: const StageReward(gold: 110, exp: 50),
      twoStarScore: 1300,
      threeStarScore: 2600,
    ),
    StageDefinition(
      id: '3-8',
      name: '引擎室',
      chapter: 3,
      stageNumber: 8,
      staminaCost: 8,
      moveLimit: 15,
      enemies: [_dockWorker, _dockWorker, _dockWorker],
      reward: const StageReward(gold: 110, exp: 50),
      twoStarScore: 1400,
      threeStarScore: 2800,
    ),
    StageDefinition(
      id: '3-9',
      name: '貨物攔截',
      chapter: 3,
      stageNumber: 9,
      staminaCost: 8,
      moveLimit: 15,
      enemies: [_dockWorker, _seagull, _seagull, _dockWorker],
      reward: StageReward(gold: 120, exp: 55),
      twoStarScore: 1500,
      threeStarScore: 3000,
    ),
    StageDefinition(
      id: '3-10',
      name: '海鷗王',
      chapter: 3,
      stageNumber: 10,
      staminaCost: 10,
      moveLimit: 22,
      enemies: [_dockWorker, _seagull, _seagullBoss],
      reward: const StageReward(gold: 300, exp: 80),
      twoStarScore: 2500,
      threeStarScore: 5000,
    ),

    // ═══ 第 4 章：摩天大樓 ═══
    StageDefinition(id: '4-1', name: '大廳潛入', chapter: 4, stageNumber: 1,
      staminaCost: 7, moveLimit: 18,
      enemies: [_securityBot],
      reward: const StageReward(gold: 90, exp: 45),
      twoStarScore: 1000, threeStarScore: 2000),
    StageDefinition(id: '4-2', name: '電梯井', chapter: 4, stageNumber: 2,
      staminaCost: 7, moveLimit: 16,
      enemies: [_securityBot, _laserTrap],
      reward: const StageReward(gold: 100, exp: 50),
      twoStarScore: 1100, threeStarScore: 2200),
    StageDefinition(id: '4-3', name: '辦公室搜查', chapter: 4, stageNumber: 3,
      staminaCost: 7, moveLimit: 16,
      enemies: [_securityBot, _securityBot],
      reward: const StageReward(gold: 100, exp: 50),
      twoStarScore: 1200, threeStarScore: 2400),
    StageDefinition(id: '4-4', name: '監控室', chapter: 4, stageNumber: 4,
      staminaCost: 8, moveLimit: 16,
      enemies: [_laserTrap, _securityBot, _laserTrap],
      reward: const StageReward(gold: 110, exp: 55),
      twoStarScore: 1300, threeStarScore: 2600),
    StageDefinition(id: '4-5', name: '伺服器機房', chapter: 4, stageNumber: 5,
      staminaCost: 8, moveLimit: 15,
      enemies: [_securityBot, _eliteSecurity],
      reward: const StageReward(gold: 120, exp: 55, unlockAgentId: 'flash'),
      twoStarScore: 1400, threeStarScore: 2800),
    StageDefinition(id: '4-6', name: '通風管道', chapter: 4, stageNumber: 6,
      staminaCost: 8, moveLimit: 15,
      enemies: [_laserTrap, _laserTrap, _securityBot],
      reward: const StageReward(gold: 120, exp: 55),
      twoStarScore: 1500, threeStarScore: 3000),
    StageDefinition(id: '4-7', name: '會議室突襲', chapter: 4, stageNumber: 7,
      staminaCost: 8, moveLimit: 15,
      enemies: [_eliteSecurity, _securityBot, _securityBot],
      reward: const StageReward(gold: 130, exp: 60),
      twoStarScore: 1600, threeStarScore: 3200),
    StageDefinition(id: '4-8', name: '頂樓花園', chapter: 4, stageNumber: 8,
      staminaCost: 9, moveLimit: 15,
      enemies: [_eliteSecurity, _laserTrap, _eliteSecurity],
      reward: const StageReward(gold: 130, exp: 60),
      twoStarScore: 1700, threeStarScore: 3400),
    StageDefinition(id: '4-9', name: '直升機坪', chapter: 4, stageNumber: 9,
      staminaCost: 9, moveLimit: 15,
      enemies: [_securityBot, _eliteSecurity, _securityBot, _laserTrap],
      reward: const StageReward(gold: 140, exp: 65),
      twoStarScore: 1800, threeStarScore: 3600),
    StageDefinition(id: '4-10', name: '幕後金主', chapter: 4, stageNumber: 10,
      staminaCost: 10, moveLimit: 22,
      enemies: [_eliteSecurity, _ceo],
      reward: const StageReward(gold: 350, exp: 100),
      twoStarScore: 3000, threeStarScore: 6000),

    // ═══ 第 5 章：地下鐵 ═══
    StageDefinition(id: '5-1', name: '廢棄車站', chapter: 5, stageNumber: 1,
      staminaCost: 8, moveLimit: 18,
      enemies: [_shadowAgent],
      reward: const StageReward(gold: 110, exp: 55),
      twoStarScore: 1200, threeStarScore: 2400),
    StageDefinition(id: '5-2', name: '隧道追蹤', chapter: 5, stageNumber: 2,
      staminaCost: 8, moveLimit: 16,
      enemies: [_shadowAgent, _shadowSniper],
      reward: const StageReward(gold: 120, exp: 60),
      twoStarScore: 1300, threeStarScore: 2600),
    StageDefinition(id: '5-3', name: '月台伏擊', chapter: 5, stageNumber: 3,
      staminaCost: 8, moveLimit: 16,
      enemies: [_shadowSniper, _shadowAgent, _shadowSniper],
      reward: const StageReward(gold: 120, exp: 60),
      twoStarScore: 1400, threeStarScore: 2800),
    StageDefinition(id: '5-4', name: '列車頂部', chapter: 5, stageNumber: 4,
      staminaCost: 9, moveLimit: 16,
      enemies: [_shadowAgent, _shadowAgent, _shadowAgent],
      reward: const StageReward(gold: 130, exp: 65),
      twoStarScore: 1500, threeStarScore: 3000),
    StageDefinition(id: '5-5', name: '訊號室', chapter: 5, stageNumber: 5,
      staminaCost: 9, moveLimit: 15,
      enemies: [_shadowSniper, _shadowAgent, _shadowSniper],
      reward: const StageReward(gold: 140, exp: 65),
      twoStarScore: 1600, threeStarScore: 3200),
    StageDefinition(id: '5-6', name: '地下水道', chapter: 5, stageNumber: 6,
      staminaCost: 9, moveLimit: 15,
      enemies: [_shadowAgent, _shadowSniper, _shadowAgent, _shadowSniper],
      reward: const StageReward(gold: 140, exp: 70),
      twoStarScore: 1700, threeStarScore: 3400),
    StageDefinition(id: '5-7', name: '秘密通訊站', chapter: 5, stageNumber: 7,
      staminaCost: 9, moveLimit: 15,
      enemies: [_shadowAgent, _shadowAgent, _shadowCommander],
      reward: const StageReward(gold: 150, exp: 70),
      twoStarScore: 1800, threeStarScore: 3600),
    StageDefinition(id: '5-8', name: '爆破倒數', chapter: 5, stageNumber: 8,
      staminaCost: 10, moveLimit: 14,
      enemies: [_shadowSniper, _shadowCommander, _shadowSniper],
      reward: const StageReward(gold: 150, exp: 75),
      twoStarScore: 2000, threeStarScore: 4000),
    StageDefinition(id: '5-9', name: '最終列車', chapter: 5, stageNumber: 9,
      staminaCost: 10, moveLimit: 14,
      enemies: [_shadowAgent, _shadowSniper, _shadowAgent, _shadowCommander],
      reward: const StageReward(gold: 160, exp: 75),
      twoStarScore: 2200, threeStarScore: 4400),
    StageDefinition(id: '5-10', name: '暗影指揮官', chapter: 5, stageNumber: 10,
      staminaCost: 12, moveLimit: 22,
      enemies: [_shadowAgent, _shadowSniper, _shadowCommander],
      reward: const StageReward(gold: 400, exp: 120),
      twoStarScore: 3500, threeStarScore: 7000),

    // ═══ 第 6 章：秘密基地 ═══
    StageDefinition(id: '6-1', name: '基地入口', chapter: 6, stageNumber: 1,
      staminaCost: 9, moveLimit: 18,
      enemies: [_eliteGuard, _eliteGuard],
      reward: const StageReward(gold: 130, exp: 65),
      twoStarScore: 1500, threeStarScore: 3000),
    StageDefinition(id: '6-2', name: '走廊戰鬥', chapter: 6, stageNumber: 2,
      staminaCost: 9, moveLimit: 16,
      enemies: [_eliteGuard, _heavyBot],
      reward: const StageReward(gold: 140, exp: 70),
      twoStarScore: 1700, threeStarScore: 3400),
    StageDefinition(id: '6-3', name: '武器庫', chapter: 6, stageNumber: 3,
      staminaCost: 10, moveLimit: 16,
      enemies: [_heavyBot, _eliteGuard, _heavyBot],
      reward: const StageReward(gold: 150, exp: 75),
      twoStarScore: 1900, threeStarScore: 3800),
    StageDefinition(id: '6-4', name: '研究室', chapter: 6, stageNumber: 4,
      staminaCost: 10, moveLimit: 16,
      enemies: [_securityBot, _heavyBot, _eliteGuard],
      reward: const StageReward(gold: 150, exp: 75),
      twoStarScore: 2000, threeStarScore: 4000),
    StageDefinition(id: '6-5', name: '能源核心', chapter: 6, stageNumber: 5,
      staminaCost: 10, moveLimit: 15,
      enemies: [_heavyBot, _heavyBot, _eliteGuard],
      reward: const StageReward(gold: 160, exp: 80),
      twoStarScore: 2200, threeStarScore: 4400),
    StageDefinition(id: '6-6', name: '控制室', chapter: 6, stageNumber: 6,
      staminaCost: 10, moveLimit: 15,
      enemies: [_eliteGuard, _shadowAgent, _heavyBot, _shadowAgent],
      reward: const StageReward(gold: 170, exp: 80),
      twoStarScore: 2400, threeStarScore: 4800),
    StageDefinition(id: '6-7', name: '陷阱長廊', chapter: 6, stageNumber: 7,
      staminaCost: 11, moveLimit: 15,
      enemies: [_laserTrap, _heavyBot, _laserTrap, _eliteGuard],
      reward: const StageReward(gold: 170, exp: 85),
      twoStarScore: 2500, threeStarScore: 5000),
    StageDefinition(id: '6-8', name: '首領前廳', chapter: 6, stageNumber: 8,
      staminaCost: 11, moveLimit: 14,
      enemies: [_shadowCommander, _eliteGuard, _heavyBot],
      reward: const StageReward(gold: 180, exp: 85),
      twoStarScore: 2700, threeStarScore: 5400),
    StageDefinition(id: '6-9', name: '最終防線', chapter: 6, stageNumber: 9,
      staminaCost: 12, moveLimit: 14,
      enemies: [_heavyBot, _shadowCommander, _heavyBot, _eliteGuard],
      reward: const StageReward(gold: 200, exp: 90),
      twoStarScore: 3000, threeStarScore: 6000),
    StageDefinition(id: '6-10', name: '暗影首領', chapter: 6, stageNumber: 10,
      staminaCost: 15, moveLimit: 25,
      enemies: [_shadowCommander, _heavyBot, _finalBoss],
      reward: const StageReward(gold: 500, exp: 150),
      twoStarScore: 5000, threeStarScore: 10000),
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
