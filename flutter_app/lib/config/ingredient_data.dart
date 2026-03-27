import '../core/models/block.dart';
import '../core/models/ingredient.dart';
import '../core/models/dessert.dart';

/// 所有食材定義（30 種，每瓶 6 種）
class IngredientDefinitions {
  IngredientDefinitions._();

  // ────────── ☀️ 烘焙瓶 (coral) ──────────
  static const flour = IngredientDefinition(
    id: 'flour', name: '麵粉', emoji: '🌾',
    tier: IngredientTier.common, bottleColor: BlockColor.coral,
    bottleLevelRequired: 1, energyCost: 30, sellPrice: 5,
  );
  static const butter = IngredientDefinition(
    id: 'butter', name: '奶油', emoji: '🧈',
    tier: IngredientTier.common, bottleColor: BlockColor.coral,
    bottleLevelRequired: 1, energyCost: 30, sellPrice: 5,
  );
  static const egg = IngredientDefinition(
    id: 'egg', name: '雞蛋', emoji: '🥚',
    tier: IngredientTier.uncommon, bottleColor: BlockColor.coral,
    bottleLevelRequired: 3, energyCost: 60, sellPrice: 12,
  );
  static const yeast = IngredientDefinition(
    id: 'yeast', name: '酵母', emoji: '🫧',
    tier: IngredientTier.uncommon, bottleColor: BlockColor.coral,
    bottleLevelRequired: 5, energyCost: 80, sellPrice: 18,
  );
  static const honey = IngredientDefinition(
    id: 'honey', name: '蜂蜜', emoji: '🍯',
    tier: IngredientTier.rare, bottleColor: BlockColor.coral,
    bottleLevelRequired: 7, energyCost: 120, sellPrice: 30,
  );
  static const goldenSyrup = IngredientDefinition(
    id: 'golden_syrup', name: '金色糖漿', emoji: '🥇',
    tier: IngredientTier.epic, bottleColor: BlockColor.coral,
    bottleLevelRequired: 9, energyCost: 180, sellPrice: 50,
  );

  // ────────── 🍃 香草瓶 (mint) ──────────
  static const mintLeaf = IngredientDefinition(
    id: 'mint_leaf', name: '薄荷葉', emoji: '🍃',
    tier: IngredientTier.common, bottleColor: BlockColor.mint,
    bottleLevelRequired: 1, energyCost: 30, sellPrice: 5,
  );
  static const matcha = IngredientDefinition(
    id: 'matcha', name: '抹茶粉', emoji: '🍵',
    tier: IngredientTier.common, bottleColor: BlockColor.mint,
    bottleLevelRequired: 1, energyCost: 30, sellPrice: 5,
  );
  static const vanillaPod = IngredientDefinition(
    id: 'vanilla_pod', name: '香草莢', emoji: '🌿',
    tier: IngredientTier.uncommon, bottleColor: BlockColor.mint,
    bottleLevelRequired: 3, energyCost: 60, sellPrice: 12,
  );
  static const cinnamon = IngredientDefinition(
    id: 'cinnamon', name: '肉桂', emoji: '🪵',
    tier: IngredientTier.uncommon, bottleColor: BlockColor.mint,
    bottleLevelRequired: 5, energyCost: 80, sellPrice: 18,
  );
  static const saffron = IngredientDefinition(
    id: 'saffron', name: '藏紅花', emoji: '🌸',
    tier: IngredientTier.rare, bottleColor: BlockColor.mint,
    bottleLevelRequired: 7, energyCost: 120, sellPrice: 30,
  );
  static const enchantedHerb = IngredientDefinition(
    id: 'enchanted_herb', name: '魔法香草精華', emoji: '✨',
    tier: IngredientTier.epic, bottleColor: BlockColor.mint,
    bottleLevelRequired: 9, energyCost: 180, sellPrice: 50,
  );

  // ────────── 💧 飲品瓶 (teal) ──────────
  static const milk = IngredientDefinition(
    id: 'milk', name: '牛奶', emoji: '🥛',
    tier: IngredientTier.common, bottleColor: BlockColor.teal,
    bottleLevelRequired: 1, energyCost: 30, sellPrice: 5,
  );
  static const juice = IngredientDefinition(
    id: 'juice', name: '果汁', emoji: '🧃',
    tier: IngredientTier.common, bottleColor: BlockColor.teal,
    bottleLevelRequired: 1, energyCost: 30, sellPrice: 5,
  );
  static const cream = IngredientDefinition(
    id: 'cream', name: '鮮奶油', emoji: '🍦',
    tier: IngredientTier.uncommon, bottleColor: BlockColor.teal,
    bottleLevelRequired: 3, energyCost: 60, sellPrice: 12,
  );
  static const condensedMilk = IngredientDefinition(
    id: 'condensed_milk', name: '煉乳', emoji: '🫙',
    tier: IngredientTier.uncommon, bottleColor: BlockColor.teal,
    bottleLevelRequired: 5, energyCost: 80, sellPrice: 18,
  );
  static const coconutMilk = IngredientDefinition(
    id: 'coconut_milk', name: '椰奶', emoji: '🥥',
    tier: IngredientTier.rare, bottleColor: BlockColor.teal,
    bottleLevelRequired: 7, energyCost: 120, sellPrice: 30,
  );
  static const starlightDew = IngredientDefinition(
    id: 'starlight_dew', name: '星光露水', emoji: '💫',
    tier: IngredientTier.epic, bottleColor: BlockColor.teal,
    bottleLevelRequired: 9, energyCost: 180, sellPrice: 50,
  );

  // ────────── ⭐ 裝飾瓶 (gold) ──────────
  static const powderedSugar = IngredientDefinition(
    id: 'powdered_sugar', name: '糖粉', emoji: '🍚',
    tier: IngredientTier.common, bottleColor: BlockColor.gold,
    bottleLevelRequired: 1, energyCost: 30, sellPrice: 5,
  );
  static const chocoChips = IngredientDefinition(
    id: 'choco_chips', name: '巧克力碎片', emoji: '🍫',
    tier: IngredientTier.common, bottleColor: BlockColor.gold,
    bottleLevelRequired: 1, energyCost: 30, sellPrice: 5,
  );
  static const fruitSlices = IngredientDefinition(
    id: 'fruit_slices', name: '水果切片', emoji: '🍓',
    tier: IngredientTier.uncommon, bottleColor: BlockColor.gold,
    bottleLevelRequired: 3, energyCost: 60, sellPrice: 12,
  );
  static const goldLeaf = IngredientDefinition(
    id: 'gold_leaf', name: '食用金箔', emoji: '🏅',
    tier: IngredientTier.uncommon, bottleColor: BlockColor.gold,
    bottleLevelRequired: 5, energyCost: 80, sellPrice: 18,
  );
  static const rainbowSprinkles = IngredientDefinition(
    id: 'rainbow_sprinkles', name: '彩虹糖珠', emoji: '🌈',
    tier: IngredientTier.rare, bottleColor: BlockColor.gold,
    bottleLevelRequired: 7, energyCost: 120, sellPrice: 30,
  );
  static const magicStardust = IngredientDefinition(
    id: 'magic_stardust', name: '魔法星塵', emoji: '🌟',
    tier: IngredientTier.epic, bottleColor: BlockColor.gold,
    bottleLevelRequired: 9, energyCost: 180, sellPrice: 50,
  );

  // ────────── 🌙 夜甜點瓶 (rose) ──────────
  static const cocoaPowder = IngredientDefinition(
    id: 'cocoa_powder', name: '可可粉', emoji: '🤎',
    tier: IngredientTier.common, bottleColor: BlockColor.rose,
    bottleLevelRequired: 1, energyCost: 30, sellPrice: 5,
  );
  static const brownSugar = IngredientDefinition(
    id: 'brown_sugar', name: '黑糖', emoji: '🟫',
    tier: IngredientTier.common, bottleColor: BlockColor.rose,
    bottleLevelRequired: 1, energyCost: 30, sellPrice: 5,
  );
  static const darkChocolate = IngredientDefinition(
    id: 'dark_chocolate', name: '黑巧克力', emoji: '🍫',
    tier: IngredientTier.uncommon, bottleColor: BlockColor.rose,
    bottleLevelRequired: 3, energyCost: 60, sellPrice: 12,
  );
  static const coffeeGrounds = IngredientDefinition(
    id: 'coffee_grounds', name: '咖啡粉', emoji: '☕',
    tier: IngredientTier.uncommon, bottleColor: BlockColor.rose,
    bottleLevelRequired: 5, energyCost: 80, sellPrice: 18,
  );
  static const purpleYam = IngredientDefinition(
    id: 'purple_yam', name: '紫薯泥', emoji: '🟣',
    tier: IngredientTier.rare, bottleColor: BlockColor.rose,
    bottleLevelRequired: 7, energyCost: 120, sellPrice: 30,
  );
  static const moonlightEssence = IngredientDefinition(
    id: 'moonlight_essence', name: '月光精粹', emoji: '🌙',
    tier: IngredientTier.epic, bottleColor: BlockColor.rose,
    bottleLevelRequired: 9, energyCost: 180, sellPrice: 50,
  );

  /// 全部食材清單
  static const List<IngredientDefinition> all = [
    // 烘焙
    flour, butter, egg, yeast, honey, goldenSyrup,
    // 香草
    mintLeaf, matcha, vanillaPod, cinnamon, saffron, enchantedHerb,
    // 飲品
    milk, juice, cream, condensedMilk, coconutMilk, starlightDew,
    // 裝飾
    powderedSugar, chocoChips, fruitSlices, goldLeaf, rainbowSprinkles, magicStardust,
    // 夜甜點
    cocoaPowder, brownSugar, darkChocolate, coffeeGrounds, purpleYam, moonlightEssence,
  ];

  /// 依 ID 查找
  static IngredientDefinition? getById(String id) {
    for (final i in all) {
      if (i.id == id) return i;
    }
    return null;
  }

  /// 取得某瓶的所有食材
  static List<IngredientDefinition> getByBottleColor(BlockColor color) {
    return all.where((i) => i.bottleColor == color).toList();
  }

  /// 取得某瓶在指定等級下可產出的食材
  static List<IngredientDefinition> getAvailable(BlockColor color, int bottleLevel) {
    return all
        .where((i) => i.bottleColor == color && i.bottleLevelRequired <= bottleLevel)
        .toList();
  }
}

/// 所有甜點食譜定義（20 道）
class DessertDefinitions {
  DessertDefinitions._();

  // ── Tier 1: 新手（預設解鎖）──
  static const butterRoll = DessertRecipe(
    id: 'butter_roll', name: '奶油小餐包', emoji: '🍞', tier: 1,
    ingredients: {'flour': 2, 'butter': 1, 'egg': 1},
    sellPrice: 40, unlock: DessertUnlockCondition.defaultUnlocked(),
  );
  static const mintTea = DessertRecipe(
    id: 'mint_tea', name: '薄荷茶', emoji: '🍵', tier: 1,
    ingredients: {'mint_leaf': 2, 'milk': 1},
    sellPrice: 30, unlock: DessertUnlockCondition.defaultUnlocked(),
  );
  static const cocoaCookie = DessertRecipe(
    id: 'cocoa_cookie', name: '可可餅乾', emoji: '🍪', tier: 1,
    ingredients: {'cocoa_powder': 2, 'flour': 1, 'butter': 1},
    sellPrice: 40, unlock: DessertUnlockCondition.defaultUnlocked(),
  );
  static const freshJuice = DessertRecipe(
    id: 'fresh_juice', name: '鮮果汁', emoji: '🥤', tier: 1,
    ingredients: {'juice': 2, 'fruit_slices': 1},
    sellPrice: 35, unlock: DessertUnlockCondition.defaultUnlocked(),
  );

  // ── Tier 2: 中級（Chapter 1 解鎖）──
  static const honeyToast = DessertRecipe(
    id: 'honey_toast', name: '蜂蜜吐司', emoji: '🍯', tier: 2,
    ingredients: {'flour': 2, 'egg': 1, 'honey': 1, 'butter': 1},
    sellPrice: 80, unlock: DessertUnlockCondition.stageClear('1-5'),
  );
  static const matchaLatte = DessertRecipe(
    id: 'matcha_latte', name: '抹茶拿鐵', emoji: '🍵', tier: 2,
    ingredients: {'matcha': 2, 'milk': 1, 'cream': 1},
    sellPrice: 75, unlock: DessertUnlockCondition.stageClear('1-5'),
  );
  static const chocolateCake = DessertRecipe(
    id: 'chocolate_cake', name: '巧克力蛋糕', emoji: '🎂', tier: 2,
    ingredients: {'dark_chocolate': 2, 'egg': 2, 'flour': 1, 'cream': 1},
    sellPrice: 90, unlock: DessertUnlockCondition.stageClear('1-8'),
  );
  static const fruitTart = DessertRecipe(
    id: 'fruit_tart', name: '水果塔', emoji: '🥧', tier: 2,
    ingredients: {'flour': 2, 'butter': 1, 'fruit_slices': 2, 'cream': 1},
    sellPrice: 85, unlock: DessertUnlockCondition.stageClear('1-8'),
  );
  static const cinnamonRoll = DessertRecipe(
    id: 'cinnamon_roll', name: '肉桂捲', emoji: '🥐', tier: 2,
    ingredients: {'flour': 2, 'yeast': 1, 'cinnamon': 1, 'butter': 1},
    sellPrice: 80, unlock: DessertUnlockCondition.stageClear('1-10'),
  );

  // ── Tier 3: 進階（Chapter 2 解鎖）──
  static const cremeCaramel = DessertRecipe(
    id: 'creme_caramel', name: '焦糖布丁', emoji: '🍮', tier: 3,
    ingredients: {'egg': 2, 'golden_syrup': 1, 'condensed_milk': 1, 'vanilla_pod': 1},
    sellPrice: 150, unlock: DessertUnlockCondition.stageClear('2-3'),
  );
  static const coconutTaroSago = DessertRecipe(
    id: 'coconut_taro_sago', name: '椰奶紫芋西米露', emoji: '🥥', tier: 3,
    ingredients: {'coconut_milk': 2, 'purple_yam': 1, 'brown_sugar': 1},
    sellPrice: 140, unlock: DessertUnlockCondition.stageClear('2-5'),
  );
  static const starryLollipop = DessertRecipe(
    id: 'starry_lollipop', name: '星空棒棒糖', emoji: '🍭', tier: 3,
    ingredients: {'rainbow_sprinkles': 1, 'gold_leaf': 1, 'powdered_sugar': 2, 'golden_syrup': 1},
    sellPrice: 160, unlock: DessertUnlockCondition.stageClear('2-5'),
  );
  static const tiramisu = DessertRecipe(
    id: 'tiramisu', name: '提拉米蘇', emoji: '🍰', tier: 3,
    ingredients: {'coffee_grounds': 2, 'dark_chocolate': 1, 'cream': 2, 'cocoa_powder': 1},
    sellPrice: 170, unlock: DessertUnlockCondition.stageClear('2-8'),
  );
  static const saffronMillefeuille = DessertRecipe(
    id: 'saffron_millefeuille', name: '藏紅花千層', emoji: '🧁', tier: 3,
    ingredients: {'flour': 2, 'butter': 1, 'saffron': 1, 'cream': 1, 'vanilla_pod': 1},
    sellPrice: 180, unlock: DessertUnlockCondition.stageClear('2-10'),
  );

  // ── Tier 4: 大師（Chapter 3 / 食譜購買）──
  static const moonlightMacaron = DessertRecipe(
    id: 'moonlight_macaron', name: '月光馬卡龍', emoji: '🌙', tier: 4,
    ingredients: {'egg': 2, 'moonlight_essence': 1, 'powdered_sugar': 1, 'vanilla_pod': 1},
    sellPrice: 280, unlock: DessertUnlockCondition.stageClear('3-3'),
  );
  static const magicRainbowCake = DessertRecipe(
    id: 'magic_rainbow_cake', name: '魔法彩虹蛋糕', emoji: '🌈', tier: 4,
    ingredients: {'magic_stardust': 1, 'enchanted_herb': 1, 'flour': 2, 'egg': 2, 'cream': 1},
    sellPrice: 350, unlock: DessertUnlockCondition.stageClear('3-5'),
  );
  static const stardustTruffle = DessertRecipe(
    id: 'stardust_truffle', name: '星塵巧克力松露', emoji: '🍫', tier: 4,
    ingredients: {'dark_chocolate': 2, 'magic_stardust': 1, 'moonlight_essence': 1, 'cream': 1},
    sellPrice: 380, unlock: DessertUnlockCondition.stageClear('3-8'),
  );
  static const goldenCrownPuff = DessertRecipe(
    id: 'golden_crown_puff', name: '金箔皇冠泡芙', emoji: '👑', tier: 4,
    ingredients: {'egg': 2, 'flour': 1, 'golden_syrup': 1, 'gold_leaf': 1, 'cream': 1, 'starlight_dew': 1},
    sellPrice: 400, unlock: DessertUnlockCondition.purchase(5000),
  );
  static const auroraMillefeuille = DessertRecipe(
    id: 'aurora_millefeuille', name: '極光千層酥', emoji: '🌌', tier: 4,
    ingredients: {'enchanted_herb': 1, 'saffron': 1, 'starlight_dew': 1, 'flour': 2, 'butter': 1, 'rainbow_sprinkles': 1},
    sellPrice: 420, unlock: DessertUnlockCondition.purchase(8000),
  );
  static const patissierMasterpiece = DessertRecipe(
    id: 'patissier_masterpiece', name: '夢幻甜點師之作', emoji: '🏆', tier: 4,
    ingredients: {'golden_syrup': 1, 'enchanted_herb': 1, 'starlight_dew': 1, 'magic_stardust': 1, 'moonlight_essence': 1},
    sellPrice: 500, unlock: DessertUnlockCondition.purchase(12000),
  );

  /// 全部食譜
  static const List<DessertRecipe> all = [
    // Tier 1
    butterRoll, mintTea, cocoaCookie, freshJuice,
    // Tier 2
    honeyToast, matchaLatte, chocolateCake, fruitTart, cinnamonRoll,
    // Tier 3
    cremeCaramel, coconutTaroSago, starryLollipop, tiramisu, saffronMillefeuille,
    // Tier 4
    moonlightMacaron, magicRainbowCake, stardustTruffle,
    goldenCrownPuff, auroraMillefeuille, patissierMasterpiece,
  ];

  static DessertRecipe? getById(String id) {
    for (final r in all) {
      if (r.id == id) return r;
    }
    return null;
  }

  static List<DessertRecipe> getByTier(int tier) {
    return all.where((r) => r.tier == tier).toList();
  }
}
