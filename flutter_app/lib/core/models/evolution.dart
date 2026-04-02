/// 進化系統模型
/// 每隻角色可進化 2 階，提升數值和等級上限
import 'material.dart';

/// 進化階段定義
class EvolutionStageDefinition {
  final int stage;                  // 1 or 2
  final String nameSuffix;          // 進化後名稱後綴
  final int requiredLevel;          // 最低等級需求
  final int goldCost;
  final Map<GameMaterial, int> materialCost;
  final double atkMultiplier;       // ATK 加成倍率
  final double defMultiplier;       // DEF 加成倍率
  final double hpMultiplier;        // HP 加成倍率
  final int maxLevelIncrease;       // 等級上限增加

  const EvolutionStageDefinition({
    required this.stage,
    required this.nameSuffix,
    required this.requiredLevel,
    required this.goldCost,
    required this.materialCost,
    required this.atkMultiplier,
    required this.defMultiplier,
    required this.hpMultiplier,
    required this.maxLevelIncrease,
  });

  factory EvolutionStageDefinition.fromJson(Map<String, dynamic> json) {
    final rawMaterials = json['materialCost'] as Map<String, dynamic>? ?? {};
    final materials = <GameMaterial, int>{};
    for (final entry in rawMaterials.entries) {
      final mat = GameMaterial.values.where((m) => m.name == entry.key);
      if (mat.isNotEmpty) {
        materials[mat.first] = (entry.value as num).toInt();
      }
    }
    return EvolutionStageDefinition(
      stage: (json['stage'] as num).toInt(),
      nameSuffix: json['nameSuffix'] as String? ?? '',
      requiredLevel: (json['requiredLevel'] as num).toInt(),
      goldCost: (json['goldCost'] as num).toInt(),
      materialCost: materials,
      atkMultiplier: (json['atkMultiplier'] as num).toDouble(),
      defMultiplier: (json['defMultiplier'] as num).toDouble(),
      hpMultiplier: (json['hpMultiplier'] as num).toDouble(),
      maxLevelIncrease: (json['maxLevelIncrease'] as num?)?.toInt() ?? 10,
    );
  }
}
