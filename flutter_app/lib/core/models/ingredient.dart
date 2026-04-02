import 'block.dart';

/// 食材稀有度
enum IngredientTier {
  common,   // 普通
  uncommon, // 優良
  rare,     // 稀有
  epic;     // 史詩

  String get label => ['普通', '優良', '稀有', '史詩'][index];
  int get requiredBottleLevel => [1, 3, 7, 9][index];
}

/// 食材定義
class IngredientDefinition {
  final String id;
  final String name;
  final String emoji;
  final IngredientTier tier;
  final BlockColor bottleColor; // 對應哪個瓶子
  final int bottleLevelRequired;
  final int energyCost;
  final int sellPrice;

  const IngredientDefinition({
    required this.id,
    required this.name,
    required this.emoji,
    required this.tier,
    required this.bottleColor,
    required this.bottleLevelRequired,
    required this.energyCost,
    required this.sellPrice,
  });

  factory IngredientDefinition.fromJson(Map<String, dynamic> json) {
    return IngredientDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String,
      tier: IngredientTier.values.firstWhere(
        (t) => t.name == json['tier'],
        orElse: () => IngredientTier.common,
      ),
      bottleColor: BlockColor.values.firstWhere(
        (c) => c.name == json['bottleColor'],
        orElse: () => BlockColor.coral,
      ),
      bottleLevelRequired: (json['bottleLevelRequired'] as num).toInt(),
      energyCost: (json['energyCost'] as num).toInt(),
      sellPrice: (json['sellPrice'] as num).toInt(),
    );
  }
}
