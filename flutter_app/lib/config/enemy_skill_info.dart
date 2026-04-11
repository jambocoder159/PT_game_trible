/// 敵人技能說明資料
/// 用於首次遭遇彈窗、敵人卡片圖示、長按詳情面板
import 'package:flutter/material.dart';
import '../core/models/enemy.dart';

class EnemySkillInfo {
  final EnemySkillType type;
  final String name;
  final String emoji;
  final IconData icon;
  final Color color;
  final String description;
  final String tip;

  const EnemySkillInfo({
    required this.type,
    required this.name,
    required this.emoji,
    required this.icon,
    required this.color,
    required this.description,
    required this.tip,
  });
}

const enemySkillInfoMap = <EnemySkillType, EnemySkillInfo>{
  EnemySkillType.obstacle: EnemySkillInfo(
    type: EnemySkillType.obstacle,
    name: '障礙',
    emoji: '🧱',
    icon: Icons.square_rounded,
    color: Color(0xFF9E9E9E),
    description: '在棋盤放置灰色障礙格，無法被消除，需要在旁邊消除 2 次才能破壞。',
    tip: '優先消除障礙旁邊的方塊來破壞它！',
  ),
  EnemySkillType.poison: EnemySkillInfo(
    type: EnemySkillType.poison,
    name: '毒格',
    emoji: '🟣',
    icon: Icons.science_rounded,
    color: Color(0xFF9C27B0),
    description: '在棋盤放置紫色毒格並開始倒數，歸零時會對全隊造成傷害。',
    tip: '直接消除毒格所在的方塊可以安全解除！',
  ),
  EnemySkillType.weaken: EnemySkillInfo(
    type: EnemySkillType.weaken,
    name: '弱化',
    emoji: '▼',
    icon: Icons.arrow_downward_rounded,
    color: Color(0xFFE65100),
    description: '標記棋盤上的方塊，被弱化的方塊消除時傷害和能量都減半。',
    tip: '優先消除其他方塊，或用技能清除弱化格！',
  ),
  EnemySkillType.shield: EnemySkillInfo(
    type: EnemySkillType.shield,
    name: '護盾',
    emoji: '🛡️',
    icon: Icons.shield_rounded,
    color: Color(0xFF00BCD4),
    description: '敵人獲得一層額外的護盾 HP，攻擊會先扣護盾再扣血量。',
    tip: '集中火力快速打破護盾！',
  ),
  EnemySkillType.charge: EnemySkillInfo(
    type: EnemySkillType.charge,
    name: '蓄力',
    emoji: '⚡',
    icon: Icons.bolt_rounded,
    color: Color(0xFFFFC107),
    description: '敵人開始蓄力，下一回合將發動 3 倍傷害的重擊！',
    tip: '看到蓄力提示時，確保團隊 HP 充足！',
  ),
  EnemySkillType.rage: EnemySkillInfo(
    type: EnemySkillType.rage,
    name: '狂暴',
    emoji: '🔥',
    icon: Icons.whatshot_rounded,
    color: Color(0xFFF44336),
    description: '當敵人 HP 低於 30% 時觸發，攻擊力翻倍且攻擊更頻繁！',
    tip: '趕在狂暴前擊敗，或準備好治療技能！',
  ),
  EnemySkillType.aura: EnemySkillInfo(
    type: EnemySkillType.aura,
    name: '屬性壓制',
    emoji: '🌀',
    icon: Icons.blur_circular_rounded,
    color: Color(0xFF3F51B5),
    description: '壓制特定屬性，該屬性方塊造成的傷害減半。',
    tip: '避免依賴被壓制的屬性，多消除其他顏色！',
  ),
  EnemySkillType.heal: EnemySkillInfo(
    type: EnemySkillType.heal,
    name: '回血',
    emoji: '💚',
    icon: Icons.favorite_rounded,
    color: Color(0xFF4CAF50),
    description: '敵人定期回復一定比例的最大 HP。',
    tip: '提高輸出節奏，別讓回血抵消你的傷害！',
  ),
  EnemySkillType.summon: EnemySkillInfo(
    type: EnemySkillType.summon,
    name: '召喚',
    emoji: '👻',
    icon: Icons.group_add_rounded,
    color: Color(0xFF1A237E),
    description: '定期召喚一隻小怪加入戰鬥，增加敵方數量。',
    tip: '優先擊敗召喚者，阻止更多小怪出現！',
  ),
};
