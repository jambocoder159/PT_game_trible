/// 遊戲圖片素材路徑映射
///
/// 將角色 ID / 方塊顏色對應到實際圖片檔案路徑
import '../core/models/block.dart';

class ImageAssets {
  ImageAssets._();

  static const _base = 'assets/images/output';

  // ─── 角色 ID → 圖片檔名映射 ───
  // 根據 asset_inventory.md 中的角色屬性/職業/稀有度對應
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

  // ─── 方塊顏色 → 圖片路徑 ───

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
}
