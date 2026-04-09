/// 戰鬥引擎
/// 處理傷害計算、技能效果、敵人回擊
import 'dart:math';
import '../../config/balance_config.dart';
import '../../config/battle_params.dart';
import '../../config/skill_tier_data.dart';
import '../models/battle_state.dart';
import '../models/cat_agent.dart';
import '../models/block.dart';
import '../models/enemy.dart';
import '../models/passive_skill.dart';
import '../models/skill_enhancement.dart';
import '../models/talent_tree.dart';

/// 技能效果結果
class SkillResult {
  final String description;
  final int damageDealt;
  final int hpHealed;
  final int shieldTurns;
  final double shieldPercent;
  final SkillBoardEffect? boardEffect; // 放置效果（需由 GameProvider 執行）
  final BlockColor? agentColor;       // 角色屬性對應的方塊顏色

  const SkillResult({
    required this.description,
    this.damageDealt = 0,
    this.hpHealed = 0,
    this.shieldTurns = 0,
    this.shieldPercent = 0,
    this.boardEffect,
    this.agentColor,
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
  final int healAmount; // 治療量
  final int counterDamage; // 反擊傷害

  const TurnResult({
    required this.damageByColor,
    required this.totalDamage,
    required this.energyGained,
    this.enemyKilled = false,
    this.enemyAttacked = false,
    this.enemyDamage = 0,
    this.healAmount = 0,
    this.counterDamage = 0,
  });
}

/// 自動攻擊事件（含 Balatro 風格傷害分解數據）
/// 角色累積傷害事件（連鎖中每次配對時觸發，用於頭像顯示）
class DamageAccumEvent {
  final String agentId;
  final int damage; // 本次累積的 base 傷害（未乘 combo）

  const DamageAccumEvent({required this.agentId, required this.damage});
}

/// 角色攻擊事件（回合結束統一打出）
class AutoAttackEvent {
  final bool isPlayerAttack;
  final String attackerId;
  final String? targetId;
  final int damage;         // 最終傷害（含 combo + 屬性）
  final bool killed;

  final int preComboDamage; // combo 前累積傷害
  final int combo;
  final double comboMult;
  final double attributeMult;

  const AutoAttackEvent({
    required this.isPlayerAttack,
    required this.attackerId,
    this.targetId,
    required this.damage,
    this.killed = false,
    this.preComboDamage = 0,
    this.combo = 0,
    this.comboMult = 1.0,
    this.attributeMult = 1.0,
  });
}

/// Tick 結算結果（每次連鎖呼叫一次）
class TickResult {
  final int tickNumber;
  final Map<String, int> energyGained;
  final List<DamageAccumEvent> accumEvents; // 角色累積傷害（頭像跳數字用）
  final int boardDamage;
  final int totalBlocksEliminated;
  final int healAmount;

  const TickResult({
    required this.tickNumber,
    required this.energyGained,
    required this.accumEvents,
    this.boardDamage = 0,
    this.totalBlocksEliminated = 0,
    this.healAmount = 0,
  });
}

/// 回合結束結算結果（所有連鎖完成後）
class FinalizeResult {
  final List<AutoAttackEvent> attacks;
  final int totalDamage;
  final bool anyEnemyKilled;

  const FinalizeResult({
    required this.attacks,
    this.totalDamage = 0,
    this.anyEnemyKilled = false,
  });
}

class BattleEngine {
  BattleEngine._();

  static final _random = Random();
  static BattleParams get _params => BalanceConfig.instance.battleParams;

  /// 處理一個 tick（連鎖消除）— 累積傷害，不打出
  /// 棋盤傷害即時生效，角色傷害累積到 pendingDamage
  static TickResult processTick(
    BattleState battle,
    Map<BlockColor, int> matchedBlockCounts,
    int combo,
  ) {
    battle.tickCount += 1;
    battle.lastCombo = combo;

    final energyGained = <String, int>{};
    final accumEvents = <DamageAccumEvent>[];
    int totalHeal = 0;

    // ── 1. 充能：消同色方塊 → 對應角色累積能量 ──
    for (final entry in matchedBlockCounts.entries) {
      final color = entry.key;
      final count = entry.value;

      for (final agent in battle.team) {
        if (agent.definition.attribute.blockColor == color) {
          var energy = count;

          final energyUp = agent.getTalentBonus(TalentEffectType.energyGainUp);
          if (energyUp > 0) {
            energy = (energy * (1 + energyUp / 100)).round();
          }

          final energyBonus = agent.getPassive(PassiveEffectType.energyBonus);
          if (energyBonus != null) {
            energy = (energy * (1 + energyBonus.effectValue)).round();
          }

          agent.addEnergy(energy);
          energyGained[agent.definition.id] =
              (energyGained[agent.definition.id] ?? 0) + energy;
        }
      }

      // 被動：消除治療
      for (final agent in battle.team) {
        final healOnMatch = agent.getPassive(PassiveEffectType.healOnMatch);
        if (healOnMatch != null &&
            agent.definition.attribute.blockColor == color) {
          final heal = (battle.teamMaxHp * healOnMatch.effectValue).round();
          battle.teamCurrentHp =
              (battle.teamCurrentHp + heal).clamp(0, battle.teamMaxHp);
          totalHeal += heal;
        }
      }
    }

    // ── 2a. 棋盤傷害：即時生效 ──
    final totalBlocks = matchedBlockCounts.values.fold<int>(0, (a, b) => a + b);
    int boardDamage = 0;

    final enemy = battle.currentEnemy;
    if (enemy != null && !enemy.isDead && totalBlocks > 0) {
      boardDamage = totalBlocks * _params.noAgentMatchDamage;
      enemy.takeDamage(boardDamage);
    }

    // ── 2b. 角色傷害：累積到 pendingDamage（不扣血） ──
    for (final agent in battle.team) {
      final agentColor = agent.definition.attribute.blockColor;
      final matchCount = matchedBlockCounts[agentColor] ?? 0;
      if (matchCount <= 0) continue;

      var baseDmg = battle.calculateAutoAttackDamage(agent, enemy!);
      var damage = baseDmg;

      // 配對顏色倍率
      damage = (damage * _params.colorMatchBonus).round();

      // 消除數量加成
      if (matchCount > 1) {
        damage = (damage * (1 + (matchCount - 1) * _params.matchDamageBonusPerBlock)).round();
      }

      // 累積（不套 combo，combo 在 finalize 時統一計算）
      final id = agent.definition.id;
      battle.pendingDamage[id] = (battle.pendingDamage[id] ?? 0) + damage;

      accumEvents.add(DamageAccumEvent(agentId: id, damage: damage));
    }

    return TickResult(
      tickNumber: battle.tickCount,
      energyGained: energyGained,
      accumEvents: accumEvents,
      boardDamage: boardDamage,
      totalBlocksEliminated: totalBlocks,
      healAmount: totalHeal,
    );
  }

  /// 回合結束：統一套 combo，計算最終傷害（不扣血，由 UI 在命中時扣）
  static FinalizeResult finalizeAttacks(BattleState battle) {
    final attacks = <AutoAttackEvent>[];

    if (battle.pendingDamage.isEmpty) {
      return const FinalizeResult(attacks: []);
    }

    // 計算 combo 倍率
    final combo = battle.lastCombo;
    double comboMult = 1.0;
    if (combo > 1) {
      comboMult = 1 + (combo - 1) * _params.comboBonusPerCombo;
      for (final a in battle.team) {
        final comboBonus = a.getTalentBonus(TalentEffectType.comboBonus);
        if (comboBonus > 0) {
          comboMult += comboBonus / 100;
          break;
        }
      }
    }

    for (final agent in battle.team) {
      final id = agent.definition.id;
      final preComboDmg = battle.pendingDamage[id];
      if (preComboDmg == null || preComboDmg <= 0) continue;

      final enemy = battle.currentEnemy;
      if (enemy == null || enemy.isDead) continue;

      final attrMult = agent.definition.attribute
          .damageMultiplierAgainst(enemy.definition.attribute);

      var finalDamage = (preComboDmg * comboMult).round();

      if (!battle.firstAttackDone) battle.firstAttackDone = true;

      attacks.add(AutoAttackEvent(
        isPlayerAttack: true,
        attackerId: id,
        targetId: enemy.definition.id,
        damage: finalDamage,
        killed: false, // UI 命中時判斷
        preComboDamage: preComboDmg,
        combo: combo,
        comboMult: comboMult,
        attributeMult: attrMult,
      ));
    }

    // 清空累積
    battle.pendingDamage.clear();

    return FinalizeResult(
      attacks: attacks,
      totalDamage: 0,
      anyEnemyKilled: false,
    );
  }

  /// UI 命中時呼叫：扣血 + 處理擊殺
  static bool applyHitDamage(BattleState battle, int damage) {
    final enemy = battle.currentEnemy;
    if (enemy == null || enemy.isDead) return false;

    enemy.takeDamage(damage);

    if (enemy.isDead) {
      _processKillEffects(battle);
      battle.advanceToNextEnemy();
      return true;
    }
    return false;
  }

  /// 處理敵方攻擊階段（整輪消除完成後呼叫一次）
  /// 所有存活敵人推進 countdown，到期的敵人發動攻擊
  static List<AutoAttackEvent> processEnemyPhase(BattleState battle) {
    final autoAttacks = <AutoAttackEvent>[];

    for (final enemy in battle.enemies) {
      if (enemy.isDead) continue;
      final shouldAttack = enemy.tickAttack();
      if (shouldAttack) {
        final damage = battle.enemyAttackFrom(enemy);

        autoAttacks.add(AutoAttackEvent(
          isPlayerAttack: false,
          attackerId: enemy.definition.id,
          damage: damage,
        ));

        // 被動：反擊
        for (final agent in battle.team) {
          final counter = agent.getPassive(PassiveEffectType.counterAttack);
          if (counter != null && !enemy.isDead) {
            if (_random.nextDouble() < counter.effectValue) {
              final counterDmg = (agent.atk * _params.counterDamageMultiplier).round();
              enemy.takeDamage(counterDmg);
              if (enemy.isDead) {
                _processKillEffects(battle);
                battle.advanceToNextEnemy();
              }
            }
          }
        }
      }
    }

    return autoAttacks;
  }

  /// 處理一次消除的傷害和能量（舊版回合制，保留向下相容）
  static TurnResult processMatches(
    BattleState battle,
    Map<BlockColor, int> matchedBlockCounts,
    int combo,
  ) {
    final damageByColor = <BlockColor, int>{};
    final energyGained = <String, int>{};
    int totalDamage = 0;
    int totalHeal = 0;

    battle.lastCombo = combo;

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

      // Combo 加成
      if (combo > 1) {
        double comboMult = 1 + (combo - 1) * _params.comboBonusPerCombo;

        // 天賦：連擊傷害加成
        for (final agent in battle.team) {
          final comboBonus = agent.getTalentBonus(TalentEffectType.comboBonus);
          if (comboBonus > 0) {
            comboMult += comboBonus / 100;
            break;
          }
        }

        damage = (damage * comboMult).round();
      }

      if (damage > 0) {
        damageByColor[color] = damage;
        totalDamage += damage;
      }

      // 累積能量
      for (final agent in battle.team) {
        if (agent.definition.attribute.blockColor == color) {
          var energy = count;

          // 天賦：能量獲取加成
          final energyUp = agent.getTalentBonus(TalentEffectType.energyGainUp);
          if (energyUp > 0) {
            energy = (energy * (1 + energyUp / 100)).round();
          }

          // 被動：特定顏色能量加成
          final energyBonus = agent.getPassive(PassiveEffectType.energyBonus);
          if (energyBonus != null) {
            energy = (energy * (1 + energyBonus.effectValue)).round();
          }

          agent.addEnergy(energy);
          energyGained[agent.definition.id] =
              (energyGained[agent.definition.id] ?? 0) + energy;
        }
      }

      // 被動：消除治療
      for (final agent in battle.team) {
        final healOnMatch = agent.getPassive(PassiveEffectType.healOnMatch);
        if (healOnMatch != null &&
            agent.definition.attribute.blockColor == color) {
          final heal = (battle.teamMaxHp * healOnMatch.effectValue).round();
          battle.teamCurrentHp =
              (battle.teamCurrentHp + heal).clamp(0, battle.teamMaxHp);
          totalHeal += heal;
        }
      }
    }

    // 標記首次攻擊已完成
    if (totalDamage > 0) {
      battle.firstAttackDone = true;
    }

    // 對敵人造成傷害
    if (totalDamage > 0) {
      enemy.takeDamage(totalDamage);
    }

    final killed = enemy.isDead;
    if (killed) {
      // 被動：擊殺效果
      _processKillEffects(battle);
      battle.advanceToNextEnemy();
    }

    return TurnResult(
      damageByColor: damageByColor,
      totalDamage: totalDamage,
      energyGained: energyGained,
      enemyKilled: killed,
      healAmount: totalHeal,
    );
  }

  /// 處理擊殺效果
  static void _processKillEffects(BattleState battle) {
    for (final agent in battle.team) {
      final onKill = agent.getPassive(PassiveEffectType.onKillEffect);
      if (onKill != null) {
        if (agent.definition.id == 'shadow') {
          // 暗影：退還 30% 能量
          final refund = (agent.maxEnergy * onKill.effectValue).round();
          agent.addEnergy(refund);
        } else {
          // 閃光/其他：固定獲得能量
          agent.addEnergy(onKill.effectValue.round());
        }
      }
    }
  }

  /// 處理回合開始效果（DoT、HoT、被動觸發）
  static TurnResult processTurnStart(BattleState battle) {
    int totalDamage = 0;
    int totalHeal = 0;

    // 被動：每回合治療
    for (final agent in battle.team) {
      final turnHeal = agent.getPassive(PassiveEffectType.turnStartHeal);
      if (turnHeal != null) {
        final heal = (battle.teamMaxHp * turnHeal.effectValue).round();
        battle.teamCurrentHp =
            (battle.teamCurrentHp + heal).clamp(0, battle.teamMaxHp);
        totalHeal += heal;
      }
    }

    // HoT（技能強化效果）
    if (battle.hotTurnsLeft > 0) {
      final heal = (battle.teamMaxHp * battle.hotPercent).round();
      battle.teamCurrentHp =
          (battle.teamCurrentHp + heal).clamp(0, battle.teamMaxHp);
      totalHeal += heal;
      battle.hotTurnsLeft--;
    }

    // DoT 對敵人造成傷害
    final enemy = battle.currentEnemy;
    if (enemy != null && !enemy.isDead) {
      final dotsToRemove = <DotEffect>[];
      for (final dot in battle.activeDots) {
        enemy.takeDamage(dot.damagePerTurn);
        totalDamage += dot.damagePerTurn;
        dot.turnsRemaining--;
        if (dot.turnsRemaining <= 0) {
          dotsToRemove.add(dot);
        }
      }
      battle.activeDots.removeWhere((d) => dotsToRemove.contains(d));

      if (enemy.isDead) {
        _processKillEffects(battle);
        battle.advanceToNextEnemy();
      }
    }

    // 破防回合遞減
    if (battle.defDebuffTurns > 0) {
      battle.defDebuffTurns--;
      if (battle.defDebuffTurns <= 0) {
        battle.defDebuffPercent = 0;
      }
    }

    // 反射回合遞減
    if (battle.reflectTurnsLeft > 0) {
      battle.reflectTurnsLeft--;
      if (battle.reflectTurnsLeft <= 0) {
        battle.reflectPercent = 0;
      }
    }

    // 被動：低血量增傷（阿焰）
    // 不需要在這裡處理，因為傷害計算時動態判斷

    return TurnResult(
      damageByColor: const {},
      totalDamage: totalDamage,
      energyGained: const {},
      healAmount: totalHeal,
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

    // 被動：反擊（大地）
    int counterDmg = 0;
    for (final agent in battle.team) {
      final counter = agent.getPassive(PassiveEffectType.counterAttack);
      if (counter != null && !enemy.isDead) {
        if (_random.nextDouble() < counter.effectValue) {
          counterDmg = (agent.atk * 0.5).round();
          enemy.takeDamage(counterDmg);
          if (enemy.isDead) {
            _processKillEffects(battle);
            battle.advanceToNextEnemy();
          }
        }
      }
    }

    return TurnResult(
      damageByColor: const {},
      totalDamage: 0,
      energyGained: const {},
      enemyAttacked: true,
      enemyDamage: damage,
      counterDamage: counterDmg,
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
    var multiplier = skill.multiplierAtLevel(agent.level);

    // 技能強化：累計倍率加成
    final tierBonus = SkillTierData.getCumulativeMultiplierBonus(
      agent.definition.id,
      agent.skillTier,
    );
    multiplier += tierBonus;

    // 天賦：技能傷害加成
    final skillDmgUp = agent.getTalentBonus(TalentEffectType.skillDamageUp);

    // 被動：連擊技能加成
    double passiveSkillMult = 1.0;
    for (final a in battle.team) {
      final comboSkill = a.getPassive(PassiveEffectType.comboSkillBonus);
      if (comboSkill != null) {
        // 阿焰: 3+ combo, 閃光: 5+ combo
        final threshold = a.definition.id == 'flash' ? 5 : 3;
        if (battle.lastCombo >= threshold) {
          passiveSkillMult += comboSkill.effectValue;
        }
      }
    }

    // 被動：低血量增傷
    final lowHp = agent.getPassive(PassiveEffectType.lowHpBoost);
    if (lowHp != null && battle.teamCurrentHp < battle.teamMaxHp * _params.lowHpThreshold) {
      passiveSkillMult += lowHp.effectValue;
    }

    agent.useSkill();

    // 取得當前階級的機制列表
    final activeMechanics = SkillTierData.getActiveMechanics(
      agent.definition.id,
      agent.skillTier,
    );

    // 放置效果（所有技能共用）
    final boardEffect = skill.boardEffect;
    final agentColor = agent.definition.attribute.blockColor;

    SkillResult result;

    switch (skill.effectType) {
      case SkillEffectType.damage:
        result = _processDamageSkill(battle, agent, multiplier, skillDmgUp, passiveSkillMult, activeMechanics);
        break;

      case SkillEffectType.heal:
        result = _processHealSkill(battle, agent, multiplier, activeMechanics);
        break;

      case SkillEffectType.shield:
        result = _processShieldSkill(battle, agent, multiplier, activeMechanics);
        break;

      case SkillEffectType.aoe:
        result = _processAoeSkill(battle, agent, multiplier, skillDmgUp, passiveSkillMult, activeMechanics);
        break;

      case SkillEffectType.execute:
        result = _processExecuteSkill(battle, agent, multiplier, skillDmgUp, passiveSkillMult, activeMechanics);
        break;

      case SkillEffectType.delay:
        final enemy = battle.currentEnemy;
        if (enemy != null) {
          enemy.attackCountdown += _params.delaySkillTurns;
        }
        result = SkillResult(
          description: '${skill.name}！敵人攻擊延遲 ${_params.delaySkillTurns} 回合',
        );
        break;
    }

    // 附加放置效果資訊到結果
    if (boardEffect != null) {
      final boardDesc = '｜${boardEffect.description}';
      return SkillResult(
        description: '${result.description}$boardDesc',
        damageDealt: result.damageDealt,
        hpHealed: result.hpHealed,
        shieldTurns: result.shieldTurns,
        shieldPercent: result.shieldPercent,
        boardEffect: boardEffect,
        agentColor: agentColor,
      );
    }

    return result;
  }

  static SkillResult _processDamageSkill(
    BattleState battle,
    BattleAgent agent,
    double multiplier,
    double skillDmgUp,
    double passiveSkillMult,
    List<SkillTierDefinition> mechanics,
  ) {
    final enemy = battle.currentEnemy;
    if (enemy == null) return const SkillResult(description: '無目標');

    final attrMult = agent.definition.attribute
        .damageMultiplierAgainst(enemy.definition.attribute);
    var damage = (agent.atk * multiplier * attrMult).round();

    // 天賦技能傷害加成
    if (skillDmgUp > 0) damage = (damage * (1 + skillDmgUp / 100)).round();
    // 被動加成
    damage = (damage * passiveSkillMult).round();
    // 破防
    if (battle.defDebuffTurns > 0) {
      damage = (damage * (1 + battle.defDebuffPercent)).round();
    }

    enemy.takeDamage(damage);

    // 技能強化機制
    for (final mech in mechanics) {
      switch (mech.newMechanic) {
        case SkillTierMechanic.dot:
          battle.activeDots.add(DotEffect(
            damagePerTurn: (agent.atk * mech.mechanicValue).round(),
            turnsRemaining: _params.dotDefaultDuration,
          ));
          break;
        case SkillTierMechanic.aoeSplash:
          for (final e in battle.enemies) {
            if (!e.isDead && e != enemy) {
              e.takeDamage((damage * mech.mechanicValue).round());
            }
          }
          break;
        case SkillTierMechanic.defBreak:
          battle.defDebuffTurns = _params.defBreakDefaultDuration;
          battle.defDebuffPercent = mech.mechanicValue;
          break;
        default:
          break;
      }
    }

    if (enemy.isDead) {
      _processKillEffects(battle);
      battle.advanceToNextEnemy();
    }

    // 被動：放技能後獲得護盾
    _applyShieldOnSkill(battle, agent);

    return SkillResult(
      description: '${agent.definition.skill.name}！造成 $damage 傷害',
      damageDealt: damage,
    );
  }

  static SkillResult _processHealSkill(
    BattleState battle,
    BattleAgent agent,
    double multiplier,
    List<SkillTierDefinition> mechanics,
  ) {
    // 天賦：治療效果加成
    final healBoost = agent.getTalentBonus(TalentEffectType.healBoost);
    final effectiveMult = multiplier * (1 + healBoost / 100);

    final healAmount = (battle.teamMaxHp * effectiveMult / 100).round();
    battle.teamCurrentHp =
        (battle.teamCurrentHp + healAmount).clamp(0, battle.teamMaxHp);

    // 技能強化機制
    for (final mech in mechanics) {
      switch (mech.newMechanic) {
        case SkillTierMechanic.delayAdded:
          final enemy = battle.currentEnemy;
          if (enemy != null) {
            enemy.attackCountdown += mech.mechanicValue.round();
          }
          break;
        case SkillTierMechanic.durationExtend:
          // HoT
          battle.hotTurnsLeft = _params.dotDefaultDuration;
          battle.hotPercent = mech.mechanicValue;
          break;
        case SkillTierMechanic.energyRefund:
          agent.addEnergy(mech.mechanicValue.round());
          break;
        default:
          break;
      }
    }

    _applyShieldOnSkill(battle, agent);

    return SkillResult(
      description: '${agent.definition.skill.name}！回復 $healAmount HP',
      hpHealed: healAmount,
    );
  }

  static SkillResult _processShieldSkill(
    BattleState battle,
    BattleAgent agent,
    double multiplier,
    List<SkillTierDefinition> mechanics,
  ) {
    // 天賦：護盾效果加成
    final shieldBoost = agent.getTalentBonus(TalentEffectType.shieldBoost);
    final effectiveMult = multiplier * (1 + shieldBoost / 100);

    int shieldDuration = _params.shieldDefaultDuration;

    // 技能強化機制
    for (final mech in mechanics) {
      switch (mech.newMechanic) {
        case SkillTierMechanic.durationExtend:
          shieldDuration += mech.mechanicValue.round();
          break;
        case SkillTierMechanic.reflect:
          battle.reflectPercent = mech.mechanicValue;
          battle.reflectTurnsLeft = shieldDuration;
          break;
        case SkillTierMechanic.dot:
          // 荊棘（受擊反擊，在 enemyAttack 中處理）
          // 這裡用 reflectPercent 模擬
          battle.reflectPercent = mech.mechanicValue;
          battle.reflectTurnsLeft = shieldDuration;
          break;
        default:
          break;
      }
    }

    battle.shieldTurnsLeft = shieldDuration;
    battle.shieldReduction = effectiveMult;

    return SkillResult(
      description: '${agent.definition.skill.name}！減傷 ${effectiveMult.round()}%，持續 $shieldDuration 回合',
      shieldTurns: shieldDuration,
      shieldPercent: effectiveMult,
    );
  }

  static SkillResult _processAoeSkill(
    BattleState battle,
    BattleAgent agent,
    double multiplier,
    double skillDmgUp,
    double passiveSkillMult,
    List<SkillTierDefinition> mechanics,
  ) {
    var totalDmg = 0;
    bool anyKilled = false;

    for (final enemy in battle.enemies) {
      if (!enemy.isDead) {
        final attrMult = agent.definition.attribute
            .damageMultiplierAgainst(enemy.definition.attribute);
        var damage = (agent.atk * multiplier * attrMult).round();

        if (skillDmgUp > 0) damage = (damage * (1 + skillDmgUp / 100)).round();
        damage = (damage * passiveSkillMult).round();
        if (battle.defDebuffTurns > 0) {
          damage = (damage * (1 + battle.defDebuffPercent)).round();
        }

        enemy.takeDamage(damage);
        totalDmg += damage;
        if (enemy.isDead) anyKilled = true;
      }
    }

    // 技能強化機制
    for (final mech in mechanics) {
      switch (mech.newMechanic) {
        case SkillTierMechanic.defBreak:
          battle.defDebuffTurns = _params.defBreakDefaultDuration;
          battle.defDebuffPercent = mech.mechanicValue;
          break;
        case SkillTierMechanic.aoeSplash:
          // 連鎖閃電：隨機追擊
          final alive = battle.enemies.where((e) => !e.isDead).toList();
          if (alive.isNotEmpty) {
            final target = alive[_random.nextInt(alive.length)];
            final extraDmg = (agent.atk * mech.mechanicValue).round();
            target.takeDamage(extraDmg);
            totalDmg += extraDmg;
            if (target.isDead) anyKilled = true;
          }
          break;
        case SkillTierMechanic.energyRefund:
          if (anyKilled) {
            agent.addEnergy(mech.mechanicValue.round());
          }
          break;
        default:
          break;
      }
    }

    if (anyKilled) {
      _processKillEffects(battle);
    }
    battle.advanceToNextEnemy();

    _applyShieldOnSkill(battle, agent);

    return SkillResult(
      description: '${agent.definition.skill.name}！對全體造成 $totalDmg 傷害',
      damageDealt: totalDmg,
    );
  }

  static SkillResult _processExecuteSkill(
    BattleState battle,
    BattleAgent agent,
    double multiplier,
    double skillDmgUp,
    double passiveSkillMult,
    List<SkillTierDefinition> mechanics,
  ) {
    final enemy = battle.currentEnemy;
    if (enemy == null) return const SkillResult(description: '無目標');

    final attrMult = agent.definition.attribute
        .damageMultiplierAgainst(enemy.definition.attribute);
    var damage = (agent.atk * multiplier * attrMult).round();

    if (skillDmgUp > 0) damage = (damage * (1 + skillDmgUp / 100)).round();
    damage = (damage * passiveSkillMult).round();
    if (battle.defDebuffTurns > 0) {
      damage = (damage * (1 + battle.defDebuffPercent)).round();
    }

    // 斬殺門檻
    double executeThreshold = _params.executeThresholdBase;

    // 技能強化：門檻提升
    for (final mech in mechanics) {
      if (mech.newMechanic == SkillTierMechanic.executeThresholdUp) {
        executeThreshold = mech.mechanicValue;
      }
    }

    // 被動：門檻提升
    final thresholdPassive = agent.getPassive(PassiveEffectType.executeThresholdUp);
    if (thresholdPassive != null) {
      executeThreshold += thresholdPassive.effectValue;
    }

    if (enemy.hpPercent < executeThreshold) {
      damage = (damage * _params.executeBonusMultiplier).round();
    }

    enemy.takeDamage(damage);

    // 技能強化：DoT
    for (final mech in mechanics) {
      if (mech.newMechanic == SkillTierMechanic.dot) {
        battle.activeDots.add(DotEffect(
          damagePerTurn: (agent.atk * mech.mechanicValue).round(),
          turnsRemaining: _params.dotDefaultDuration,
        ));
      }
    }

    // 技能強化：擊殺退能量
    if (enemy.isDead) {
      for (final mech in mechanics) {
        if (mech.newMechanic == SkillTierMechanic.energyRefund) {
          if (mech.mechanicValue < 0) {
            // -1 表示全額退還
            agent.addEnergy(agent.maxEnergy);
          } else {
            agent.addEnergy(mech.mechanicValue.round());
          }
        }
      }
      _processKillEffects(battle);
      battle.advanceToNextEnemy();
    }

    _applyShieldOnSkill(battle, agent);

    return SkillResult(
      description: '${agent.definition.skill.name}！造成 $damage 傷害',
      damageDealt: damage,
    );
  }

  /// 被動：放技能後獲得護盾
  static void _applyShieldOnSkill(BattleState battle, BattleAgent agent) {
    for (final a in battle.team) {
      final shieldPassive = a.getPassive(PassiveEffectType.shieldOnSkill);
      if (shieldPassive != null && a == agent) {
        // 獲得護盾（如果沒有更強的護盾）
        if (battle.shieldTurnsLeft <= 0) {
          battle.shieldTurnsLeft = 1;
          battle.shieldReduction = shieldPassive.effectValue * 100;
        }
      }
    }
  }

  // ═══════════════════════════════════════════════
  //  敵人技能系統
  // ═══════════════════════════════════════════════

  /// 敵人技能階段結果
  static EnemySkillPhaseResult processEnemySkillPhase(
    BattleState battle,
    int boardCols,
    int boardRows,
  ) {
    final events = <EnemySkillEvent>[];

    for (final enemy in battle.enemies) {
      if (enemy.isDead) continue;

      // 推進冷卻計時器
      final triggered = enemy.skillState.tickCooldowns();

      for (final type in triggered) {
        final skill = enemy.getSkill(type);
        if (skill == null) continue;

        switch (type) {
          case EnemySkillType.obstacle:
            final positions = _pickRandomEmptyPositions(
              battle, boardCols, boardRows, skill.blockCount,
            );
            for (final pos in positions) {
              battle.obstacleBlocks.add(
                ObstacleBlock(col: pos.$1, row: pos.$2),
              );
            }
            enemy.skillState.resetCooldown(type, skill.cooldown);
            if (positions.isNotEmpty) {
              events.add(EnemySkillEvent(
                enemyId: enemy.definition.id,
                type: type,
                positions: positions,
              ));
            }
            break;

          case EnemySkillType.poison:
            final positions = _pickRandomEmptyPositions(
              battle, boardCols, boardRows, skill.blockCount,
            );
            for (final pos in positions) {
              battle.poisonBlocks.add(
                PoisonBlock(col: pos.$1, row: pos.$2, countdown: skill.poisonCountdown),
              );
            }
            enemy.skillState.resetCooldown(type, skill.cooldown);
            if (positions.isNotEmpty) {
              events.add(EnemySkillEvent(
                enemyId: enemy.definition.id,
                type: type,
                positions: positions,
                countdown: skill.poisonCountdown,
              ));
            }
            break;

          case EnemySkillType.weaken:
            final positions = _pickRandomEmptyPositions(
              battle, boardCols, boardRows, skill.blockCount,
            );
            for (final pos in positions) {
              battle.weakenedBlocks.add(
                WeakenedBlock(col: pos.$1, row: pos.$2),
              );
            }
            enemy.skillState.resetCooldown(type, skill.cooldown);
            if (positions.isNotEmpty) {
              events.add(EnemySkillEvent(
                enemyId: enemy.definition.id,
                type: type,
                positions: positions,
              ));
            }
            break;

          case EnemySkillType.heal:
            enemy.applyHeal(skill.healPercent);
            enemy.skillState.resetCooldown(type, skill.healCooldown);
            events.add(EnemySkillEvent(
              enemyId: enemy.definition.id,
              type: type,
              healAmount: (enemy.maxHp * skill.healPercent).round(),
            ));
            break;

          case EnemySkillType.summon:
            if (skill.summonEnemy != null) {
              // 使用同章難度倍率（從現有敵人推算）
              final hpMult = enemy.maxHp / enemy.definition.baseHp;
              final atkMult = enemy.atk / enemy.definition.baseAtk;
              final summoned = EnemyInstance.fromDefinition(
                skill.summonEnemy!,
                hpMultiplier: hpMult,
                atkMultiplier: atkMult,
              );
              battle.enemies.add(summoned);
              enemy.skillState.resetCooldown(type, skill.summonCooldown);
              events.add(EnemySkillEvent(
                enemyId: enemy.definition.id,
                type: type,
                summonedEnemyName: skill.summonEnemy!.name,
              ));
            }
            break;

          default:
            break;
        }
      }

      // 蓄力判定（不走冷卻，跟隨攻擊節奏）
      if (enemy.hasSkill(EnemySkillType.charge) && !enemy.skillState.isCharging) {
        // 在攻擊倒數 == 2 時開始蓄力（下一回合攻擊）
        if (enemy.attackCountdown == 2) {
          enemy.skillState.isCharging = true;
          events.add(EnemySkillEvent(
            enemyId: enemy.definition.id,
            type: EnemySkillType.charge,
          ));
        }
      }
    }

    // 毒格倒數
    final expiredPoisons = <PoisonBlock>[];
    int totalPoisonDamage = 0;
    for (final poison in battle.poisonBlocks) {
      poison.countdown--;
      if (poison.isExpired) {
        expiredPoisons.add(poison);
        // 用場上最強存活敵人的 ATK 計算毒爆傷害
        final strongestAtk = battle.enemies
            .where((e) => !e.isDead)
            .fold<int>(0, (max, e) => e.atk > max ? e.atk : max);
        final poisonDmg = (strongestAtk * 0.5).round();
        totalPoisonDamage += poisonDmg;
      }
    }
    if (totalPoisonDamage > 0) {
      battle.teamCurrentHp = (battle.teamCurrentHp - totalPoisonDamage).clamp(0, battle.teamMaxHp);
      final expiredPositions = expiredPoisons.map((p) => (p.col, p.row)).toList();
      events.add(EnemySkillEvent(
        enemyId: 'poison_explode',
        type: EnemySkillType.poison,
        poisonDamage: totalPoisonDamage,
        positions: expiredPositions,
      ));
    }
    battle.poisonBlocks.removeWhere((p) => p.isExpired);

    // 弱化格回合遞減
    for (final w in battle.weakenedBlocks) {
      w.turnsLeft--;
    }
    battle.weakenedBlocks.removeWhere((w) => w.isExpired);

    return EnemySkillPhaseResult(events: events);
  }

  /// 處理消除時的棋盤技能互動
  /// 回傳被清除的障礙格和毒格位置
  static BoardSkillInteraction processMatchBoardSkills(
    BattleState battle,
    List<(int, int)> matchedPositions,
  ) {
    final clearedObstacles = <(int, int)>[];
    final clearedPoisons = <(int, int)>[];
    final clearedWeakened = <(int, int)>[];
    int weakenedInMatch = 0;

    // 檢查消除的格子是否包含毒格（安全消除）
    for (final pos in matchedPositions) {
      final poison = battle.getPoisonAt(pos.$1, pos.$2);
      if (poison != null) {
        clearedPoisons.add(pos);
        battle.poisonBlocks.remove(poison);
      }

      // 檢查弱化
      if (battle.isWeakened(pos.$1, pos.$2)) {
        weakenedInMatch++;
        clearedWeakened.add(pos);
        battle.weakenedBlocks.removeWhere(
          (w) => w.col == pos.$1 && w.row == pos.$2,
        );
      }
    }

    // 相鄰消除對障礙格的影響
    final adjacentSet = <String>{};
    for (final pos in matchedPositions) {
      adjacentSet.add('${pos.$1},${pos.$2}');
    }

    for (final obstacle in battle.obstacleBlocks.toList()) {
      if (obstacle.isBroken) continue;

      // 檢查是否有相鄰格被消除
      final neighbors = [
        (obstacle.col - 1, obstacle.row),
        (obstacle.col + 1, obstacle.row),
        (obstacle.col, obstacle.row - 1),
        (obstacle.col, obstacle.row + 1),
      ];
      for (final n in neighbors) {
        if (adjacentSet.contains('${n.$1},${n.$2}')) {
          obstacle.hitCount++;
          break; // 每次消除最多 +1
        }
      }

      if (obstacle.isBroken) {
        clearedObstacles.add((obstacle.col, obstacle.row));
      }
    }
    battle.obstacleBlocks.removeWhere((o) => o.isBroken);

    return BoardSkillInteraction(
      clearedObstacles: clearedObstacles,
      clearedPoisons: clearedPoisons,
      clearedWeakened: clearedWeakened,
      weakenedInMatch: weakenedInMatch,
    );
  }

  /// 技能消除（角色技能的消除效果）直接清除障礙/毒/弱化格
  static List<(int, int)> clearBoardSkillsBySkillEliminate(
    BattleState battle,
    List<(int, int)> eliminatedPositions,
  ) {
    final cleared = <(int, int)>[];

    for (final pos in eliminatedPositions) {
      // 清障礙
      final obstacleIdx = battle.obstacleBlocks.indexWhere(
        (o) => o.col == pos.$1 && o.row == pos.$2,
      );
      if (obstacleIdx >= 0) {
        battle.obstacleBlocks.removeAt(obstacleIdx);
        cleared.add(pos);
      }

      // 清毒格
      final poisonIdx = battle.poisonBlocks.indexWhere(
        (p) => p.col == pos.$1 && p.row == pos.$2,
      );
      if (poisonIdx >= 0) {
        battle.poisonBlocks.removeAt(poisonIdx);
        cleared.add(pos);
      }

      // 清弱化
      final weakenIdx = battle.weakenedBlocks.indexWhere(
        (w) => w.col == pos.$1 && w.row == pos.$2,
      );
      if (weakenIdx >= 0) {
        battle.weakenedBlocks.removeAt(weakenIdx);
        cleared.add(pos);
      }
    }

    return cleared;
  }

  /// 轉色技能清除弱化和毒格（轉色覆蓋）
  static List<(int, int)> clearBoardSkillsByConvert(
    BattleState battle,
    List<(int, int)> convertedPositions,
  ) {
    final cleared = <(int, int)>[];

    for (final pos in convertedPositions) {
      // 轉色清弱化
      final weakenIdx = battle.weakenedBlocks.indexWhere(
        (w) => w.col == pos.$1 && w.row == pos.$2,
      );
      if (weakenIdx >= 0) {
        battle.weakenedBlocks.removeAt(weakenIdx);
        cleared.add(pos);
      }

      // 轉色清毒格
      final poisonIdx = battle.poisonBlocks.indexWhere(
        (p) => p.col == pos.$1 && p.row == pos.$2,
      );
      if (poisonIdx >= 0) {
        battle.poisonBlocks.removeAt(poisonIdx);
        cleared.add(pos);
      }
    }

    return cleared;
  }

  /// 在棋盤上隨機挑選空位（避開已有障礙/毒/弱化的位置）
  static List<(int, int)> _pickRandomEmptyPositions(
    BattleState battle,
    int cols,
    int rows,
    int count,
  ) {
    final occupied = <String>{};
    for (final o in battle.obstacleBlocks) {
      occupied.add('${o.col},${o.row}');
    }
    for (final p in battle.poisonBlocks) {
      occupied.add('${p.col},${p.row}');
    }
    for (final w in battle.weakenedBlocks) {
      occupied.add('${w.col},${w.row}');
    }

    final candidates = <(int, int)>[];
    for (int c = 0; c < cols; c++) {
      for (int r = 0; r < rows; r++) {
        if (!occupied.contains('$c,$r')) {
          candidates.add((c, r));
        }
      }
    }

    candidates.shuffle(_random);
    return candidates.take(count).toList();
  }
}

// ─── 敵人技能事件（供 UI 使用）───

class EnemySkillEvent {
  final String enemyId;
  final EnemySkillType type;
  final List<(int, int)> positions;
  final int? countdown;
  final int? healAmount;
  final int? poisonDamage;
  final String? summonedEnemyName;

  const EnemySkillEvent({
    required this.enemyId,
    required this.type,
    this.positions = const [],
    this.countdown,
    this.healAmount,
    this.poisonDamage,
    this.summonedEnemyName,
  });
}

class EnemySkillPhaseResult {
  final List<EnemySkillEvent> events;
  const EnemySkillPhaseResult({required this.events});
  bool get hasEvents => events.isNotEmpty;
}

class BoardSkillInteraction {
  final List<(int, int)> clearedObstacles;
  final List<(int, int)> clearedPoisons;
  final List<(int, int)> clearedWeakened;
  final int weakenedInMatch;

  const BoardSkillInteraction({
    this.clearedObstacles = const [],
    this.clearedPoisons = const [],
    this.clearedWeakened = const [],
    this.weakenedInMatch = 0,
  });

  bool get hadInteraction =>
      clearedObstacles.isNotEmpty ||
      clearedPoisons.isNotEmpty ||
      clearedWeakened.isNotEmpty;
}
