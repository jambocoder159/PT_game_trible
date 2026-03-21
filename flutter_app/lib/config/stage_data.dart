/// 關卡數據
/// MVP：第 1 章（後巷區）10 關 + 第 2 章（商店街）10 關 + 第 3 章（港口區）10 關
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
      name: '後巷區',
      location: '秘密組織總部附近的後巷',
      description: '新人特工訓練 + 首次實戰任務',
    ),
    ChapterInfo(
      number: 2,
      name: '商店街',
      location: '市中心的繁華商店街',
      description: '調查可疑的寵物店',
    ),
    ChapterInfo(
      number: 3,
      name: '港口區',
      location: '城市南端的貨運碼頭',
      description: '攔截走私貨物',
    ),
  ];

  // ─── 敵人定義 ───

  // 第 1 章：後巷區
  static const _rat = EnemyDefinition(
    id: 'rat',
    name: '鼠幫小嘍囉',
    emoji: '🐀',
    attribute: AgentAttribute.attributeB,
    baseHp: 100,
    baseAtk: 8,
    attackInterval: 3,
  );

  static const _bigRat = EnemyDefinition(
    id: 'big_rat',
    name: '鼠幫打手',
    emoji: '🐀',
    attribute: AgentAttribute.attributeB,
    baseHp: 200,
    baseAtk: 15,
    attackInterval: 3,
  );

  static const _strayDog = EnemyDefinition(
    id: 'stray_dog',
    name: '流浪惡犬',
    emoji: '🐕',
    attribute: AgentAttribute.attributeA,
    baseHp: 250,
    baseAtk: 20,
    attackInterval: 4,
  );

  static const _ratBoss = EnemyDefinition(
    id: 'rat_boss',
    name: '鼠幫老大',
    emoji: '🐀',
    attribute: AgentAttribute.attributeB,
    baseHp: 500,
    baseAtk: 25,
    attackInterval: 3,
  );

  // 第 2 章：商店街
  static const _petShopGuard = EnemyDefinition(
    id: 'pet_shop_guard',
    name: '寵物店打手',
    emoji: '🦝',
    attribute: AgentAttribute.attributeC,
    baseHp: 200,
    baseAtk: 15,
    attackInterval: 3,
  );

  static const _trapDevice = EnemyDefinition(
    id: 'trap_device',
    name: '捕獸陷阱',
    emoji: '⚙️',
    attribute: AgentAttribute.attributeD,
    baseHp: 150,
    baseAtk: 25,
    attackInterval: 4,
  );

  static const _shopOwner = EnemyDefinition(
    id: 'shop_owner',
    name: '可疑店長',
    emoji: '🦊',
    attribute: AgentAttribute.attributeE,
    baseHp: 600,
    baseAtk: 22,
    attackInterval: 3,
  );

  // 第 3 章：港口區
  static const _dockWorker = EnemyDefinition(
    id: 'dock_worker',
    name: '碼頭幫派',
    emoji: '🦦',
    attribute: AgentAttribute.attributeA,
    baseHp: 300,
    baseAtk: 20,
    attackInterval: 3,
  );

  static const _seagull = EnemyDefinition(
    id: 'seagull',
    name: '暴躁海鷗',
    emoji: '🦅',
    attribute: AgentAttribute.attributeD,
    baseHp: 180,
    baseAtk: 30,
    attackInterval: 2,
  );

  static const _seagullBoss = EnemyDefinition(
    id: 'seagull_boss',
    name: '海鷗王',
    emoji: '🦅',
    attribute: AgentAttribute.attributeD,
    baseHp: 800,
    baseAtk: 35,
    attackInterval: 3,
  );

  // ─── 關卡定義 ───

  static final List<StageDefinition> allStages = [
    // ═══ 第 1 章：後巷區 ═══
    StageDefinition(
      id: '1-1',
      name: '新人報到',
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
      name: '後巷巡邏',
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
      name: '解救同伴',
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
      name: '垃圾場突襲',
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
      name: '惡犬來襲',
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
      name: '追蹤線索',
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
      name: '地下通道',
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
      name: '埋伏圈套',
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
      name: '直搗巢穴',
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
      name: '鼠幫老大',
      chapter: 1,
      stageNumber: 10,
      staminaCost: 8,
      moveLimit: 20,
      enemies: [_bigRat, _ratBoss],
      reward: const StageReward(gold: 150, exp: 50),
      twoStarScore: 1500,
      threeStarScore: 3000,
    ),

    // ═══ 第 2 章：商店街 ═══
    StageDefinition(
      id: '2-1',
      name: '可疑的寵物店',
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
      name: '店後調查',
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
      name: '陷阱走廊',
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
      name: '倉庫搜索',
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
      name: '暗巷追逐',
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
      name: '密室突入',
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
      name: '保全室',
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
      name: '地下通道',
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
      name: '證據確保',
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
      name: '可疑店長',
      chapter: 2,
      stageNumber: 10,
      staminaCost: 8,
      moveLimit: 20,
      enemies: [_petShopGuard, _shopOwner],
      reward: const StageReward(gold: 200, exp: 60),
      twoStarScore: 1800,
      threeStarScore: 3600,
    ),

    // ═══ 第 3 章：港口區 ═══
    StageDefinition(
      id: '3-1',
      name: '碼頭偵察',
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
      name: '貨櫃迷宮',
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
      name: '海鷗騷擾',
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
    const StageDefinition(
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
