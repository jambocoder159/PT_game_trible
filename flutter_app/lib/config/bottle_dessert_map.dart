import '../core/models/block.dart';

/// 瓶子直接產出甜點的等級對照
class BottleDessertTier {
  final int requiredLevel;
  final String dessertId;
  final int energyCost;

  const BottleDessertTier({
    required this.requiredLevel,
    required this.dessertId,
    required this.energyCost,
  });
}

/// 瓶子 → 甜點對照表
class BottleDessertMap {
  BottleDessertMap._();

  static const Map<BlockColor, List<BottleDessertTier>> mapping = {
    // ☀️ 烘焙瓶
    BlockColor.coral: [
      BottleDessertTier(requiredLevel: 1, dessertId: 'butter_roll', energyCost: 30),
      BottleDessertTier(requiredLevel: 3, dessertId: 'honey_toast', energyCost: 60),
      BottleDessertTier(requiredLevel: 5, dessertId: 'cinnamon_roll', energyCost: 80),
    ],
    // 🍃 香草瓶
    BlockColor.mint: [
      BottleDessertTier(requiredLevel: 1, dessertId: 'mint_tea', energyCost: 30),
      BottleDessertTier(requiredLevel: 3, dessertId: 'matcha_latte', energyCost: 60),
      BottleDessertTier(requiredLevel: 5, dessertId: 'saffron_millefeuille', energyCost: 80),
    ],
    // 💧 飲品瓶
    BlockColor.teal: [
      BottleDessertTier(requiredLevel: 1, dessertId: 'fresh_juice', energyCost: 30),
      BottleDessertTier(requiredLevel: 3, dessertId: 'coconut_taro_sago', energyCost: 60),
      BottleDessertTier(requiredLevel: 5, dessertId: 'tiramisu', energyCost: 80),
    ],
    // ⭐ 裝飾瓶
    BlockColor.gold: [
      BottleDessertTier(requiredLevel: 1, dessertId: 'cocoa_cookie', energyCost: 30),
      BottleDessertTier(requiredLevel: 3, dessertId: 'starry_lollipop', energyCost: 60),
      BottleDessertTier(requiredLevel: 5, dessertId: 'stardust_truffle', energyCost: 80),
    ],
    // 🌙 夜甜點瓶
    BlockColor.rose: [
      BottleDessertTier(requiredLevel: 1, dessertId: 'rose_pudding', energyCost: 30),
      BottleDessertTier(requiredLevel: 3, dessertId: 'moonlight_macaron', energyCost: 60),
      BottleDessertTier(requiredLevel: 5, dessertId: 'patissier_masterpiece', energyCost: 80),
    ],
  };

  /// 取得瓶子在當前等級能生產的最高階甜點
  static BottleDessertTier? getBestForLevel(BlockColor color, int level) {
    final tiers = mapping[color];
    if (tiers == null || tiers.isEmpty) return null;
    BottleDessertTier? best;
    for (final tier in tiers) {
      if (tier.requiredLevel <= level) best = tier;
    }
    return best;
  }

  /// 取得該顏色所有已解鎖的甜點選項
  static List<BottleDessertTier> getAvailable(BlockColor color, int level) {
    final tiers = mapping[color];
    if (tiers == null) return [];
    return tiers.where((t) => t.requiredLevel <= level).toList();
  }

  /// 取得該顏色的所有甜點（含未解鎖）
  static List<BottleDessertTier> getAll(BlockColor color) {
    return mapping[color] ?? [];
  }
}
