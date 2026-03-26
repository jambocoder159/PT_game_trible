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
    // 屬性A 🔴 火系
    'blaze': 'lightning_claw',
    'ember': 'flame_fang',
    'inferno': 'crimson_shadow',
    // 屬性B 🟢 大地系
    'terra': 'storm_blade',
    'sprout': 'ice_eye',
    'gaia': 'azure_star',
    // 屬性C 🔵 水系
    'tide': 'jade_leaf',
    'frost': 'venom_mist',
    'tsunami': 'forest_guardian',
    // 屬性D 🟡 雷系
    'flash': 'thunder_claw',
    'spark': 'golden_sand',
    'thunder': 'sun_herald',
    // 屬性E 🟣 暗系
    'shadow': 'rose_thorn',
    'phantom': 'blood_moon',
    'eclipse': 'moonlight',
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
    BlockColor.coral: 'block_coral',
    BlockColor.teal: 'block_teal',
    BlockColor.mint: 'block_mint',
    BlockColor.gold: 'block_gold',
    BlockColor.rose: 'block_rose',
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
    1: 'Dark_forest_with_202603261716.jpeg',
    2: 'Crystal_cave_underground_202603261716.jpeg',
    3: 'Castle_corridor_interior_202603261716.jpeg',
    4: 'Snowy_mountain_peak_202603261716.jpeg',
    5: 'Volcanic_hellscape_with_202603261716.jpeg',
    6: 'Demon_lord_throne_202603261716.jpeg',
  };

  /// 取得戰鬥場景背景（依章節）
  static String? battleBackground(int chapter) {
    final name = _battleBackgrounds[chapter];
    if (name == null) return null;
    return '$_bgBase/$name';
  }

  /// 首頁背景
  static const homeBackground =
      '$_bgBase/Spy_headquarters_control_202603261716.jpeg';

  /// 商店背景
  static const shopBackground =
      '$_bgBase/Cozy_cartoon_underground_202603261716.jpeg';

  /// 角色資訊背景
  static const agentInfoBackground =
      '$_bgBase/Tech_interface_background_202603261716.jpeg';

  // ═══════════════════════════════════════
  // 敵人圖片映射
  // ═══════════════════════════════════════

  /// 敵人 ID → 圖片檔名（5 張通用怪複用）
  static const Map<String, String> _enemyImageNames = {
    // 小型群體怪 → wolf
    'rat': 'wolf',
    'big_rat': 'wolf',
    // 中型肉盾怪 → bear
    'stray_dog': 'bear',
    'elite_guard': 'bear',
    'heavy_bot': 'bear',
    // 飛行/快攻怪 → hawk
    'seagull': 'hawk',
    'shadow_sniper': 'hawk',
    // 人型雜兵 → fox
    'pet_shop_guard': 'fox',
    'dock_worker': 'fox',
    'security_bot': 'fox',
    'elite_security': 'fox',
    'shadow_agent_enemy': 'fox',
    'shadow_commander': 'fox',
    // 機關/毒型怪 → snake
    'trap_device': 'snake',
    'laser_trap': 'snake',
  };

  /// Boss → 章節 Boss 圖
  static const Map<String, String> _bossImageNames = {
    'rat_boss': 'boss_ch1',
    'shop_owner': 'boss_ch2',
    'seagull_boss': 'boss_ch3',
    'ceo': 'boss_ch4',
    // shadowCommander 在第 5 章 boss 戰出現，但也是普通敵人
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
    final name = _enemyImageNames[enemyId] ?? 'wolf'; // fallback
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
    AgentAttribute.attributeA: 'icon_attr_fire',
    AgentAttribute.attributeB: 'icon_attr_nature',
    AgentAttribute.attributeC: 'icon_attr_water',
    AgentAttribute.attributeD: 'icon_attr_lightning',
    AgentAttribute.attributeE: 'icon_attr_shadow',
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

  static const coin = '$_icons/icon_coin.png';
  static const diamond = '$_icons/icon_diamond.png';
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
    AgentAttribute.attributeA: 'vfx_skill_a',
    AgentAttribute.attributeB: 'vfx_skill_b',
    AgentAttribute.attributeC: 'vfx_skill_c',
    AgentAttribute.attributeD: 'vfx_skill_d',
    AgentAttribute.attributeE: 'vfx_skill_e',
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
