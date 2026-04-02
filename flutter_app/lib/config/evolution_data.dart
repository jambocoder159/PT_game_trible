/// 進化靜態數據
/// 每隻角色 2 階進化
import '../core/models/evolution.dart';
import '../core/models/material.dart';

class EvolutionData {
  EvolutionData._();

  static void loadFromJson(Map<String, dynamic> json) {
    for (final rarity in ['n', 'r', 'sr', 'ssr']) {
      final list = json[rarity] as List<dynamic>?;
      if (list == null) continue;
      final parsed = list
          .where((e) => e is Map<String, dynamic> && e.containsKey('stage'))
          .map((e) => EvolutionStageDefinition.fromJson(e as Map<String, dynamic>))
          .toList();
      switch (rarity) {
        case 'n':   nEvolutions = parsed; break;
        case 'r':   rEvolutions = parsed; break;
        case 'sr':  srEvolutions = parsed; break;
        case 'ssr': ssrEvolutions = parsed; break;
      }
    }
  }

  /// N 稀有度進化（Lv15 → Lv25）
  static List<EvolutionStageDefinition> nEvolutions = const <EvolutionStageDefinition>[
    EvolutionStageDefinition(
      stage: 1, nameSuffix: '·改',
      requiredLevel: 15,
      goldCost: 1000,
      materialCost: {
        GameMaterial.commonShard: 10,
        GameMaterial.advancedShard: 3,
      },
      atkMultiplier: 1.15, defMultiplier: 1.15, hpMultiplier: 1.15,
      maxLevelIncrease: 10,
    ),
    EvolutionStageDefinition(
      stage: 2, nameSuffix: '·極',
      requiredLevel: 30,
      goldCost: 3000,
      materialCost: {
        GameMaterial.advancedShard: 8,
        GameMaterial.rareShard: 3,
        GameMaterial.skillCore: 2,
      },
      atkMultiplier: 1.35, defMultiplier: 1.35, hpMultiplier: 1.35,
      maxLevelIncrease: 10,
    ),
  ];

  /// R 稀有度進化（Lv20 → Lv35）
  static List<EvolutionStageDefinition> rEvolutions = const <EvolutionStageDefinition>[
    EvolutionStageDefinition(
      stage: 1, nameSuffix: '·改',
      requiredLevel: 20,
      goldCost: 2000,
      materialCost: {
        GameMaterial.commonShard: 15,
        GameMaterial.advancedShard: 5,
        GameMaterial.talentScroll: 2,
      },
      atkMultiplier: 1.2, defMultiplier: 1.2, hpMultiplier: 1.2,
      maxLevelIncrease: 10,
    ),
    EvolutionStageDefinition(
      stage: 2, nameSuffix: '·極',
      requiredLevel: 40,
      goldCost: 5000,
      materialCost: {
        GameMaterial.advancedShard: 10,
        GameMaterial.rareShard: 5,
        GameMaterial.skillCore: 3,
        GameMaterial.passiveGem: 2,
      },
      atkMultiplier: 1.45, defMultiplier: 1.45, hpMultiplier: 1.45,
      maxLevelIncrease: 10,
    ),
  ];

  /// SR 稀有度進化（Lv25 → Lv45）
  static List<EvolutionStageDefinition> srEvolutions = const <EvolutionStageDefinition>[
    EvolutionStageDefinition(
      stage: 1, nameSuffix: '·改',
      requiredLevel: 25,
      goldCost: 3000,
      materialCost: {
        GameMaterial.advancedShard: 8,
        GameMaterial.rareShard: 3,
        GameMaterial.talentScroll: 3,
      },
      atkMultiplier: 1.25, defMultiplier: 1.25, hpMultiplier: 1.25,
      maxLevelIncrease: 10,
    ),
    EvolutionStageDefinition(
      stage: 2, nameSuffix: '·極',
      requiredLevel: 45,
      goldCost: 8000,
      materialCost: {
        GameMaterial.rareShard: 8,
        GameMaterial.skillCore: 5,
        GameMaterial.passiveGem: 3,
        GameMaterial.talentScroll: 5,
      },
      atkMultiplier: 1.55, defMultiplier: 1.55, hpMultiplier: 1.55,
      maxLevelIncrease: 10,
    ),
  ];

  /// SSR 稀有度進化
  static List<EvolutionStageDefinition> ssrEvolutions = const <EvolutionStageDefinition>[
    EvolutionStageDefinition(
      stage: 1, nameSuffix: '·改',
      requiredLevel: 30,
      goldCost: 5000,
      materialCost: {
        GameMaterial.advancedShard: 10,
        GameMaterial.rareShard: 5,
        GameMaterial.talentScroll: 5,
        GameMaterial.skillCore: 3,
      },
      atkMultiplier: 1.3, defMultiplier: 1.3, hpMultiplier: 1.3,
      maxLevelIncrease: 10,
    ),
    EvolutionStageDefinition(
      stage: 2, nameSuffix: '·極',
      requiredLevel: 50,
      goldCost: 12000,
      materialCost: {
        GameMaterial.rareShard: 12,
        GameMaterial.skillCore: 8,
        GameMaterial.passiveGem: 5,
        GameMaterial.talentScroll: 8,
      },
      atkMultiplier: 1.65, defMultiplier: 1.65, hpMultiplier: 1.65,
      maxLevelIncrease: 10,
    ),
  ];

  /// 根據稀有度取得進化資料
  static List<EvolutionStageDefinition> getEvolutionsForRarity(String rarityName) {
    switch (rarityName) {
      case 'n': return nEvolutions;
      case 'r': return rEvolutions;
      case 'sr': return srEvolutions;
      case 'ssr': return ssrEvolutions;
      default: return nEvolutions;
    }
  }

  /// 取得特定進化階段
  static EvolutionStageDefinition? getEvolution(String rarityName, int stage) {
    final evolutions = getEvolutionsForRarity(rarityName);
    if (stage < 1 || stage > evolutions.length) return null;
    return evolutions[stage - 1];
  }
}
