import 'block.dart';
import '../../config/bottle_dessert_map.dart';

/// 魔法瓶定義（5 瓶對應 5 屬性）
class BottleDefinition {
  final BlockColor color;
  final String name;
  final String emoji;

  const BottleDefinition({
    required this.color,
    required this.name,
    required this.emoji,
  });
}

/// 瓶子等級資料
class BottleLevelData {
  final int level;
  final int capacity;
  final String? stageGateId; // 需通關的關卡 ID，null 表示無門檻
  final int upgradeCostGold;
  final Map<String, int> upgradeMaterials; // materialName → count

  const BottleLevelData({
    required this.level,
    required this.capacity,
    this.stageGateId,
    this.upgradeCostGold = 0,
    this.upgradeMaterials = const {},
  });

  factory BottleLevelData.fromJson(Map<String, dynamic> json) {
    final rawMaterials = json['upgradeMaterials'] as Map<String, dynamic>? ?? {};
    return BottleLevelData(
      level: (json['level'] as num).toInt(),
      capacity: (json['capacity'] as num).toInt(),
      stageGateId: json['stageGateId'] as String?,
      upgradeCostGold: (json['upgradeCostGold'] as num?)?.toInt() ?? 0,
      upgradeMaterials: rawMaterials.map((k, v) => MapEntry(k, (v as num).toInt())),
    );
  }
}

/// 瓶子實例狀態（可序列化）
class BottleStatus {
  final BlockColor color;
  int level;
  int currentEnergy;

  /// 當前生產的甜點 ID
  String? currentDessertId;

  BottleStatus({
    required this.color,
    this.level = 1,
    this.currentEnergy = 0,
    this.currentDessertId,
  });

  /// 當前等級的容量上限
  int get capacity => BottleDefinitions.getLevelData(level).capacity;

  /// 能量是否已滿
  bool get isFull => currentEnergy >= capacity;

  /// 填充進度 (0.0 ~ 1.0)
  double get fillProgress => (currentEnergy / capacity).clamp(0.0, 1.0);

  /// 增加能量（不超過容量）
  void addEnergy(int amount) {
    currentEnergy = (currentEnergy + amount).clamp(0, capacity);
  }

  /// 消耗能量
  bool consumeEnergy(int amount) {
    if (currentEnergy >= amount) {
      currentEnergy -= amount;
      return true;
    }
    return false;
  }

  factory BottleStatus.fromJson(Map<String, dynamic> json) {
    final color = BlockColor.values[json['colorIndex'] as int? ?? 0];
    final level = json['level'] as int? ?? 1;
    // 向下相容：舊版 defaultIngredientId → 自動映射為 currentDessertId
    var dessertId = json['currentDessertId'] as String?;
    if (dessertId == null && json.containsKey('defaultIngredientId')) {
      dessertId = BottleDessertMap.getBestForLevel(color, level)?.dessertId;
    }
    return BottleStatus(
      color: color,
      level: level,
      currentEnergy: json['currentEnergy'] as int? ?? 0,
      currentDessertId: dessertId,
    );
  }

  Map<String, dynamic> toJson() => {
    'colorIndex': color.index,
    'level': level,
    'currentEnergy': currentEnergy,
    if (currentDessertId != null) 'currentDessertId': currentDessertId,
  };
}

/// 魔法瓶靜態定義
class BottleDefinitions {
  BottleDefinitions._();

  static void loadFromJson(Map<String, dynamic> json) {
    final rawLevels = json['levels'] as List<dynamic>? ?? [];
    final parsed = <BottleLevelData>[];
    for (final item in rawLevels) {
      if (item is Map<String, dynamic> && item.containsKey('level')) {
        parsed.add(BottleLevelData.fromJson(item));
      }
    }
    if (parsed.isNotEmpty) levels = parsed;
    if (json.containsKey('maxLevel')) maxLevel = (json['maxLevel'] as num).toInt();
  }

  static const all = [
    BottleDefinition(color: BlockColor.coral, name: '烘焙魔法瓶', emoji: '☀️'),
    BottleDefinition(color: BlockColor.mint,  name: '香草魔法瓶', emoji: '🍃'),
    BottleDefinition(color: BlockColor.teal,  name: '飲品魔法瓶', emoji: '💧'),
    BottleDefinition(color: BlockColor.gold,  name: '裝飾魔法瓶', emoji: '⭐'),
    BottleDefinition(color: BlockColor.rose,  name: '夜甜點魔法瓶', emoji: '🌙'),
  ];

  static BottleDefinition getByColor(BlockColor color) {
    return all.firstWhere((b) => b.color == color);
  }

  /// 等級曲線：capacity ≈ 100 + 80*(lv-1) + 10*(lv-1)²
  static List<BottleLevelData> levels = const [
    BottleLevelData(level: 1,  capacity: 100),
    BottleLevelData(level: 2,  capacity: 180,  stageGateId: '1-3',  upgradeCostGold: 200,   upgradeMaterials: {'commonShard': 3}),
    BottleLevelData(level: 3,  capacity: 280,  stageGateId: '1-5',  upgradeCostGold: 500,   upgradeMaterials: {'commonShard': 5}),
    BottleLevelData(level: 4,  capacity: 400,  stageGateId: '1-8',  upgradeCostGold: 1000,  upgradeMaterials: {'advancedShard': 3}),
    BottleLevelData(level: 5,  capacity: 550,  stageGateId: '2-1',  upgradeCostGold: 2000,  upgradeMaterials: {'advancedShard': 5, '_matchingEssence': 1}),
    BottleLevelData(level: 6,  capacity: 730,  stageGateId: '2-5',  upgradeCostGold: 3500,  upgradeMaterials: {'advancedShard': 8, '_matchingEssence': 2}),
    BottleLevelData(level: 7,  capacity: 950,  stageGateId: '2-8',  upgradeCostGold: 5500,  upgradeMaterials: {'rareShard': 3, '_matchingEssence': 3}),
    BottleLevelData(level: 8,  capacity: 1200, stageGateId: '3-1',  upgradeCostGold: 8000,  upgradeMaterials: {'rareShard': 5, '_matchingEssence': 5}),
    BottleLevelData(level: 9,  capacity: 1500, stageGateId: '3-5',  upgradeCostGold: 12000, upgradeMaterials: {'rareShard': 8, '_matchingEssence': 8}),
    BottleLevelData(level: 10, capacity: 1850, stageGateId: '3-8',  upgradeCostGold: 18000, upgradeMaterials: {'rareShard': 12, '_matchingEssence': 12}),
  ];

  static int maxLevel = 10;

  static BottleLevelData getLevelData(int level) {
    final idx = (level - 1).clamp(0, levels.length - 1);
    return levels[idx];
  }

  /// 取得升級所需的材料（解析 _matchingEssence 為實際對應精華）
  static Map<String, int> getUpgradeMaterials(int targetLevel, BlockColor color) {
    final levelData = getLevelData(targetLevel);
    final essenceKey = _essenceKeyForColor(color);
    final result = <String, int>{};
    for (final entry in levelData.upgradeMaterials.entries) {
      if (entry.key == '_matchingEssence') {
        result[essenceKey] = entry.value;
      } else {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  static String _essenceKeyForColor(BlockColor color) {
    switch (color) {
      case BlockColor.coral: return 'essenceA';
      case BlockColor.mint:  return 'essenceB';
      case BlockColor.teal:  return 'essenceC';
      case BlockColor.gold:  return 'essenceD';
      case BlockColor.rose:  return 'essenceE';
    }
  }
}
