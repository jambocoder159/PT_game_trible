/// 戰鬥引擎
/// 處理傷害計算、技能效果、敵人回擊
import '../models/battle_state.dart';
import '../models/cat_agent.dart';
import '../models/block.dart';

/// 技能效果結果
class SkillResult {
  final String description;
  final int damageDealt;
  final int hpHealed;
  final int shieldTurns;
  final double shieldPercent;

  const SkillResult({
    required this.description,
    this.damageDealt = 0,
    this.hpHealed = 0,
    this.shieldTurns = 0,
    this.shieldPercent = 0,
  });
}

/// 回合結算結果
class TurnResult {
  final Map<BlockColor, int> damageByColor; // 每種顏色造成的傷害
  final int totalDamage;
  final Map<String, int> energyGained; // 角色ID → 獲得能量
  final bool enemyKilled;
  final bool enemyAttacked; // 敵人是否反擊
  final int enemyDamage; // 敵人造成的傷害

  const TurnResult({
    required this.damageByColor,
    required this.totalDamage,
    required this.energyGained,
    this.enemyKilled = false,
    this.enemyAttacked = false,
    this.enemyDamage = 0,
  });
}

class BattleEngine {
  BattleEngine._();

  /// 處理一次消除的傷害和能量
  /// matches: 此次消除的所有 match 結果（顏色 → 方塊數）
  static TurnResult processMatches(
    BattleState battle,
    Map<BlockColor, int> matchedBlockCounts,
    int combo,
  ) {
    final damageByColor = <BlockColor, int>{};
    final energyGained = <String, int>{};
    int totalDamage = 0;

    final enemy = battle.currentEnemy;
    if (enemy == null || enemy.isDead) {
      return TurnResult(
        damageByColor: damageByColor,
        totalDamage: 0,
        energyGained: energyGained,
      );
    }

    // 計算每種顏色的傷害
    for (final entry in matchedBlockCounts.entries) {
      final color = entry.key;
      final count = entry.value;

      // 計算傷害
      var damage = battle.calculateMatchDamage(color, count);

      // Combo 加成（每 combo +10%）
      if (combo > 1) {
        damage = (damage * (1 + (combo - 1) * 0.1)).round();
      }

      if (damage > 0) {
        damageByColor[color] = damage;
        totalDamage += damage;
      }

      // 累積能量：消除的方塊數 → 對應屬性角色獲得能量
      for (final agent in battle.team) {
        if (agent.definition.attribute.blockColor == color) {
          // 消除自己屬性的方塊：每個 +1 能量
          final energy = count;
          agent.addEnergy(energy);
          energyGained[agent.definition.id] =
              (energyGained[agent.definition.id] ?? 0) + energy;
        }
      }
    }

    // 對敵人造成傷害
    if (totalDamage > 0) {
      enemy.takeDamage(totalDamage);
    }

    final killed = enemy.isDead;
    if (killed) {
      battle.advanceToNextEnemy();
    }

    return TurnResult(
      damageByColor: damageByColor,
      totalDamage: totalDamage,
      energyGained: energyGained,
      enemyKilled: killed,
    );
  }

  /// 處理敵人回擊
  static TurnResult processEnemyTurn(BattleState battle) {
    final enemy = battle.currentEnemy;
    if (enemy == null || enemy.isDead) {
      return const TurnResult(
        damageByColor: {},
        totalDamage: 0,
        energyGained: {},
      );
    }

    final shouldAttack = enemy.tickAttack();
    if (!shouldAttack) {
      return const TurnResult(
        damageByColor: {},
        totalDamage: 0,
        energyGained: {},
      );
    }

    final damage = battle.enemyAttack();
    return TurnResult(
      damageByColor: const {},
      totalDamage: 0,
      energyGained: const {},
      enemyAttacked: true,
      enemyDamage: damage,
    );
  }

  /// 施放技能
  static SkillResult activateSkill(
    BattleState battle,
    BattleAgent agent,
  ) {
    if (!agent.isSkillReady) {
      return const SkillResult(description: '能量不足');
    }

    final skill = agent.definition.skill;
    final multiplier = skill.multiplierAtLevel(agent.level);
    agent.useSkill();

    switch (skill.effectType) {
      case SkillEffectType.damage:
        // 單體傷害
        final enemy = battle.currentEnemy;
        if (enemy == null) {
          return const SkillResult(description: '無目標');
        }
        final attrMult = agent.definition.attribute
            .damageMultiplierAgainst(enemy.definition.attribute);
        final damage = (agent.atk * multiplier * attrMult).round();
        enemy.takeDamage(damage);
        if (enemy.isDead) battle.advanceToNextEnemy();
        return SkillResult(
          description: '${skill.name}！造成 $damage 傷害',
          damageDealt: damage,
        );

      case SkillEffectType.heal:
        // 回復
        final healAmount =
            (battle.teamMaxHp * multiplier / 100).round();
        battle.teamCurrentHp =
            (battle.teamCurrentHp + healAmount).clamp(0, battle.teamMaxHp);
        return SkillResult(
          description: '${skill.name}！回復 $healAmount HP',
          hpHealed: healAmount,
        );

      case SkillEffectType.shield:
        // 減傷護盾
        battle.shieldTurnsLeft = 2;
        battle.shieldReduction = multiplier;
        return SkillResult(
          description: '${skill.name}！減傷 ${multiplier.round()}%，持續 2 回合',
          shieldTurns: 2,
          shieldPercent: multiplier,
        );

      case SkillEffectType.aoe:
        // 全體傷害
        var totalDmg = 0;
        for (final enemy in battle.enemies) {
          if (!enemy.isDead) {
            final attrMult = agent.definition.attribute
                .damageMultiplierAgainst(enemy.definition.attribute);
            final damage = (agent.atk * multiplier * attrMult).round();
            enemy.takeDamage(damage);
            totalDmg += damage;
          }
        }
        battle.advanceToNextEnemy();
        return SkillResult(
          description: '${skill.name}！對全體造成 $totalDmg 傷害',
          damageDealt: totalDmg,
        );

      case SkillEffectType.execute:
        // 斬殺（低血額外傷害）
        final enemy = battle.currentEnemy;
        if (enemy == null) {
          return const SkillResult(description: '無目標');
        }
        final attrMult = agent.definition.attribute
            .damageMultiplierAgainst(enemy.definition.attribute);
        var damage = (agent.atk * multiplier * attrMult).round();
        if (enemy.hpPercent < 0.3) {
          damage = (damage * 1.5).round();
        }
        enemy.takeDamage(damage);
        if (enemy.isDead) battle.advanceToNextEnemy();
        return SkillResult(
          description: '${skill.name}！造成 $damage 傷害',
          damageDealt: damage,
        );

      case SkillEffectType.delay:
        // 延遲敵人攻擊
        final enemy = battle.currentEnemy;
        if (enemy != null) {
          enemy.attackCountdown += 2;
        }
        return SkillResult(
          description: '${skill.name}！敵人攻擊延遲 2 回合',
        );
    }
  }
}
