/// 玩家資料模型
/// MVP 版本：本地存檔，包含貨幣、體力、角色、隊伍、關卡進度
import 'cat_agent.dart';

/// 玩家資料
class PlayerData {
  int playerLevel;
  int playerExp;
  int gold;
  int diamonds;

  // 體力
  int stamina;
  int maxStamina;
  DateTime lastStaminaRecover;

  // 角色（id → instance）
  Map<String, CatAgentInstance> agents;

  // 隊伍（最多 3 個角色 ID）
  List<String> team;

  // 關卡進度（stageId → StageProgress）
  Map<String, StageProgress> stageProgress;

  // 每日任務
  DailyQuestData dailyQuests;

  // 七日打卡
  WeeklyCheckInData weeklyCheckIn;

  // 新手任務
  NewbieQuestData newbieQuests;

  // 新手引導
  bool tutorialCompleted;

  // 首頁導覽（教學完成後的放置大廳引導）
  bool homeGuideCompleted;

  // 延遲教學：已顯示的功能提示 key
  Set<String> shownFeatureHints;

  // 素材庫存（GameMaterial.name → 數量）
  Map<String, int> materials;

  // ── 放置模式：瓶子 / 食材 / 甜點 ──

  // 食材庫存（ingredientId → 數量）
  Map<String, int> ingredients;

  // 甜點庫存（dessertId → 數量）
  Map<String, int> desserts;

  // 瓶子狀態（colorIndex 字串 → serialized BottleStatus）
  Map<String, dynamic> bottleStates;

  // 已解鎖的食譜 ID（purchase 類型需手動解鎖）
  Set<String> unlockedRecipes;

  // 食材一次性遷移旗標（v2：食材層移除後自動售出）
  bool ingredientsMigrated;

  PlayerData({
    this.playerLevel = 1,
    this.playerExp = 0,
    this.gold = 0,
    this.diamonds = 0,
    this.stamina = 60,
    this.maxStamina = 60,
    this.tutorialCompleted = false,
    this.homeGuideCompleted = false,
    Set<String>? shownFeatureHints,
    DateTime? lastStaminaRecover,
    Map<String, CatAgentInstance>? agents,
    List<String>? team,
    Map<String, StageProgress>? stageProgress,
    DailyQuestData? dailyQuests,
    WeeklyCheckInData? weeklyCheckIn,
    NewbieQuestData? newbieQuests,
    Map<String, int>? materials,
    Map<String, int>? ingredients,
    Map<String, int>? desserts,
    Map<String, dynamic>? bottleStates,
    Set<String>? unlockedRecipes,
    this.ingredientsMigrated = false,
  })  : lastStaminaRecover = lastStaminaRecover ?? DateTime.now(),
        agents = agents ?? {},
        team = team ?? [],
        stageProgress = stageProgress ?? {},
        dailyQuests = dailyQuests ?? DailyQuestData(),
        weeklyCheckIn = weeklyCheckIn ?? WeeklyCheckInData(),
        newbieQuests = newbieQuests ?? NewbieQuestData(),
        materials = materials ?? {},
        ingredients = ingredients ?? {},
        desserts = desserts ?? {},
        shownFeatureHints = shownFeatureHints ?? {},
        bottleStates = bottleStates ?? {},
        unlockedRecipes = unlockedRecipes ?? {};

  /// 建立新玩家的初始資料
  factory PlayerData.newPlayer() {
    final data = PlayerData(
      gold: 100,
      diamonds: 50,
    );

    // 解鎖初始角色（阿焰）
    data.agents['blaze'] = CatAgentInstance(
      definitionId: 'blaze',
      isUnlocked: true,
    );

    // 預設隊伍
    data.team = ['blaze'];

    return data;
  }

  /// 從 JSON 建立
  factory PlayerData.fromJson(Map<String, dynamic> json) {
    final agentsJson = json['agents'] as Map<String, dynamic>? ?? {};
    final agents = agentsJson.map(
      (k, v) => MapEntry(k, CatAgentInstance.fromJson(v as Map<String, dynamic>)),
    );

    final stagesJson = json['stageProgress'] as Map<String, dynamic>? ?? {};
    final stages = stagesJson.map(
      (k, v) => MapEntry(k, StageProgress.fromJson(v as Map<String, dynamic>)),
    );

    final materialsJson = json['materials'] as Map<String, dynamic>? ?? {};
    final materials = materialsJson.map(
      (k, v) => MapEntry(k, v as int),
    );

    final ingredientsJson = json['ingredients'] as Map<String, dynamic>? ?? {};
    final ingredients = ingredientsJson.map(
      (k, v) => MapEntry(k, v as int),
    );

    final dessertsJson = json['desserts'] as Map<String, dynamic>? ?? {};
    final desserts = dessertsJson.map(
      (k, v) => MapEntry(k, v as int),
    );

    return PlayerData(
      playerLevel: json['playerLevel'] as int? ?? 1,
      playerExp: json['playerExp'] as int? ?? 0,
      gold: json['gold'] as int? ?? 0,
      diamonds: json['diamonds'] as int? ?? 0,
      stamina: json['stamina'] as int? ?? 60,
      maxStamina: json['maxStamina'] as int? ?? 60,
      tutorialCompleted: json['tutorialCompleted'] as bool? ?? false,
      homeGuideCompleted: json['homeGuideCompleted'] as bool? ?? false,
      shownFeatureHints: (json['shownFeatureHints'] as List<dynamic>?)?.cast<String>().toSet() ?? {},
      lastStaminaRecover: json['lastStaminaRecover'] != null
          ? DateTime.parse(json['lastStaminaRecover'] as String)
          : DateTime.now(),
      agents: agents,
      team: (json['team'] as List<dynamic>?)?.cast<String>() ?? [],
      stageProgress: stages,
      dailyQuests: json['dailyQuests'] != null
          ? DailyQuestData.fromJson(json['dailyQuests'] as Map<String, dynamic>)
          : DailyQuestData(),
      weeklyCheckIn: json['weeklyCheckIn'] != null
          ? WeeklyCheckInData.fromJson(json['weeklyCheckIn'] as Map<String, dynamic>)
          : WeeklyCheckInData(),
      newbieQuests: json['newbieQuests'] != null
          ? NewbieQuestData.fromJson(json['newbieQuests'] as Map<String, dynamic>)
          : NewbieQuestData(),
      materials: materials,
      ingredients: ingredients,
      desserts: desserts,
      bottleStates: json['bottleStates'] as Map<String, dynamic>? ?? {},
      unlockedRecipes: (json['unlockedRecipes'] as List<dynamic>?)?.cast<String>().toSet() ?? {},
      ingredientsMigrated: json['ingredientsMigrated'] as bool? ?? false,
    );
  }

  /// 轉為 JSON
  Map<String, dynamic> toJson() {
    return {
      'playerLevel': playerLevel,
      'playerExp': playerExp,
      'gold': gold,
      'diamonds': diamonds,
      'stamina': stamina,
      'maxStamina': maxStamina,
      'tutorialCompleted': tutorialCompleted,
      'homeGuideCompleted': homeGuideCompleted,
      'shownFeatureHints': shownFeatureHints.toList(),
      'lastStaminaRecover': lastStaminaRecover.toIso8601String(),
      'agents': agents.map((k, v) => MapEntry(k, v.toJson())),
      'team': team,
      'stageProgress': stageProgress.map((k, v) => MapEntry(k, v.toJson())),
      'dailyQuests': dailyQuests.toJson(),
      'weeklyCheckIn': weeklyCheckIn.toJson(),
      'newbieQuests': newbieQuests.toJson(),
      'materials': materials,
      'ingredients': ingredients,
      'desserts': desserts,
      'bottleStates': bottleStates,
      'unlockedRecipes': unlockedRecipes.toList(),
      'ingredientsMigrated': ingredientsMigrated,
    };
  }

  /// 計算目前應有的體力（考慮離線恢復）
  void recoverStamina() {
    final now = DateTime.now();
    final elapsed = now.difference(lastStaminaRecover);
    final recovered = elapsed.inMinutes ~/ 8; // 每 8 分鐘恢復 1 點

    if (recovered > 0 && stamina < maxStamina) {
      stamina = (stamina + recovered).clamp(0, maxStamina);
      lastStaminaRecover = now;
    }
  }

  /// 消耗體力
  bool consumeStamina(int amount) {
    recoverStamina();
    if (stamina >= amount) {
      stamina -= amount;
      return true;
    }
    return false;
  }

  /// 增加玩家經驗
  void addPlayerExp(int exp) {
    playerExp += exp;
    // 簡單升級公式：每級需要 100 * level 經驗
    while (playerExp >= playerLevel * 100) {
      playerExp -= playerLevel * 100;
      playerLevel++;
      // 升級恢復體力
      stamina = maxStamina;
      // 每 10 級增加 5 體力上限
      if (playerLevel % 10 == 0) {
        maxStamina += 5;
        stamina = maxStamina;
      }
    }
  }
}

/// 關卡進度
class StageProgress {
  final bool cleared;
  final int stars; // 0-3
  final int bestScore;

  const StageProgress({
    this.cleared = false,
    this.stars = 0,
    this.bestScore = 0,
  });

  factory StageProgress.fromJson(Map<String, dynamic> json) {
    return StageProgress(
      cleared: json['cleared'] as bool? ?? false,
      stars: json['stars'] as int? ?? 0,
      bestScore: json['bestScore'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cleared': cleared,
      'stars': stars,
      'bestScore': bestScore,
    };
  }
}

/// 每日任務資料
class DailyQuestData {
  String date; // yyyy-MM-dd
  bool hasLoggedIn;
  int stagesCompleted;
  int blocksEliminated;
  bool rewardsClaimed;

  DailyQuestData({
    String? date,
    this.hasLoggedIn = false,
    this.stagesCompleted = 0,
    this.blocksEliminated = 0,
    this.rewardsClaimed = false,
  }) : date = date ?? _todayString();

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 檢查是否需要重置（新的一天）
  bool get needsReset => date != _todayString();

  /// 重置每日任務
  void reset() {
    date = _todayString();
    hasLoggedIn = false;
    stagesCompleted = 0;
    blocksEliminated = 0;
    rewardsClaimed = false;
  }

  /// 所有任務是否完成
  bool get allCompleted => hasLoggedIn && stagesCompleted >= 3 && blocksEliminated >= 200;

  factory DailyQuestData.fromJson(Map<String, dynamic> json) {
    return DailyQuestData(
      date: json['date'] as String?,
      hasLoggedIn: json['hasLoggedIn'] as bool? ?? false,
      stagesCompleted: json['stagesCompleted'] as int? ?? 0,
      blocksEliminated: json['blocksEliminated'] as int? ?? 0,
      rewardsClaimed: json['rewardsClaimed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'hasLoggedIn': hasLoggedIn,
      'stagesCompleted': stagesCompleted,
      'blocksEliminated': blocksEliminated,
      'rewardsClaimed': rewardsClaimed,
    };
  }
}

/// 七日打卡資料
class WeeklyCheckInData {
  /// 打卡週期的起始日（第一天登入日）
  String startDate;

  /// 已打卡的天數列表（1~7，代表第幾天打過卡）
  List<int> checkedDays;

  /// 今天是否已打卡
  bool todayChecked;

  /// 今天的日期字串（用來判斷是否跨日）
  String lastCheckDate;

  WeeklyCheckInData({
    String? startDate,
    List<int>? checkedDays,
    this.todayChecked = false,
    String? lastCheckDate,
  })  : startDate = startDate ?? _todayString(),
        checkedDays = checkedDays ?? [],
        lastCheckDate = lastCheckDate ?? '';

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 當前是第幾天（從 startDate 算起，1-based）
  int get currentDay {
    try {
      final start = DateTime.parse(startDate);
      final now = DateTime.now();
      final diff = DateTime(now.year, now.month, now.day)
          .difference(DateTime(start.year, start.month, start.day))
          .inDays;
      return (diff + 1).clamp(1, 8); // 超過 7 天回傳 8 表示週期結束
    } catch (_) {
      return 1;
    }
  }

  /// 今天是否需要刷新（跨日）
  bool get needsRefresh => lastCheckDate != _todayString();

  /// 週期是否已結束（7 天都過了）
  bool get isCycleComplete => currentDay > 7;

  /// 重新開始新一輪打卡
  void resetCycle() {
    startDate = _todayString();
    checkedDays = [];
    todayChecked = false;
    lastCheckDate = '';
  }

  /// 跨日刷新（只重置 todayChecked）
  void refreshDay() {
    todayChecked = false;
    lastCheckDate = _todayString();
  }

  /// 打卡（回傳是否成功）
  bool checkIn() {
    if (todayChecked) return false;
    if (isCycleComplete) return false;
    final day = currentDay;
    if (!checkedDays.contains(day)) {
      checkedDays.add(day);
    }
    todayChecked = true;
    lastCheckDate = _todayString();
    return true;
  }

  /// 已打卡天數
  int get totalChecked => checkedDays.length;

  factory WeeklyCheckInData.fromJson(Map<String, dynamic> json) {
    return WeeklyCheckInData(
      startDate: json['startDate'] as String?,
      checkedDays: (json['checkedDays'] as List<dynamic>?)?.cast<int>() ?? [],
      todayChecked: json['todayChecked'] as bool? ?? false,
      lastCheckDate: json['lastCheckDate'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate,
      'checkedDays': checkedDays,
      'todayChecked': todayChecked,
      'lastCheckDate': lastCheckDate,
    };
  }
}

/// 新手任務資料
class NewbieQuestData {
  /// 已完成的任務 ID 集合
  Set<String> completedIds;

  /// 已領取獎勵的任務 ID
  Set<String> claimedIds;

  NewbieQuestData({
    Set<String>? completedIds,
    Set<String>? claimedIds,
  })  : completedIds = completedIds ?? {},
        claimedIds = claimedIds ?? {};

  bool isCompleted(String id) => completedIds.contains(id);
  bool isClaimed(String id) => claimedIds.contains(id);

  void complete(String id) => completedIds.add(id);
  void claim(String id) => claimedIds.add(id);

  factory NewbieQuestData.fromJson(Map<String, dynamic> json) {
    return NewbieQuestData(
      completedIds: (json['completedIds'] as List<dynamic>?)?.cast<String>().toSet() ?? {},
      claimedIds: (json['claimedIds'] as List<dynamic>?)?.cast<String>().toSet() ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'completedIds': completedIds.toList(),
      'claimedIds': claimedIds.toList(),
    };
  }
}
