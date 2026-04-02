/// 遊戲模式設定（從 web/js/GameModes.js 移植）
/// 所有模式的參數集中管理

class ScoringConfig {
  final int baseScore;
  final double comboMultiplier;
  final double chainMultiplier;
  final Map<int, int> comboMilestones;

  const ScoringConfig({
    required this.baseScore,
    required this.comboMultiplier,
    required this.chainMultiplier,
    required this.comboMilestones,
  });

  factory ScoringConfig.fromJson(Map<String, dynamic> json) {
    final rawMilestones = json['comboMilestones'] as Map<String, dynamic>? ?? {};
    return ScoringConfig(
      baseScore: (json['baseScore'] as num).toInt(),
      comboMultiplier: (json['comboMultiplier'] as num).toDouble(),
      chainMultiplier: (json['chainMultiplier'] as num).toDouble(),
      comboMilestones: rawMilestones.map((k, v) => MapEntry(int.parse(k), (v as num).toInt())),
    );
  }
}

class GameModeConfig {
  final String id;
  final String title;
  final String description;
  final int numCols;
  final int numRows;
  final int actionPointsStart;
  final bool hasSkills;
  final bool hasTimer;
  final int gameDuration; // milliseconds
  final bool enableHorizontalMatches;
  final ScoringConfig scoring;

  const GameModeConfig({
    required this.id,
    required this.title,
    required this.description,
    required this.numCols,
    this.numRows = 10,
    this.actionPointsStart = 5,
    this.hasSkills = true,
    this.hasTimer = false,
    this.gameDuration = 0,
    this.enableHorizontalMatches = false,
    required this.scoring,
  });

  factory GameModeConfig.fromJson(String id, Map<String, dynamic> json) {
    return GameModeConfig(
      id: id,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      numCols: (json['numCols'] as num?)?.toInt() ?? 1,
      numRows: (json['numRows'] as num?)?.toInt() ?? 10,
      actionPointsStart: (json['actionPointsStart'] as num?)?.toInt() ?? 5,
      hasSkills: json['hasSkills'] as bool? ?? true,
      hasTimer: json['hasTimer'] as bool? ?? false,
      gameDuration: (json['gameDuration'] as num?)?.toInt() ?? 0,
      enableHorizontalMatches: json['enableHorizontalMatches'] as bool? ?? false,
      scoring: ScoringConfig.fromJson(json['scoring'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class GameModes {
  GameModes._();

  static void loadFromJson(Map<String, dynamic> json) {
    final modes = json['modes'] as Map<String, dynamic>? ?? {};
    if (modes.containsKey('classic'))   classic   = GameModeConfig.fromJson('classic',   modes['classic']);
    if (modes.containsKey('double'))    double_   = GameModeConfig.fromJson('double',    modes['double']);
    if (modes.containsKey('triple'))    triple    = GameModeConfig.fromJson('triple',    modes['triple']);
    if (modes.containsKey('timeLimit')) timeLimit = GameModeConfig.fromJson('timeLimit', modes['timeLimit']);
    if (modes.containsKey('idle'))      idle      = GameModeConfig.fromJson('idle',      modes['idle']);
    allModes = [classic, double_, triple, timeLimit];
  }

  static GameModeConfig classic = const GameModeConfig(
    id: 'classic',
    title: '三消挑戰',
    description: '經典單排模式',
    numCols: 1,
    actionPointsStart: 5,
    scoring: ScoringConfig(
      baseScore: 10,
      comboMultiplier: 0.5,
      chainMultiplier: 2,
      comboMilestones: {5: 100, 10: 300, 15: 500, 20: 1000, 30: 2000},
    ),
  );

  static GameModeConfig double_ = const GameModeConfig(
    id: 'double',
    title: '雙排挑戰',
    description: '快速雙排模式',
    numCols: 2,
    actionPointsStart: 5,
    scoring: ScoringConfig(
      baseScore: 15,
      comboMultiplier: 0.6,
      chainMultiplier: 2.5,
      comboMilestones: {5: 150, 10: 400, 15: 750, 20: 1500, 30: 3000},
    ),
  );

  static GameModeConfig triple = const GameModeConfig(
    id: 'triple',
    title: '三排挑戰',
    description: '進階三排模式',
    numCols: 3,
    actionPointsStart: 5,
    enableHorizontalMatches: true,
    scoring: ScoringConfig(
      baseScore: 20,
      comboMultiplier: 0.7,
      chainMultiplier: 3,
      comboMilestones: {5: 200, 10: 500, 15: 1000, 20: 2000, 30: 4000},
    ),
  );

  static GameModeConfig timeLimit = const GameModeConfig(
    id: 'timeLimit',
    title: '45秒限時挑戰',
    description: '限時挑戰模式',
    numCols: 3,
    actionPointsStart: 0,
    hasSkills: false,
    hasTimer: true,
    gameDuration: 45000,
    enableHorizontalMatches: true,
    scoring: ScoringConfig(
      baseScore: 25,
      comboMultiplier: 1.0,
      chainMultiplier: 4,
      comboMilestones: {3: 200, 5: 500, 10: 1000, 15: 2500, 20: 5000},
    ),
  );

  /// 首頁放置模式 — 3 列 8 行，無行動點限制，無計時，無 game over
  static GameModeConfig idle = const GameModeConfig(
    id: 'idle',
    title: '放置消除',
    description: '輕鬆消除，餵養貓咪',
    numCols: 3,
    numRows: 10,
    actionPointsStart: 0, // 無行動點限制
    hasSkills: false,
    hasTimer: false,
    enableHorizontalMatches: true,
    scoring: ScoringConfig(
      baseScore: 1,
      comboMultiplier: 0.3,
      chainMultiplier: 1.5,
      comboMilestones: {3: 5, 5: 10, 10: 25, 15: 50},
    ),
  );

  static List<GameModeConfig> allModes = [
    classic,
    double_,
    triple,
    timeLimit,
  ];
}
