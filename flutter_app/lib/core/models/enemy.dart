/// 敵人模型
/// 關卡中出現的敵人定義和實例
import '../models/cat_agent.dart';

// ─── 敵人技能系統 ───

/// 敵人技能類型
enum EnemySkillType {
  /// 棋盤干擾：生成灰色障礙格（需相鄰消除 2 次或技能消除清除）
  obstacle,

  /// 棋盤干擾：將方塊染毒並倒數，歸零時對玩家造成傷害
  poison,

  /// 棋盤干擾：標記方塊使其消除傷害和能量減半
  weaken,

  /// 戰鬥強化：獲得額外 HP 層
  shield,

  /// 戰鬥強化：預告後 1 回合發動 3 倍傷害攻擊
  charge,

  /// 戰鬥強化：HP < 30% 時 ATK x2、攻擊間隔 -1
  rage,

  /// 策略壓制：壓制特定屬性，該屬性方塊傷害 -50%
  aura,

  /// 戰鬥強化：每 N 回合回復 X% maxHP
  heal,

  /// Boss 專屬：每 N 回合召喚 1 隻小怪
  summon,
}

/// 敵人技能定義（靜態配置）
class EnemySkillDefinition {
  final EnemySkillType type;

  // ── 棋盤干擾參數 ──
  /// 影響格數（obstacle: 2~4, poison: 2~3, weaken: 3~5）
  final int blockCount;

  /// 觸發頻率（每幾回合觸發一次）
  final int cooldown;

  /// 毒格倒數回合數（僅 poison 使用）
  final int poisonCountdown;

  // ── 戰鬥強化參數 ──
  /// 護盾百分比（shield: 0.2~0.4 = 20%~40% maxHP）
  final double shieldPercent;

  /// 回血百分比（heal: 0.05~0.10）
  final double healPercent;

  /// 回血頻率（每幾回合回血一次）
  final int healCooldown;

  // ── 屬性壓制參數 ──
  /// 被壓制的屬性（aura 使用）
  final AgentAttribute? suppressedAttribute;

  // ── 召喚參數 ──
  /// 召喚頻率（每幾回合召喚）
  final int summonCooldown;

  /// 召喚的敵人定義（由 stage_data 指定）
  final EnemyDefinition? summonEnemy;

  const EnemySkillDefinition({
    required this.type,
    this.blockCount = 2,
    this.cooldown = 4,
    this.poisonCountdown = 3,
    this.shieldPercent = 0.2,
    this.healPercent = 0.05,
    this.healCooldown = 5,
    this.suppressedAttribute,
    this.summonCooldown = 6,
    this.summonEnemy,
  });

  /// 快速建構器
  const EnemySkillDefinition.obstacle({
    int count = 2,
    int cooldown = 4,
  }) : this(type: EnemySkillType.obstacle, blockCount: count, cooldown: cooldown);

  const EnemySkillDefinition.poison({
    int count = 2,
    int countdown = 3,
    int cooldown = 4,
  }) : this(type: EnemySkillType.poison, blockCount: count, poisonCountdown: countdown, cooldown: cooldown);

  const EnemySkillDefinition.weaken({
    int count = 3,
    int cooldown = 4,
  }) : this(type: EnemySkillType.weaken, blockCount: count, cooldown: cooldown);

  const EnemySkillDefinition.shield({
    double percent = 0.2,
  }) : this(type: EnemySkillType.shield, shieldPercent: percent);

  const EnemySkillDefinition.charge()
      : this(type: EnemySkillType.charge);

  const EnemySkillDefinition.rage()
      : this(type: EnemySkillType.rage);

  const EnemySkillDefinition.aura({
    required AgentAttribute suppressed,
  }) : this(type: EnemySkillType.aura, suppressedAttribute: suppressed);

  const EnemySkillDefinition.heal({
    double percent = 0.05,
    int cooldown = 5,
  }) : this(type: EnemySkillType.heal, healPercent: percent, healCooldown: cooldown);

  const EnemySkillDefinition.summon({
    int cooldown = 6,
    EnemyDefinition? enemy,
  }) : this(type: EnemySkillType.summon, summonCooldown: cooldown, summonEnemy: enemy);
}

/// 敵人定義（靜態數據）
class EnemyDefinition {
  final String id;
  final String name;
  final String emoji; // 簡易圖示
  final AgentAttribute attribute;
  final int baseHp;
  final int baseAtk;
  final int attackInterval; // 每幾回合攻擊一次
  final List<EnemySkillDefinition> skills; // 敵人技能列表

  const EnemyDefinition({
    required this.id,
    required this.name,
    required this.emoji,
    required this.attribute,
    required this.baseHp,
    required this.baseAtk,
    this.attackInterval = 3,
    this.skills = const [],
  });
}

// ─── 敵人技能運行時狀態 ───

/// 障礙格狀態
class ObstacleBlock {
  final int col;
  final int row;
  int hitCount; // 被相鄰消除幾次了（2 次碎裂）

  ObstacleBlock({required this.col, required this.row, this.hitCount = 0});
  bool get isBroken => hitCount >= 2;
}

/// 毒格狀態
class PoisonBlock {
  final int col;
  final int row;
  int countdown; // 歸零時爆炸

  PoisonBlock({required this.col, required this.row, required this.countdown});
  bool get isExpired => countdown <= 0;
}

/// 弱化格狀態
class WeakenedBlock {
  final int col;
  final int row;
  int turnsLeft; // 剩餘回合

  WeakenedBlock({required this.col, required this.row, this.turnsLeft = 2});
  bool get isExpired => turnsLeft <= 0;
}

/// 敵人技能運行時狀態（掛在 EnemyInstance 上）
class EnemySkillState {
  // ── 冷卻追蹤 ──
  final Map<EnemySkillType, int> cooldownTimers = {};

  // ── 護盾 ──
  int shieldHp = 0;
  int shieldMaxHp = 0;

  // ── 蓄力 ──
  bool isCharging = false;

  // ── 狂暴 ──
  bool isEnraged = false;
  int originalAttackInterval = 0;

  /// 初始化冷卻計時器
  void initCooldowns(List<EnemySkillDefinition> skills) {
    for (final skill in skills) {
      switch (skill.type) {
        case EnemySkillType.obstacle:
        case EnemySkillType.poison:
        case EnemySkillType.weaken:
          cooldownTimers[skill.type] = skill.cooldown;
          break;
        case EnemySkillType.heal:
          cooldownTimers[skill.type] = skill.healCooldown;
          break;
        case EnemySkillType.summon:
          cooldownTimers[skill.type] = skill.summonCooldown;
          break;
        default:
          break;
      }
    }
  }

  /// 推進冷卻計時器，回傳本回合應觸發的技能類型列表
  List<EnemySkillType> tickCooldowns() {
    final triggered = <EnemySkillType>[];
    for (final type in cooldownTimers.keys.toList()) {
      cooldownTimers[type] = cooldownTimers[type]! - 1;
      if (cooldownTimers[type]! <= 0) {
        triggered.add(type);
      }
    }
    return triggered;
  }

  /// 重置指定技能的冷卻
  void resetCooldown(EnemySkillType type, int cooldown) {
    cooldownTimers[type] = cooldown;
  }
}

/// 戰鬥中的敵人實例（可變狀態）
class EnemyInstance {
  final EnemyDefinition definition;
  int currentHp;
  int maxHp;
  int atk;
  int attackCountdown; // 距離下次攻擊的回合數

  // 技能運行時狀態
  final EnemySkillState skillState = EnemySkillState();

  EnemyInstance({
    required this.definition,
    required this.maxHp,
    required this.atk,
  })  : currentHp = maxHp,
        attackCountdown = definition.attackInterval {
    // 初始化技能冷卻
    skillState.initCooldowns(definition.skills);
    skillState.originalAttackInterval = definition.attackInterval;

    // 開場護盾
    final shieldSkills = definition.skills.where((s) => s.type == EnemySkillType.shield);
    if (shieldSkills.isNotEmpty) {
      final shieldDef = shieldSkills.first;
      skillState.shieldHp = (maxHp * shieldDef.shieldPercent).round();
      skillState.shieldMaxHp = skillState.shieldHp;
    }
  }

  /// 從定義 + 難度倍率建立
  factory EnemyInstance.fromDefinition(
    EnemyDefinition def, {
    double hpMultiplier = 1.0,
    double atkMultiplier = 1.0,
  }) {
    final hp = (def.baseHp * hpMultiplier).round();
    return EnemyInstance(
      definition: def,
      maxHp: hp,
      atk: (def.baseAtk * atkMultiplier).round(),
    );
  }

  bool get isDead => currentHp <= 0;
  double get hpPercent => maxHp > 0 ? currentHp / maxHp : 0;
  bool get hasShield => skillState.shieldHp > 0;

  /// 是否擁有特定技能
  bool hasSkill(EnemySkillType type) =>
      definition.skills.any((s) => s.type == type);

  /// 取得特定技能定義
  EnemySkillDefinition? getSkill(EnemySkillType type) {
    for (final s in definition.skills) {
      if (s.type == type) return s;
    }
    return null;
  }

  /// 受到傷害（先扣護盾再扣血，回傳實際對本體的傷害值）
  int takeDamage(int damage) {
    if (skillState.shieldHp > 0) {
      if (damage <= skillState.shieldHp) {
        skillState.shieldHp -= damage;
        return 0;
      } else {
        final overflow = damage - skillState.shieldHp;
        skillState.shieldHp = 0;
        final actual = overflow.clamp(0, currentHp);
        currentHp -= actual;
        _checkRage();
        return actual;
      }
    }

    final actual = damage.clamp(0, currentHp);
    currentHp -= actual;
    _checkRage();
    return actual;
  }

  /// 檢查是否觸發狂暴
  void _checkRage() {
    if (!skillState.isEnraged && hasSkill(EnemySkillType.rage) && hpPercent < 0.3 && !isDead) {
      skillState.isEnraged = true;
      atk = (atk * 2).round();
      // 攻擊間隔 -1（最少 1）
      final newInterval = (definition.attackInterval - 1).clamp(1, 99);
      attackCountdown = attackCountdown.clamp(1, newInterval);
    }
  }

  /// 取得實際攻擊間隔（考慮狂暴）
  int get effectiveAttackInterval {
    if (skillState.isEnraged) {
      return (definition.attackInterval - 1).clamp(1, 99);
    }
    return definition.attackInterval;
  }

  /// 倒數攻擊計時，回傳是否要攻擊
  bool tickAttack() {
    attackCountdown--;
    if (attackCountdown <= 0) {
      attackCountdown = effectiveAttackInterval;
      return true;
    }
    return false;
  }

  /// 敵人回血
  void applyHeal(double percent) {
    final healAmount = (maxHp * percent).round();
    currentHp = (currentHp + healAmount).clamp(0, maxHp);
  }
}
