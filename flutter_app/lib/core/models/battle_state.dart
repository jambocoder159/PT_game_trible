/// 戰鬥狀態
/// 管理一場戰鬥中的隊伍、敵人、技能充能等狀態
import 'cat_agent.dart';
import 'enemy.dart';
import 'block.dart';

/// 戰鬥中的角色實例
class BattleAgent {
  final CatAgentDefinition definition;
  final int level;
  int currentEnergy;
  int maxEnergy;

  BattleAgent({
    required this.definition,
    required this.level,
    this.currentEnergy = 0,
  }) : maxEnergy = definition.skill.energyCost;

  int get atk => definition.atkAtLevel(level);
  int get def => definition.defAtLevel(level);
  int get hp => definition.hpAtLevel(level);

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

  BattleState({
    required this.team,
    required this.enemies,
    this.currentEnemyIndex = 0,
    this.teamMaxHp = 0,
    this.teamCurrentHp = 0,
    this.turnCount = 0,
    this.shieldTurnsLeft = 0,
    this.shieldReduction = 0,
  });

  EnemyInstance? get currentEnemy {
    if (currentEnemyIndex >= enemies.length) return null;
    return enemies[currentEnemyIndex];
  }

  bool get allEnemiesDead => enemies.every((e) => e.isDead);
  bool get isTeamDead => teamCurrentHp <= 0;
  bool get isBattleOver => allEnemiesDead || isTeamDead;
  bool get isVictory => allEnemiesDead && !isTeamDead;

  /// 計算消除方塊對當前敵人造成的傷害
  /// 傷害公式: 每個方塊 = 對應屬性角色ATK * 屬性倍率
  int calculateMatchDamage(BlockColor blockColor, int matchCount) {
    // 找到該屬性的角色
    final agent = _findAgentByBlockColor(blockColor);
    if (agent == null) {
      // 隊伍中沒有該屬性角色 → 基礎傷害
      return matchCount * 5;
    }

    final enemy = currentEnemy;
    if (enemy == null) return 0;

    // 屬性倍率
    final multiplier = agent.definition.attribute
        .damageMultiplierAgainst(enemy.definition.attribute);

    // 傷害 = ATK * 方塊數 * 屬性倍率 * 0.5
    return (agent.atk * matchCount * multiplier * 0.5).round();
  }

  /// 根據方塊顏色找對應的隊伍角色
  BattleAgent? _findAgentByBlockColor(BlockColor blockColor) {
    for (final agent in team) {
      if (agent.definition.attribute.blockColor == blockColor) {
        return agent;
      }
    }
    return null;
  }

  /// 敵人攻擊隊伍
  int enemyAttack() {
    final enemy = currentEnemy;
    if (enemy == null) return 0;

    var damage = enemy.atk;

    // 護盾減傷
    if (shieldTurnsLeft > 0) {
      damage = (damage * (1 - shieldReduction / 100)).round();
      shieldTurnsLeft--;
    }

    teamCurrentHp = (teamCurrentHp - damage).clamp(0, teamMaxHp);
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
