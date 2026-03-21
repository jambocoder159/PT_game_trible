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

  PlayerData({
    this.playerLevel = 1,
    this.playerExp = 0,
    this.gold = 0,
    this.diamonds = 0,
    this.stamina = 60,
    this.maxStamina = 60,
    DateTime? lastStaminaRecover,
    Map<String, CatAgentInstance>? agents,
    List<String>? team,
    Map<String, StageProgress>? stageProgress,
    DailyQuestData? dailyQuests,
  })  : lastStaminaRecover = lastStaminaRecover ?? DateTime.now(),
        agents = agents ?? {},
        team = team ?? [],
        stageProgress = stageProgress ?? {},
        dailyQuests = dailyQuests ?? DailyQuestData();

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

    return PlayerData(
      playerLevel: json['playerLevel'] as int? ?? 1,
      playerExp: json['playerExp'] as int? ?? 0,
      gold: json['gold'] as int? ?? 0,
      diamonds: json['diamonds'] as int? ?? 0,
      stamina: json['stamina'] as int? ?? 60,
      maxStamina: json['maxStamina'] as int? ?? 60,
      lastStaminaRecover: json['lastStaminaRecover'] != null
          ? DateTime.parse(json['lastStaminaRecover'] as String)
          : DateTime.now(),
      agents: agents,
      team: (json['team'] as List<dynamic>?)?.cast<String>() ?? [],
      stageProgress: stages,
      dailyQuests: json['dailyQuests'] != null
          ? DailyQuestData.fromJson(json['dailyQuests'] as Map<String, dynamic>)
          : DailyQuestData(),
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
      'lastStaminaRecover': lastStaminaRecover.toIso8601String(),
      'agents': agents.map((k, v) => MapEntry(k, v.toJson())),
      'team': team,
      'stageProgress': stageProgress.map((k, v) => MapEntry(k, v.toJson())),
      'dailyQuests': dailyQuests.toJson(),
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
