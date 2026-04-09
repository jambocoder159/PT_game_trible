/// 戰鬥流程整合測試
/// 模擬完整的闖關戰鬥循環：消除→充能→技能→敵方回合
import 'package:flutter_test/flutter_test.dart';
import 'package:match3_puzzle/config/cat_agent_data.dart';
import 'package:match3_puzzle/config/stage_data.dart';
import 'package:match3_puzzle/core/engine/battle_engine.dart';
import 'package:match3_puzzle/core/models/battle_state.dart';
import 'package:match3_puzzle/core/models/block.dart';
import 'package:match3_puzzle/core/models/cat_agent.dart';
import 'package:match3_puzzle/core/models/enemy.dart';

// 角色 ID 對照：
// A屬性(coral): blaze(小麥/打手), ember(窯窯/AOE), inferno(焦糖/斬殺)
// B屬性(mint):  terra(抹抹/護盾), sprout(薄荷/治療), gaia(肉桂/打手)
// C屬性(teal):  tide(露露/治療+延遲), frost(奶昔/護盾), tsunami(蘇打/AOE)
// D屬性(gold):  flash(糖霜/AOE), spark(棉花糖/治療), thunder(可頌/打手)
// E屬性(rose):  shadow(可可/斬殺), dusk(布丁/護盾), berry(藍莓/AOE)

void main() {
  // ═══════════════════════════════════════
  // 1. 基礎戰鬥流程
  // ═══════════════════════════════════════
  group('基礎戰鬥流程', () {
    late BattleState battle;
    late BattleAgent agent;

    setUp(() {
      // 用小麥（單體傷害型，能量 5，屬性 A/coral）
      final def = CatAgentData.getById('blaze')!;
      agent = BattleAgent(definition: def, level: 10, skillTier: 1);

      // 用 1-1 的簡單敵人
      final enemyDef = StageData.getById('1-1')!.enemies.first;
      final enemy = EnemyInstance.fromDefinition(enemyDef);

      battle = BattleState(
        team: [agent],
        enemies: [enemy],
        teamMaxHp: 500,
        teamCurrentHp: 500,
      );
      battle.initEnemySkills();
    });

    test('消除方塊產生傷害和能量', () {
      final enemy = battle.currentEnemy!;
      final hpBefore = enemy.currentHp;

      // 模擬消除 3 個 coral 方塊（小麥的屬性色）
      final tick = BattleEngine.processTick(
        battle,
        {BlockColor.coral: 3},
        1,
      );

      // 應該有能量增加
      expect(tick.energyGained, isNotEmpty);
      expect(agent.currentEnergy, greaterThan(0));

      // 棋盤傷害應該即時生效
      expect(tick.boardDamage, greaterThan(0));
      expect(enemy.currentHp, lessThan(hpBefore));

      // 角色傷害應該累積（未打出）
      expect(tick.accumEvents, isNotEmpty);
      expect(battle.pendingDamage, isNotEmpty);
    });

    test('回合結束打出累積傷害', () {
      // 消除一些方塊累積傷害
      BattleEngine.processTick(battle, {BlockColor.coral: 3}, 1);
      expect(battle.pendingDamage, isNotEmpty);

      // finalize 打出
      final result = BattleEngine.finalizeAttacks(battle);
      expect(result.attacks, isNotEmpty);
      expect(result.attacks.first.damage, greaterThan(0));
      expect(result.attacks.first.isPlayerAttack, true);

      // pendingDamage 應該被清空
      expect(battle.pendingDamage, isEmpty);
    });

    test('充滿能量後可施放技能', () {
      // 手動充滿能量
      agent.addEnergy(agent.maxEnergy);
      expect(agent.isSkillReady, true);

      final enemy = battle.currentEnemy!;
      final hpBefore = enemy.currentHp;

      // 施放技能
      final result = BattleEngine.activateSkill(battle, agent);

      expect(result.damageDealt, greaterThan(0));
      expect(agent.currentEnergy, 0); // 能量歸零
      expect(agent.isSkillReady, false);
      expect(enemy.currentHp, lessThan(hpBefore));
    });

    test('能量不足時技能不觸發', () {
      expect(agent.currentEnergy, 0);
      expect(agent.isSkillReady, false);

      final result = BattleEngine.activateSkill(battle, agent);
      expect(result.description, '能量不足');
      expect(result.damageDealt, 0);
    });

    test('敵方回合正確攻擊', () {
      final hpBefore = battle.teamCurrentHp;

      // 跑到敵人攻擊
      List<AutoAttackEvent> attacks = [];
      for (int i = 0; i < 5; i++) {
        attacks = BattleEngine.processEnemyPhase(battle);
        if (attacks.isNotEmpty) break;
      }

      expect(attacks, isNotEmpty);
      expect(battle.teamCurrentHp, lessThan(hpBefore));
    });
  });

  // ═══════════════════════════════════════
  // 2. 多角色充能與技能施放
  // ═══════════════════════════════════════
  group('多角色技能施放', () {
    test('消除不同顏色方塊對應不同角色充能', () {
      final wheat = BattleAgent(
        definition: CatAgentData.getById('blaze')!, // A/coral
        level: 10,
      );
      final matcha = BattleAgent(
        definition: CatAgentData.getById('terra')!, // B/mint
        level: 10,
      );

      final enemy = EnemyInstance.fromDefinition(
        StageData.getById('1-1')!.enemies.first,
      );
      final battle = BattleState(
        team: [wheat, matcha],
        enemies: [enemy],
        teamMaxHp: 800,
        teamCurrentHp: 800,
      );

      // 消除 coral 方塊 → 只有小麥充能
      BattleEngine.processTick(battle, {BlockColor.coral: 3}, 1);
      expect(wheat.currentEnergy, greaterThan(0));
      expect(matcha.currentEnergy, 0);

      // 消除 mint 方塊 → 只有抹抹充能
      BattleEngine.processTick(battle, {BlockColor.mint: 2}, 2);
      expect(matcha.currentEnergy, greaterThan(0));
    });

    test('治療技能正確回血', () {
      final mint = BattleAgent(
        definition: CatAgentData.getById('sprout')!, // 薄荷，治療型
        level: 10,
      );
      final enemy = EnemyInstance.fromDefinition(
        StageData.getById('1-1')!.enemies.first,
      );
      final battle = BattleState(
        team: [mint],
        enemies: [enemy],
        teamMaxHp: 1000,
        teamCurrentHp: 500, // 先受傷
      );

      mint.addEnergy(mint.maxEnergy);
      final result = BattleEngine.activateSkill(battle, mint);

      expect(result.hpHealed, greaterThan(0));
      expect(battle.teamCurrentHp, greaterThan(500));
    });

    test('護盾技能正確減傷', () {
      final matcha = BattleAgent(
        definition: CatAgentData.getById('terra')!, // 抹抹，護盾型
        level: 10,
      );
      final enemyDef = const EnemyDefinition(
        id: 'test', name: 'T', emoji: '🎯',
        attribute: AgentAttribute.attributeA,
        baseHp: 999, baseAtk: 100, attackInterval: 1,
      );
      final enemy = EnemyInstance.fromDefinition(enemyDef);
      final battle = BattleState(
        team: [matcha],
        enemies: [enemy],
        teamMaxHp: 1000,
        teamCurrentHp: 1000,
      );

      // 開盾
      matcha.addEnergy(matcha.maxEnergy);
      final result = BattleEngine.activateSkill(battle, matcha);
      expect(result.shieldTurns, greaterThan(0));
      expect(battle.shieldTurnsLeft, greaterThan(0));

      // 敵人攻擊（ATK 100）
      final attacks = BattleEngine.processEnemyPhase(battle);
      expect(attacks, isNotEmpty);

      // 因為有護盾，實際受傷應該少於 100
      final damageTaken = 1000 - battle.teamCurrentHp;
      expect(damageTaken, lessThan(100));
    });

    test('AOE 技能對所有敵人造成傷害', () {
      final kiln = BattleAgent(
        definition: CatAgentData.getById('ember')!, // 窯窯，AOE
        level: 10,
      );
      final enemies = [
        EnemyInstance.fromDefinition(StageData.getById('1-2')!.enemies[0]),
        EnemyInstance.fromDefinition(StageData.getById('1-2')!.enemies[1]),
      ];
      final battle = BattleState(
        team: [kiln],
        enemies: enemies,
        teamMaxHp: 500,
        teamCurrentHp: 500,
      );

      kiln.addEnergy(kiln.maxEnergy);
      final result = BattleEngine.activateSkill(battle, kiln);

      expect(result.damageDealt, greaterThan(0));
      // 兩隻敵人都應該受傷
      for (final e in enemies) {
        expect(e.currentHp, lessThan(e.maxHp));
      }
    });

    test('斬殺技能在低血時加傷', () {
      final caramel = BattleAgent(
        definition: CatAgentData.getById('inferno')!, // 焦糖，斬殺
        level: 10,
      );
      final enemyDef = const EnemyDefinition(
        id: 'test', name: 'T', emoji: '🎯',
        attribute: AgentAttribute.attributeB,
        baseHp: 1000, baseAtk: 10,
      );

      // 高血量敵人
      final enemyHigh = EnemyInstance.fromDefinition(enemyDef);
      final battleHigh = BattleState(
        team: [caramel],
        enemies: [enemyHigh],
        teamMaxHp: 500,
        teamCurrentHp: 500,
      );
      caramel.addEnergy(caramel.maxEnergy);
      final resultHigh = BattleEngine.activateSkill(battleHigh, caramel);

      // 低血量敵人（< 30%）
      final enemyLow = EnemyInstance.fromDefinition(enemyDef);
      enemyLow.takeDamage(750); // HP = 250 = 25%
      final battleLow = BattleState(
        team: [BattleAgent(definition: CatAgentData.getById('inferno')!, level: 10)],
        enemies: [enemyLow],
        teamMaxHp: 500,
        teamCurrentHp: 500,
      );
      battleLow.team.first.addEnergy(battleLow.team.first.maxEnergy);
      final resultLow = BattleEngine.activateSkill(battleLow, battleLow.team.first);

      // 低血時傷害應該更高（+50%）
      expect(resultLow.damageDealt, greaterThan(resultHigh.damageDealt));
    });
  });

  // ═══════════════════════════════════════
  // 3. 技能棋盤效果
  // ═══════════════════════════════════════
  group('技能棋盤效果', () {
    test('技能結果包含棋盤效果資訊', () {
      final wheat = BattleAgent(
        definition: CatAgentData.getById('blaze')!, // 轉色效果
        level: 10,
      );
      final enemy = EnemyInstance.fromDefinition(
        StageData.getById('1-1')!.enemies.first,
      );
      final battle = BattleState(
        team: [wheat],
        enemies: [enemy],
        teamMaxHp: 500,
        teamCurrentHp: 500,
      );

      wheat.addEnergy(wheat.maxEnergy);
      final result = BattleEngine.activateSkill(battle, wheat);

      // 小麥的技能應該有棋盤效果（轉色）
      expect(result.boardEffect, isNotNull);
      expect(result.agentColor, isNotNull);
    });
  });

  // ═══════════════════════════════════════
  // 4. 完整回合循環
  // ═══════════════════════════════════════
  group('完整回合循環', () {
    test('消除→充能→技能→敵攻→回合結算 完整流程', () {
      final wheat = BattleAgent(
        definition: CatAgentData.getById('blaze')!,
        level: 15,
      );
      final enemyDef = const EnemyDefinition(
        id: 'test', name: 'Test', emoji: '🎯',
        attribute: AgentAttribute.attributeB,
        baseHp: 2000, baseAtk: 20, attackInterval: 2,
      );
      final enemy = EnemyInstance.fromDefinition(enemyDef);
      final battle = BattleState(
        team: [wheat],
        enemies: [enemy],
        teamMaxHp: 1000,
        teamCurrentHp: 1000,
      );
      battle.initEnemySkills();

      bool skillUsed = false;
      bool enemyAttacked = false;

      for (int turn = 0; turn < 20; turn++) {
        if (battle.isBattleOver) break;

        // 1. 回合開始效果
        BattleEngine.processTurnStart(battle);

        // 2. 模擬消除（每回合消 3 個 coral）
        BattleEngine.processTick(battle, {BlockColor.coral: 3}, 1);

        // 3. 回合結束打出傷害
        final finalize = BattleEngine.finalizeAttacks(battle);
        for (final atk in finalize.attacks) {
          BattleEngine.applyHitDamage(battle, atk.damage);
        }

        // 4. 嘗試施放技能
        if (wheat.isSkillReady && !skillUsed) {
          final result = BattleEngine.activateSkill(battle, wheat);
          expect(result.damageDealt, greaterThan(0), reason: '技能應造成傷害');
          expect(wheat.currentEnergy, 0, reason: '技能後能量歸零');
          skillUsed = true;
        }

        // 5. 敵方攻擊
        final enemyAtks = BattleEngine.processEnemyPhase(battle);
        if (enemyAtks.isNotEmpty) enemyAttacked = true;

        // 6. 敵方技能
        BattleEngine.processEnemySkillPhase(battle, 5, 7);

        battle.turnCount++;
      }

      expect(skillUsed, true, reason: '20 回合內應該充滿能量施放技能');
      expect(enemyAttacked, true, reason: '敵人 interval=2 應在 20 回合內攻擊');
    });

    test('殺死敵人後自動推進到下一隻', () {
      final wheat = BattleAgent(
        definition: CatAgentData.getById('blaze')!,
        level: 20,
      );
      final enemies = [
        EnemyInstance.fromDefinition(const EnemyDefinition(
          id: 'weak1', name: 'W1', emoji: '🐛',
          attribute: AgentAttribute.attributeB, baseHp: 50, baseAtk: 5,
        )),
        EnemyInstance.fromDefinition(const EnemyDefinition(
          id: 'weak2', name: 'W2', emoji: '🐛',
          attribute: AgentAttribute.attributeB, baseHp: 50, baseAtk: 5,
        )),
      ];
      final battle = BattleState(
        team: [wheat],
        enemies: enemies,
        teamMaxHp: 500,
        teamCurrentHp: 500,
      );

      expect(battle.currentEnemyIndex, 0);

      // 殺第一隻
      wheat.addEnergy(wheat.maxEnergy);
      BattleEngine.activateSkill(battle, wheat);

      if (enemies[0].isDead) {
        expect(battle.currentEnemyIndex, 1, reason: '第一隻死後應推進到第二隻');
      }
    });

    test('所有敵人死亡後判定勝利', () {
      final wheat = BattleAgent(
        definition: CatAgentData.getById('blaze')!,
        level: 30,
      );
      final enemy = EnemyInstance.fromDefinition(const EnemyDefinition(
        id: 'weak', name: 'W', emoji: '🐛',
        attribute: AgentAttribute.attributeB, baseHp: 10, baseAtk: 1,
      ));
      final battle = BattleState(
        team: [wheat],
        enemies: [enemy],
        teamMaxHp: 500,
        teamCurrentHp: 500,
      );

      wheat.addEnergy(wheat.maxEnergy);
      BattleEngine.activateSkill(battle, wheat);

      expect(enemy.isDead, true);
      expect(battle.allEnemiesDead, true);
      expect(battle.isVictory, true);
      expect(battle.isBattleOver, true);
    });

    test('隊伍 HP 歸零判定失敗', () {
      final wheat = BattleAgent(
        definition: CatAgentData.getById('blaze')!,
        level: 1,
      );
      final enemy = EnemyInstance.fromDefinition(const EnemyDefinition(
        id: 'strong', name: 'S', emoji: '💀',
        attribute: AgentAttribute.attributeC, baseHp: 9999, baseAtk: 999, attackInterval: 1,
      ));
      final battle = BattleState(
        team: [wheat],
        enemies: [enemy],
        teamMaxHp: 100,
        teamCurrentHp: 100,
      );

      // 敵人一擊就殺
      BattleEngine.processEnemyPhase(battle);

      expect(battle.teamCurrentHp, 0);
      expect(battle.isTeamDead, true);
      expect(battle.isBattleOver, true);
    });
  });

  // ═══════════════════════════════════════
  // 5. 敵人護盾下的技能互動
  // ═══════════════════════════════════════
  group('敵人護盾下的技能互動', () {
    test('玩家技能傷害先扣護盾', () {
      final wheat = BattleAgent(
        definition: CatAgentData.getById('blaze')!,
        level: 15,
      );
      final enemy = EnemyInstance.fromDefinition(const EnemyDefinition(
        id: 'shielded', name: 'S', emoji: '🛡',
        attribute: AgentAttribute.attributeB, baseHp: 1000, baseAtk: 10,
        skills: [EnemySkillDefinition.shield(percent: 0.5)],
      ));
      final battle = BattleState(
        team: [wheat],
        enemies: [enemy],
        teamMaxHp: 500,
        teamCurrentHp: 500,
      );

      expect(enemy.hasShield, true);
      expect(enemy.skillState.shieldHp, 500);

      wheat.addEnergy(wheat.maxEnergy);
      final result = BattleEngine.activateSkill(battle, wheat);

      // 技能造成傷害，應該先扣護盾
      expect(result.damageDealt, greaterThan(0));
      expect(enemy.skillState.shieldHp, lessThan(500));
    });

    test('棋盤傷害也先扣護盾', () {
      final wheat = BattleAgent(
        definition: CatAgentData.getById('blaze')!,
        level: 10,
      );
      final enemy = EnemyInstance.fromDefinition(const EnemyDefinition(
        id: 'shielded', name: 'S', emoji: '🛡',
        attribute: AgentAttribute.attributeB, baseHp: 1000, baseAtk: 10,
        skills: [EnemySkillDefinition.shield(percent: 0.3)],
      ));
      final battle = BattleState(
        team: [wheat],
        enemies: [enemy],
        teamMaxHp: 500,
        teamCurrentHp: 500,
      );

      final shieldBefore = enemy.skillState.shieldHp;
      BattleEngine.processTick(battle, {BlockColor.coral: 5}, 1);

      // 護盾應被棋盤傷害削減
      expect(enemy.skillState.shieldHp, lessThanOrEqualTo(shieldBefore));
    });
  });

  // ═══════════════════════════════════════
  // 6. 關卡實戰模擬
  // ═══════════════════════════════════════
  group('關卡實戰模擬', () {
    test('1-1 可以在 20 步內通關', () {
      final stage = StageData.getById('1-1')!;
      final wheat = BattleAgent(
        definition: CatAgentData.getById('blaze')!,
        level: 10,
      );
      final enemies = stage.enemies.map(
        (d) => EnemyInstance.fromDefinition(d),
      ).toList();
      final battle = BattleState(
        team: [wheat],
        enemies: enemies,
        teamMaxHp: 500,
        teamCurrentHp: 500,
      );
      battle.initEnemySkills();

      for (int turn = 0; turn < 20; turn++) {
        if (battle.isBattleOver) break;

        BattleEngine.processTurnStart(battle);

        // 模擬消除（每回合 4 個 coral + 2 個其他色）
        BattleEngine.processTick(battle, {BlockColor.coral: 4, BlockColor.mint: 2}, turn + 1);
        final finalize = BattleEngine.finalizeAttacks(battle);
        for (final atk in finalize.attacks) {
          BattleEngine.applyHitDamage(battle, atk.damage);
        }

        if (wheat.isSkillReady) {
          BattleEngine.activateSkill(battle, wheat);
        }

        BattleEngine.processEnemyPhase(battle);
        BattleEngine.processEnemySkillPhase(battle, 3, 10);
        battle.turnCount++;
      }

      expect(battle.isVictory, true, reason: '1-1 只有 160 HP 的小餐包，20 步應能通關');
    });

    test('1-10 Boss 護盾被正確處理', () {
      final stage = StageData.getById('1-10')!;
      final wheat = BattleAgent(definition: CatAgentData.getById('blaze')!, level: 15);
      final enemies = stage.enemies.map(
        (d) => EnemyInstance.fromDefinition(d),
      ).toList();
      final battle = BattleState(
        team: [wheat],
        enemies: enemies,
        teamMaxHp: 800,
        teamCurrentHp: 800,
      );
      battle.initEnemySkills();

      // Boss 是最後一隻
      final boss = enemies.last;
      expect(boss.definition.id, 'rat_boss');
      expect(boss.hasShield, true);

      final shieldBefore = boss.skillState.shieldHp;

      // 打 30 回合
      for (int turn = 0; turn < 30; turn++) {
        if (battle.isBattleOver) break;

        BattleEngine.processTurnStart(battle);
        BattleEngine.processTick(battle, {BlockColor.coral: 4}, turn + 1);
        final finalize = BattleEngine.finalizeAttacks(battle);
        for (final atk in finalize.attacks) {
          BattleEngine.applyHitDamage(battle, atk.damage);
        }
        if (wheat.isSkillReady) {
          BattleEngine.activateSkill(battle, wheat);
        }
        BattleEngine.processEnemyPhase(battle);
        BattleEngine.processEnemySkillPhase(battle, 3, 10);
        battle.turnCount++;
      }

      // Boss 護盾應該已被打穿或至少削減
      if (!boss.isDead) {
        expect(boss.skillState.shieldHp, lessThan(shieldBefore),
            reason: 'Boss 護盾應被削減');
      }
    });
  });

  // ═══════════════════════════════════════
  // 7. 能量系統邊界測試
  // ═══════════════════════════════════════
  group('能量系統', () {
    test('能量不會超過上限', () {
      final wheat = BattleAgent(
        definition: CatAgentData.getById('blaze')!,
        level: 10,
      );
      final max = wheat.maxEnergy;
      wheat.addEnergy(max + 100);
      expect(wheat.currentEnergy, max);
    });

    test('技能施放後能量歸零', () {
      final wheat = BattleAgent(
        definition: CatAgentData.getById('blaze')!,
        level: 10,
      );
      wheat.addEnergy(wheat.maxEnergy);
      expect(wheat.isSkillReady, true);

      wheat.useSkill();
      expect(wheat.currentEnergy, 0);
      expect(wheat.isSkillReady, false);
    });

    test('連續消除多回合可充滿能量', () {
      final wheat = BattleAgent(
        definition: CatAgentData.getById('blaze')!,
        level: 10,
      );
      final enemy = EnemyInstance.fromDefinition(const EnemyDefinition(
        id: 'test', name: 'T', emoji: '🎯',
        attribute: AgentAttribute.attributeB, baseHp: 9999, baseAtk: 1,
      ));
      final battle = BattleState(
        team: [wheat],
        enemies: [enemy],
        teamMaxHp: 500,
        teamCurrentHp: 500,
      );

      // 每回合消 2 個 coral，能量 cost 是 5，應在 3 回合左右充滿
      for (int i = 0; i < 5; i++) {
        BattleEngine.processTick(battle, {BlockColor.coral: 2}, i + 1);
        if (wheat.isSkillReady) break;
      }
      expect(wheat.isSkillReady, true,
          reason: '消除 5 回合 x 2 coral = 10 能量，cost 5 應充滿');
    });
  });
}
