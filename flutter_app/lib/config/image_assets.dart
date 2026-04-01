/// 遊戲圖片素材路徑映射
///
/// 將角色 ID / 方塊顏色 / 敵人 / 背景 / UI 圖示對應到實際圖片檔案路徑
import 'package:flutter/material.dart';
import '../core/models/block.dart';
import '../core/models/cat_agent.dart';

class ImageAssets {
  ImageAssets._();

  static const _base = 'assets/images/output';
  static const _icons = 'assets/images/icons';

  // ═══════════════════════════════════════
  // 角色 ID → 圖片檔名映射
  // ═══════════════════════════════════════

  static const Map<String, String> _agentImageNames = {
    // 屬性A ☀️ 太陽 — 烘焙組
    'blaze': 'wheat',
    'ember': 'kiln',
    'inferno': 'caramel',
    // 屬性B 🍃 葉子 — 香草花園組
    'terra': 'matcha',
    'sprout': 'mint',
    'gaia': 'cinnamon',
    // 屬性C 💧 水滴 — 飲品吧組
    'tide': 'dew',
    'frost': 'shake',
    'tsunami': 'soda',
    // 屬性D ⭐ 星星 — 甜點裝飾組
    'flash': 'frosting',
    'spark': 'cotton',
    'thunder': 'croissant',
    // 屬性E 🌙 月亮 — 夜間甜品組
    'shadow': 'cocoa',
    'phantom': 'pudding',
    'eclipse': 'berry',
  };

  /// 取得角色立繪路徑
  static String? characterImage(String agentId) {
    final name = _agentImageNames[agentId];
    if (name == null) return null;
    return '$_base/characters/char_$name.png';
  }

  /// 取得角色頭像路徑
  static String? avatarImage(String agentId) {
    final name = _agentImageNames[agentId];
    if (name == null) return null;
    return '$_base/avatars/avatar_$name.png';
  }

  /// 取得角色小圖示路徑
  static String? iconImage(String agentId) {
    final name = _agentImageNames[agentId];
    if (name == null) return null;
    return '$_base/icons/icon_$name.png';
  }

  // ═══════════════════════════════════════
  // 方塊顏色 → 圖片路徑
  // ═══════════════════════════════════════

  static const Map<BlockColor, String> _blockImageNames = {
    BlockColor.coral: 'block_sun',
    BlockColor.teal: 'block_herb',
    BlockColor.mint: 'block_water',
    BlockColor.gold: 'block_star',
    BlockColor.rose: 'block_moon',
  };

  /// 取得方塊圖片路徑
  static String blockImage(BlockColor color, {bool dark = false}) {
    final name = _blockImageNames[color]!;
    final suffix = dark ? '_dark' : '';
    return '$_base/blocks/$name$suffix.png';
  }

  // ═══════════════════════════════════════
  // 背景圖映射
  // ═══════════════════════════════════════

  static const _bgBase = '$_base/background';

  static const Map<int, String> _battleBackgrounds = {
    1: 'bg_ch1_battle.png',
    2: 'bg_ch2_battle.png',
    3: 'bg_ch3_battle.png',
    4: 'bg_ch4_battle.png',
    5: 'bg_ch5_battle.png',
    6: 'bg_ch6_battle.png',
  };

  /// 取得戰鬥場景背景（依章節）
  static String? battleBackground(int chapter) {
    final name = _battleBackgrounds[chapter];
    if (name == null) return null;
    return '$_bgBase/$name';
  }

  /// 首頁背景
  static const homeBackground = '$_bgBase/bg_ch1_shop.png';

  /// 商店背景
  static const shopBackground = '$_bgBase/bg_ch2_shop.png';

  /// 角色資訊背景
  static const agentInfoBackground = '$_bgBase/bg_ch3_shop.png';

  // ═══════════════════════════════════════
  // 敵人圖片映射
  // ═══════════════════════════════════════

  /// 敵人 ID → 圖片檔名（食物搗蛋鬼，各有獨立圖片）
  static const Map<String, String> _enemyImageNames = {
    // Ch.1 爺爺的老麵包店
    'rat': 'moldy_bun',
    'big_rat': 'burnt_baguette',
    'stray_dog': 'sour_croissant',
    // Ch.2 冰淇淋小舖
    'pet_shop_guard': 'melted_popsicle',
    'trap_device': 'frozen_syrup',
    // Ch.3 巧克力工坊
    'dock_worker': 'burnt_cocoa',
    'seagull': 'popping_candy',
    // Ch.4 蛋糕塔
    'security_bot': 'stale_cake',
    'laser_trap': 'whipped_cream',
    'elite_security': 'clumpy_butter',
    // Ch.5 和菓子茶屋
    'shadow_agent_enemy': 'hard_mochi',
    'shadow_sniper': 'exploding_bean',
    // Ch.6 甜點街大廣場
    'elite_guard': 'rotten_fruit_tart',
    'heavy_bot': 'petrified_mille',
  };

  /// Boss → 章節 Boss 圖
  static const Map<String, String> _bossImageNames = {
    'rat_boss': 'boss_ch1',
    'shop_owner': 'boss_ch2',
    'seagull_boss': 'boss_ch3',
    'ceo': 'boss_ch4',
    'shadow_commander': 'boss_ch5',
    'final_boss': 'boss_ch6',
  };

  /// 取得敵人圖片路徑
  static String enemyImage(String enemyId) {
    // 先查 boss
    final bossName = _bossImageNames[enemyId];
    if (bossName != null) {
      return '$_base/bosses/$bossName.png';
    }
    // 再查通用怪
    final name = _enemyImageNames[enemyId] ?? 'moldy_bun'; // fallback
    return '$_base/enemies/enemy_$name.png';
  }

  /// 取得章節 Boss 圖片路徑
  static String bossImage(int chapter) {
    return '$_base/bosses/boss_ch$chapter.png';
  }

  // ═══════════════════════════════════════
  // 屬性圖示
  // ═══════════════════════════════════════

  static const Map<AgentAttribute, String> _attributeIcons = {
    AgentAttribute.attributeA: 'icon_attr_sun',
    AgentAttribute.attributeB: 'icon_attr_herb',
    AgentAttribute.attributeC: 'icon_attr_water',
    AgentAttribute.attributeD: 'icon_attr_star',
    AgentAttribute.attributeE: 'icon_attr_moon',
  };

  /// 取得屬性圖示路徑
  static String attributeIcon(AgentAttribute attr) {
    final name = _attributeIcons[attr]!;
    return '$_icons/$name.png';
  }

  // ═══════════════════════════════════════
  // 職業圖示
  // ═══════════════════════════════════════

  static const Map<AgentRole, String> _roleIcons = {
    AgentRole.striker: 'icon_role_striker',
    AgentRole.defender: 'icon_role_defender',
    AgentRole.supporter: 'icon_role_supporter',
    AgentRole.destroyer: 'icon_role_destroyer',
    AgentRole.infiltrator: 'icon_role_infiltrator',
  };

  /// 取得職業圖示路徑
  static String roleIcon(AgentRole role) {
    final name = _roleIcons[role]!;
    return '$_icons/$name.png';
  }

  // ═══════════════════════════════════════
  // UI 通用圖示
  // ═══════════════════════════════════════

  static const coin = '$_icons/icon_candy_coin.png';
  static const diamond = '$_icons/icon_rainbow_candy.png';
  static const energy = '$_icons/icon_energy.png';
  static const attack = '$_icons/icon_attack.png';
  static const defense = '$_icons/icon_defense.png';
  static const hp = '$_icons/icon_hp.png';
  static const starEmpty = '$_icons/icon_star_empty.png';
  static const starHalf = '$_icons/icon_star_half.png';
  static const starFull = '$_icons/icon_star_full.png';
  static const chestClosed = '$_icons/icon_chest_closed.png';
  static const chestOpen = '$_icons/icon_chest_open.png';
  static const back = '$_icons/icon_back.png';
  static const pause = '$_icons/icon_pause.png';
  static const settings = '$_icons/icon_settings.png';
  static const lock = '$_icons/icon_lock.png';

  // ═══════════════════════════════════════
  // VFX 特效
  // ═══════════════════════════════════════

  static const Map<AgentAttribute, String> _skillVfx = {
    AgentAttribute.attributeA: 'vfx_skill_sun',
    AgentAttribute.attributeB: 'vfx_skill_herb',
    AgentAttribute.attributeC: 'vfx_skill_water',
    AgentAttribute.attributeD: 'vfx_skill_star',
    AgentAttribute.attributeE: 'vfx_skill_moon',
  };

  /// 取得技能特效圖片路徑
  static String skillVfx(AgentAttribute attr) {
    final name = _skillVfx[attr]!;
    return '$_base/vfx/$name.png';
  }

  static const comboFireVfx = '$_base/vfx/vfx_combo_fire.png';
  static const orbsVfx = '$_base/vfx/vfx_orbs.png';
  static const damageFontVfx = '$_base/vfx/font_damage.png';
}

// ═══════════════════════════════════════
// Helper Widget：圖片載入 + emoji fallback
// ═══════════════════════════════════════

/// 顯示遊戲素材圖片，載入失敗時顯示 emoji fallback
class GameImage extends StatelessWidget {
  final String assetPath;
  final String fallbackEmoji;
  final double? width;
  final double? height;
  final BoxFit fit;

  const GameImage({
    super.key,
    required this.assetPath,
    this.fallbackEmoji = '❓',
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Text(
            fallbackEmoji,
            style: TextStyle(fontSize: (width ?? height ?? 24) * 0.6),
          ),
        ),
      ),
    );
  }
}

/// 顯示小型圖示（屬性、職業、金幣等），載入失敗顯示 emoji
class GameIcon extends StatelessWidget {
  final String assetPath;
  final String fallbackEmoji;
  final double size;

  const GameIcon({
    super.key,
    required this.assetPath,
    this.fallbackEmoji = '❓',
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Text(
        fallbackEmoji,
        style: TextStyle(fontSize: size * 0.8),
      ),
    );
  }
}
