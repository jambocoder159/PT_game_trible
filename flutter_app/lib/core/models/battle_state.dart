/// 戰鬥狀態
/// 管理一場戰鬥中的隊伍、敵人、技能充能等狀態
import '../../config/balance_config.dart';
import '../../config/battle_params.dart';
import 'cat_agent.dart';
import 'enemy.dart';
import 'block.dart';
import 'talent_tree.dart';
import 'passive_skill.dart';

/// 持續傷害效果
class DotEffect {
  final int damagePerTurn;
  int turnsRemaining;

  DotEffect({required this.damagePerTurn, required this.turnsRemaining});
}

/// 戰鬥中的角色實例
class BattleAgent {
  final CatAgentDefinition definition;
  final int level;
  int currentEnergy;
  int maxEnergy;

  // 自動攻擊倒數（tick-based）
  int attackCountdown;

  // 養成系統數據
  final int skillTier;
  final int evolutionStage;
  final double evoAtkMult;
  final double evoDefMult;
  final double evoHpMult;
  final List<TalentNodeDefinition> unlockedTalents;
  final List<PassiveSkillDefinition> equippedPassives;

  // 天賦加成快取
  late final double _atkBonus;
  late final double _defBonus;
  late final double _hpBonus;

  BattleAgent({
    required this.definition,
    required this.level,
    this.currentEnergy = 0,
    this.skillTier = 1,
    this.evolutionStage = 0,
    this.evoAtkMult = 1.0,
    this.evoDefMult = 1.0,
    this.evoHpMult = 1.0,
    List<TalentNodeDefinition>? unlockedTalents,
    List<PassiveSkillDefinition>? equippedPassives,
  })  : maxEnergy = definition.skill.energyCost,
        attackCountdown = definition.baseSpeed,
        unlockedTalents = unlockedTalents ?? [],
        equippedPassives = equippedPassives ?? [] {
    // 計算天賦百分比加成
    _atkBonus = _sumTalentBonus(TalentEffectType.atkPercent);
    _defBonus = _sumTalentBonus(TalentEffectType.defPercent);
    _hpBonus = _sumTalentBonus(TalentEffectType.hpPercent);
  }

  double _sumTalentBonus(TalentEffectType type) {
    double total = 0;
    for (final t in unlockedTalents) {
      if (t.effectType == type) total += t.effectValue;
    }
    return total;
  }

  double getTalentBonus(TalentEffectType type) {
    return _sumTalentBonus(type);
  }

  bool hasPassive(PassiveEffectType type) {
    return equippedPassives.any((p) => p.effectType == type);
  }

  PassiveSkillDefinition? getPassive(PassiveEffectType type) {
    for (final p in equippedPassives) {
      if (p.effectType == type) return p;
    }
    return null;
  }

  int get atk {
    final base = definition.atkAtLevel(level);
    return (base * evoAtkMult * (1 + _atkBonus / 100)).round();
  }

  int get def {
    final base = definition.defAtLevel(level);
    return (base * evoDefMult * (1 + _defBonus / 100)).round();
  }

  int get hp {
    final base = definition.hpAtLevel(level);
    return (base * evoHpMult * (1 + _hpBonus / 100)).round();
  }

  /// 速度值（tick 數 / 每次普攻）
  int get speed => definition.baseSpeed;

  /// 攻擊倒數進度（1.0=剛攻擊完，0.0=即將攻擊）
  double get attackCountdownPercent =>
      speed > 0 ? attackCountdown / speed : 0;

  bool get isSkillReady => currentEnergy >= maxEnergy;
  double get energyPercent => maxEnergy > 0 ? currentEnergy / maxEnergy : 0;

  /// 累積能量
  void addEnergy(int amount) {
    currentEnergy = (currentEnergy + amount).clamp(0, maxEnergy);
  }

  /// 使用技能（重置能量）
  void useSkill() {
    currentEnergy = 0;
  }
}

/// 戰鬥狀態
class BattleState {
  final List<BattleAgent> team;
  final List<EnemyInstance> enemies;
  int currentEnemyIndex;
  int teamMaxHp;
  int teamCurrentHp;
  int turnCount;
  int shieldTurnsLeft; // 減傷護盾剩餘回合
  double shieldReduction; // 減傷百分比

  // 養成系統追蹤
  bool firstAttackDone;              // 暗影首擊被動
  List<DotEffect> activeDots;        // DoT 效果列表
  Map<String, bool> triggeredOnce;   // 一次性效果追蹤
  int defDebuffTurns;                // 敵人破防剩餘回合
  double defDebuffPercent;           // 破防百分比
  double reflectPercent;             // 反射傷害百分比
  int reflectTurnsLeft;              // 反射剩餘回合
  int hotTurnsLeft;                  // HoT 剩餘回合
  double hotPercent;                 // HoT 回復百分比
  int lastCombo;                     // 上一次的 combo 數

  int tickCount; // 消方塊驅動的時間軸計數

  /// 角色累積傷害（combo 前）— 每次連鎖累積，回合結束時統一打出
  final Map<String, int> pendingDamage = {};

  // ─── 敵人技能：棋盤狀態 ───
  final List<ObstacleBlock> obstacleBlocks = [];
  final List<PoisonBlock> poisonBlocks = [];
  final List<WeakenedBlock> weakenedBlocks = [];

  // ─── 敵人技能：屬性壓制 ───
  /// 被壓制的屬性列表（場上所有 aura 敵人的壓制屬性）
  final Set<AgentAttribute> suppressedAttributes = {};

  BattleState({
    required this.team,
    required this.enemies,
    this.currentEnemyIndex = 0,
    this.teamMaxHp = 0,
    this.teamCurrentHp = 0,
    this.turnCount = 0,
    this.tickCount = 0,
    this.shieldTurnsLeft = 0,
    this.shieldReduction = 0,
    this.firstAttackDone = false,
    List<DotEffect>? activeDots,
    Map<String, bool>? triggeredOnce,
    this.defDebuffTurns = 0,
    this.defDebuffPercent = 0,
    this.reflectPercent = 0,
    this.reflectTurnsLeft = 0,
    this.hotTurnsLeft = 0,
    this.hotPercent = 0,
    this.lastCombo = 0,
  })  : activeDots = activeDots ?? [],
        triggeredOnce = triggeredOnce ?? {};

  /// 初始化敵人技能狀態（戰鬥開始時呼叫）
  void initEnemySkills() {
    // 收集所有屬性壓制光環
    for (final enemy in enemies) {
      final auraSkill = enemy.getSkill(EnemySkillType.aura);
      if (auraSkill != null && auraSkill.suppressedAttribute != null) {
        suppressedAttributes.add(auraSkill.suppressedAttribute!);
      }
    }
  }

  /// 檢查某個位置是否有障礙格
  bool isObstacle(int col, int row) =>
      obstacleBlocks.any((b) => b.col == col && b.row == row && !b.isBroken);

  /// 檢查某個位置是否有毒格
  PoisonBlock? getPoisonAt(int col, int row) {
    for (final p in poisonBlocks) {
      if (p.col == col && p.row == row && !p.isExpired) return p;
    }
    return null;
  }

  /// 檢查某個位置是否有弱化標記
  bool isWeakened(int col, int row) =>
      weakenedBlocks.any((b) => b.col == col && b.row == row && !b.isExpired);

  /// 檢查某屬性是否被壓制
  bool isAttributeSuppressed(AgentAttribute attr) =>
      suppressedAttributes.contains(attr);

  BattleParams get _params => BalanceConfig.instance.battleParams;

  EnemyInstance? get currentEnemy {
    if (currentEnemyIndex >= enemies.length) return null;
    return enemies[currentEnemyIndex];
  }

  bool get allEnemiesDead => enemies.every((e) => e.isDead);
  bool get isTeamDead => teamCurrentHp <= 0;
  bool get isBattleOver => allEnemiesDead || isTeamDead;
  bool get isVictory => allEnemiesDead && !isTeamDead;

  /// 計算存活敵人數量
  int get aliveEnemyCount => enemies.where((e) => !e.isDead).length;

  /// 計算消除方塊對當前敵人造成的傷害
  /// [weakenedCount] 其中有多少格帶弱化標記
  int calculateMatchDamage(BlockColor blockColor, int matchCount, {int weakenedCount = 0}) {
    final agent = findAgentByBlockColor(blockColor);
    if (agent == null) {
      return matchCount * _params.noAgentMatchDamage;
    }

    final enemy = currentEnemy;
    if (enemy == null) return 0;

    final multiplier = agent.definition.attribute
        .damageMultiplierAgainst(enemy.definition.attribute);

    var damage = (agent.atk * matchCount * multiplier * _params.matchDamageCoefficient).round();

    // 屬性壓制：被壓制屬性的方塊傷害 -50%
    if (isAttributeSuppressed(agent.definition.attribute)) {
      damage = (damage * 0.5).round();
    }

    // 弱化格：弱化的方塊傷害 -50%（按比例折扣）
    if (weakenedCount > 0 && matchCount > 0) {
      final normalCount = matchCount - weakenedCount;
      final normalRatio = normalCount / matchCount;
      final weakenedRatio = weakenedCount / matchCount;
      damage = (damage * (normalRatio + weakenedRatio * 0.5)).round();
    }

    // 天賦：消除傷害加成
    final matchDmgUp = agent.getTalentBonus(TalentEffectType.matchDamageUp);
    if (matchDmgUp > 0) {
      damage = (damage * (1 + matchDmgUp / 100)).round();
    }

    // 被動：首擊加成
    if (!firstAttackDone) {
      final firstStrike = agent.getPassive(PassiveEffectType.firstStrikeBonus);
      if (firstStrike != null) {
        damage = (damage * firstStrike.effectValue).round();
      }
    }

    // 被動：攻擊低血敵人加成
    final lowEnemyBonus = agent.getPassive(PassiveEffectType.lowEnemyHpBonus);
    if (lowEnemyBonus != null && enemy.hpPercent < _params.lowEnemyHpThreshold) {
      damage = (damage * (1 + lowEnemyBonus.effectValue)).round();
    }

    // 被動：長連鎖加成
    final chainBonus = agent.getPassive(PassiveEffectType.matchChainBonus);
    if (chainBonus != null && matchCount >= _params.longChainThreshold) {
      damage = (damage * (1 + chainBonus.effectValue)).round();
    }

    // 敵人破防
    if (defDebuffTurns > 0) {
      damage = (damage * (1 + defDebuffPercent)).round();
    }

    return damage;
  }

  /// 計算角色自動普攻對敵人的傷害
  int calculateAutoAttackDamage(BattleAgent agent, EnemyInstance target) {
    final multiplier = agent.definition.attribute
        .damageMultiplierAgainst(target.definition.attribute);

    var damage = (agent.atk * multiplier).round();

    // 天賦：消除傷害加成（沿用在普攻上）
    final matchDmgUp = agent.getTalentBonus(TalentEffectType.matchDamageUp);
    if (matchDmgUp > 0) {
      damage = (damage * (1 + matchDmgUp / 100)).round();
    }

    // 被動：首擊加成
    if (!firstAttackDone) {
      final firstStrike = agent.getPassive(PassiveEffectType.firstStrikeBonus);
      if (firstStrike != null) {
        damage = (damage * firstStrike.effectValue).round();
      }
    }

    // 被動：攻擊低血敵人加成
    final lowEnemyBonus = agent.getPassive(PassiveEffectType.lowEnemyHpBonus);
    if (lowEnemyBonus != null && target.hpPercent < _params.lowEnemyHpThreshold) {
      damage = (damage * (1 + lowEnemyBonus.effectValue)).round();
    }

    // 敵人破防
    if (defDebuffTurns > 0) {
      damage = (damage * (1 + defDebuffPercent)).round();
    }

    return damage;
  }

  /// 根據方塊顏色找對應的隊伍角色
  BattleAgent? findAgentByBlockColor(BlockColor blockColor) {
    for (final agent in team) {
      if (agent.definition.attribute.blockColor == blockColor) {
        return agent;
      }
    }
    return null;
  }

  /// 敵人攻擊隊伍（指定敵人，預設當前敵人）
  int enemyAttackFrom(EnemyInstance enemy) {
    var damage = enemy.atk;

    // 蓄力重擊：3 倍傷害
    if (enemy.skillState.isCharging) {
      damage = (damage * 3).round();
      enemy.skillState.isCharging = false;
    }

    // 護盾減傷
    if (shieldTurnsLeft > 0) {
      damage = (damage * (1 - shieldReduction / 100)).round();
      shieldTurnsLeft--;
    }

    // 天賦：減傷
    for (final agent in team) {
      final dmgRed = agent.getTalentBonus(TalentEffectType.dmgReduction);
      if (dmgRed > 0) {
        damage = (damage * (1 - dmgRed / 100)).round();
        break;
      }
    }

    // 被動：固定減傷
    for (final agent in team) {
      final passive = agent.getPassive(PassiveEffectType.dmgReduction);
      if (passive != null) {
        damage = (damage * (1 - passive.effectValue)).round();
        break;
      }
    }

    teamCurrentHp = (teamCurrentHp - damage).clamp(0, teamMaxHp);

    // 被動：受傷獲得能量
    for (final agent in team) {
      final energyPassive = agent.getPassive(PassiveEffectType.energyOnDamaged);
      if (energyPassive != null) {
        agent.addEnergy(energyPassive.effectValue.round());
      }
    }

    // 反射傷害
    if (reflectTurnsLeft > 0 && enemy.currentHp > 0) {
      final reflectDmg = (damage * reflectPercent).round();
      if (reflectDmg > 0) {
        enemy.takeDamage(reflectDmg);
        if (enemy.isDead) advanceToNextEnemy();
      }
    }

    // 被動：急救本能
    if (teamCurrentHp > 0 && teamCurrentHp < teamMaxHp * _params.emergencyHealThreshold) {
      for (final agent in team) {
        if (agent.definition.id == 'tide') {
          final emergencyHeal = agent.getPassive(PassiveEffectType.lowHpBoost);
          if (emergencyHeal != null && triggeredOnce['tide_emergency_heal'] != true) {
            final healAmount = (teamMaxHp * emergencyHeal.effectValue).round();
            teamCurrentHp = (teamCurrentHp + healAmount).clamp(0, teamMaxHp);
            triggeredOnce['tide_emergency_heal'] = true;
          }
        }
      }
    }

    return damage;
  }

  /// 敵人攻擊隊伍（舊介面，向下相容）
  int enemyAttack() {
    final enemy = currentEnemy;
    if (enemy == null) return 0;

    var damage = enemy.atk;

    // 護盾減傷
    if (shieldTurnsLeft > 0) {
      damage = (damage * (1 - shieldReduction / 100)).round();
      shieldTurnsLeft--;
    }

    // 天賦：減傷
    for (final agent in team) {
      final dmgRed = agent.getTalentBonus(TalentEffectType.dmgReduction);
      if (dmgRed > 0) {
        damage = (damage * (1 - dmgRed / 100)).round();
        break; // 只取第一個有減傷天賦的角色
      }
    }

    // 被動：固定減傷
    for (final agent in team) {
      final passive = agent.getPassive(PassiveEffectType.dmgReduction);
      if (passive != null) {
        damage = (damage * (1 - passive.effectValue)).round();
        break;
      }
    }

    teamCurrentHp = (teamCurrentHp - damage).clamp(0, teamMaxHp);

    // 被動：反擊
    for (final agent in team) {
      final counter = agent.getPassive(PassiveEffectType.counterAttack);
      if (counter != null) {
        // counter.effectValue 是觸發機率
        // 這裡簡化為固定觸發（戰鬥引擎不引入隨機數）
        // 實際觸發會在 BattleEngine 中處理
      }
    }

    // 被動：受傷獲得能量
    for (final agent in team) {
      final energyPassive = agent.getPassive(PassiveEffectType.energyOnDamaged);
      if (energyPassive != null) {
        agent.addEnergy(energyPassive.effectValue.round());
      }
    }

    // 反射傷害
    if (reflectTurnsLeft > 0 && enemy.currentHp > 0) {
      final reflectDmg = (damage * reflectPercent).round();
      if (reflectDmg > 0) {
        enemy.takeDamage(reflectDmg);
        if (enemy.isDead) advanceToNextEnemy();
      }
    }

    // 被動：急救本能（露露的一次性自動治療）
    if (teamCurrentHp > 0 && teamCurrentHp < teamMaxHp * _params.emergencyHealThreshold) {
      for (final agent in team) {
        if (agent.definition.id == 'tide') {
          final emergencyHeal = agent.getPassive(PassiveEffectType.lowHpBoost);
          if (emergencyHeal != null && triggeredOnce['tide_emergency_heal'] != true) {
            final healAmount = (teamMaxHp * emergencyHeal.effectValue).round();
            teamCurrentHp = (teamCurrentHp + healAmount).clamp(0, teamMaxHp);
            triggeredOnce['tide_emergency_heal'] = true;
          }
        }
      }
    }

    return damage;
  }

  /// 推進到下一個存活的敵人
  void advanceToNextEnemy() {
    while (currentEnemyIndex < enemies.length &&
        enemies[currentEnemyIndex].isDead) {
      currentEnemyIndex++;
    }
  }
}
