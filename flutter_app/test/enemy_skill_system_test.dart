/// 敵人技能系統測試
/// 驗證 v2 技能機制的核心邏輯
import 'package:flutter_test/flutter_test.dart';
import 'package:match3_puzzle/core/models/enemy.dart';
import 'package:match3_puzzle/core/models/cat_agent.dart';
import 'package:match3_puzzle/core/models/battle_state.dart';
import 'package:match3_puzzle/core/engine/battle_engine.dart';
import 'package:match3_puzzle/config/stage_data.dart';

void main() {
  // ═══════════════════════════════════════
  // 1. EnemyDefinition 技能配置
  // ═══════════════════════════════════════
  group('EnemyDefinition 技能配置', () {
    test('無技能敵人 skills 為空', () {
      const rat = EnemyDefinition(
        id: 'rat', name: '小餐包', emoji: '🍞',
        attribute: AgentAttribute.attributeB,
        baseHp: 160, baseAtk: 8,
      );
      expect(rat.skills, isEmpty);
      expect(rat.hasPhases, false);
    });

    test('帶護盾技能的 Boss', () {
      const boss = EnemyDefinition(
        id: 'boss', name: 'Boss', emoji: '👑',
        attribute: AgentAttribute.attributeB,
        baseHp: 800, baseAtk: 25,
        skills: [EnemySkillDefinition.shield(percent: 0.2)],
      );
      expect(boss.skills.length, 1);
      expect(boss.skills[0].type, EnemySkillType.shield);
      expect(boss.skills[0].shieldPercent, 0.2);
    });

    test('多技能敵人', () {
      const enemy = EnemyDefinition(
        id: 'multi', name: 'Multi', emoji: '💀',
        attribute: AgentAttribute.attributeA,
        baseHp: 500, baseAtk: 30,
        skills: [
          EnemySkillDefinition.obstacle(count: 3, cooldown: 4),
          EnemySkillDefinition.charge(),
          EnemySkillDefinition.rage(),
        ],
      );
      expect(enemy.skills.length, 3);
      expect(enemy.skills[0].blockCount, 3);
      expect(enemy.skills[0].cooldown, 4);
    });
  });

  // ═══════════════════════════════════════
  // 2. EnemyInstance 護盾機制
  // ═══════════════════════════════════════
  group('護盾機制', () {
    test('護盾在開場時自動生成', () {
      const def = EnemyDefinition(
        id: 'shielded', name: 'S', emoji: '🛡',
        attribute: AgentAttribute.attributeA,
        baseHp: 1000, baseAtk: 20,
        skills: [EnemySkillDefinition.shield(percent: 0.3)],
      );
      final enemy = EnemyInstance.fromDefinition(def);
      expect(enemy.hasShield, true);
      expect(enemy.skillState.shieldHp, 300); // 1000 * 0.3
      expect(enemy.skillState.shieldMaxHp, 300);
    });

    test('傷害先扣護盾再扣血', () {
      const def = EnemyDefinition(
        id: 'shielded', name: 'S', emoji: '🛡',
        attribute: AgentAttribute.attributeA,
        baseHp: 1000, baseAtk: 20,
        skills: [EnemySkillDefinition.shield(percent: 0.2)],
      );
      final enemy = EnemyInstance.fromDefinition(def);
      expect(enemy.skillState.shieldHp, 200);

      // 打 100 傷害 → 全吸收在盾上
      final bodyDmg1 = enemy.takeDamage(100);
      expect(bodyDmg1, 0);
      expect(enemy.currentHp, 1000); // 本體不受傷
      expect(enemy.skillState.shieldHp, 100);

      // 再打 150 → 盾碎 + 溢出 50 到本體
      final bodyDmg2 = enemy.takeDamage(150);
      expect(bodyDmg2, 50);
      expect(enemy.currentHp, 950);
      expect(enemy.skillState.shieldHp, 0);
      expect(enemy.hasShield, false);
    });

    test('無護盾時傷害直接扣血', () {
      const def = EnemyDefinition(
        id: 'normal', name: 'N', emoji: '🍞',
        attribute: AgentAttribute.attributeB,
        baseHp: 500, baseAtk: 10,
      );
      final enemy = EnemyInstance.fromDefinition(def);
      expect(enemy.hasShield, false);

      final dmg = enemy.takeDamage(100);
      expect(dmg, 100);
      expect(enemy.currentHp, 400);
    });
  });

  // ═══════════════════════════════════════
  // 3. 狂暴機制
  // ═══════════════════════════════════════
  group('狂暴機制', () {
    test('HP < 30% 時觸發狂暴', () {
      const def = EnemyDefinition(
        id: 'rager', name: 'R', emoji: '🔥',
        attribute: AgentAttribute.attributeA,
        baseHp: 1000, baseAtk: 20, attackInterval: 3,
        skills: [EnemySkillDefinition.rage()],
      );
      final enemy = EnemyInstance.fromDefinition(def);
      expect(enemy.skillState.isEnraged, false);
      expect(enemy.atk, 20);

      // 打到 HP = 350 (35%) → 不觸發
      enemy.takeDamage(650);
      expect(enemy.skillState.isEnraged, false);
      expect(enemy.atk, 20);

      // 再打 60 → HP = 290 (29%) → 觸發！
      enemy.takeDamage(60);
      expect(enemy.skillState.isEnraged, true);
      expect(enemy.atk, 40); // ATK x2
      expect(enemy.effectiveAttackInterval, 2); // 間隔 -1
    });

    test('無狂暴技能不觸發', () {
      const def = EnemyDefinition(
        id: 'normal', name: 'N', emoji: '🍞',
        attribute: AgentAttribute.attributeB,
        baseHp: 1000, baseAtk: 20,
      );
      final enemy = EnemyInstance.fromDefinition(def);
      enemy.takeDamage(800); // HP = 200 (20%)
      expect(enemy.skillState.isEnraged, false);
      expect(enemy.atk, 20);
    });

    test('狂暴只觸發一次', () {
      const def = EnemyDefinition(
        id: 'rager', name: 'R', emoji: '🔥',
        attribute: AgentAttribute.attributeA,
        baseHp: 1000, baseAtk: 20,
        skills: [EnemySkillDefinition.rage()],
      );
      final enemy = EnemyInstance.fromDefinition(def);
      enemy.takeDamage(750); // 觸發狂暴
      expect(enemy.atk, 40);

      enemy.takeDamage(50); // 再受傷不會再翻倍
      expect(enemy.atk, 40); // 仍然是 40，不是 80
    });
  });

  // ═══════════════════════════════════════
  // 4. 蓄力重擊
  // ═══════════════════════════════════════
  group('蓄力重擊', () {
    test('蓄力狀態正確設定和清除', () {
      const def = EnemyDefinition(
        id: 'charger', name: 'C', emoji: '⚡',
        attribute: AgentAttribute.attributeA,
        baseHp: 500, baseAtk: 30, attackInterval: 3,
        skills: [EnemySkillDefinition.charge()],
      );
      final enemy = EnemyInstance.fromDefinition(def);
      final battle = _createMinimalBattle([enemy]);

      // 蓄力在 countdown == 2 時觸發（由 processEnemySkillPhase 處理）
      // 手動設定測試蓄力傷害
      enemy.skillState.isCharging = true;
      final damage = battle.enemyAttackFrom(enemy);

      // 蓄力 3 倍
      expect(damage, 90); // 30 * 3
      expect(enemy.skillState.isCharging, false); // 攻擊後清除
    });
  });

  // ═══════════════════════════════════════
  // 5. 回血機制
  // ═══════════════════════════════════════
  group('回血機制', () {
    test('applyHeal 正確回血', () {
      const def = EnemyDefinition(
        id: 'healer', name: 'H', emoji: '💚',
        attribute: AgentAttribute.attributeA,
        baseHp: 1000, baseAtk: 20,
        skills: [EnemySkillDefinition.heal(percent: 0.10, cooldown: 3)],
      );
      final enemy = EnemyInstance.fromDefinition(def);
      enemy.takeDamage(500); // HP = 500
      expect(enemy.currentHp, 500);

      enemy.applyHeal(0.10);
      expect(enemy.currentHp, 600); // +100
    });

    test('回血不超過 maxHp', () {
      const def = EnemyDefinition(
        id: 'healer', name: 'H', emoji: '💚',
        attribute: AgentAttribute.attributeA,
        baseHp: 1000, baseAtk: 20,
      );
      final enemy = EnemyInstance.fromDefinition(def);
      enemy.takeDamage(50); // HP = 950

      enemy.applyHeal(0.10); // +100 但不超過 1000
      expect(enemy.currentHp, 1000);
    });
  });

  // ═══════════════════════════════════════
  // 6. 技能冷卻系統
  // ═══════════════════════════════════════
  group('技能冷卻系統', () {
    test('冷卻計時器正確遞減和觸發', () {
      const def = EnemyDefinition(
        id: 'obs', name: 'O', emoji: '🧱',
        attribute: AgentAttribute.attributeA,
        baseHp: 500, baseAtk: 20,
        skills: [EnemySkillDefinition.obstacle(count: 2, cooldown: 3)],
      );
      final enemy = EnemyInstance.fromDefinition(def);

      // 初始冷卻 = 3
      var triggered = enemy.skillState.tickCooldowns();
      expect(triggered, isEmpty); // 3→2，未觸發

      triggered = enemy.skillState.tickCooldowns();
      expect(triggered, isEmpty); // 2→1

      triggered = enemy.skillState.tickCooldowns();
      expect(triggered, contains(EnemySkillType.obstacle)); // 1→0，觸發！
    });

    test('觸發後重置冷卻', () {
      final state = EnemySkillState();
      state.cooldownTimers[EnemySkillType.obstacle] = 1;

      final triggered = state.tickCooldowns();
      expect(triggered, contains(EnemySkillType.obstacle));

      state.resetCooldown(EnemySkillType.obstacle, 4);
      expect(state.cooldownTimers[EnemySkillType.obstacle], 4);
    });
  });

  // ═══════════════════════════════════════
  // 7. 棋盤技能互動
  // ═══════════════════════════════════════
  group('棋盤技能互動', () {
    test('障礙格被相鄰消除 2 次後碎裂', () {
      final battle = _createMinimalBattle([]);
      battle.obstacleBlocks.add(ObstacleBlock(col: 2, row: 3));

      // 第 1 次相鄰消除
      final result1 = BattleEngine.processMatchBoardSkills(
        battle, [(1, 3)], // 相鄰 (2,3) 的位置
      );
      expect(result1.clearedObstacles, isEmpty); // 還沒碎
      expect(battle.obstacleBlocks.first.hitCount, 1);

      // 第 2 次相鄰消除
      final result2 = BattleEngine.processMatchBoardSkills(
        battle, [(3, 3)],
      );
      expect(result2.clearedObstacles, hasLength(1));
      expect(battle.obstacleBlocks, isEmpty); // 已清除
    });

    test('消除毒格安全解除（不扣血）', () {
      final battle = _createMinimalBattle([]);
      battle.poisonBlocks.add(PoisonBlock(col: 1, row: 2, countdown: 2));

      final result = BattleEngine.processMatchBoardSkills(
        battle, [(1, 2)], // 直接消除毒格位置
      );
      expect(result.clearedPoisons, hasLength(1));
      expect(battle.poisonBlocks, isEmpty);
    });

    test('弱化格在消除中被統計', () {
      final battle = _createMinimalBattle([]);
      battle.weakenedBlocks.add(WeakenedBlock(col: 0, row: 0));
      battle.weakenedBlocks.add(WeakenedBlock(col: 1, row: 0));

      final result = BattleEngine.processMatchBoardSkills(
        battle, [(0, 0), (1, 0), (2, 0)],
      );
      expect(result.weakenedInMatch, 2);
      expect(result.clearedWeakened, hasLength(2));
    });

    test('技能消除直接清除障礙/毒/弱化', () {
      final battle = _createMinimalBattle([]);
      battle.obstacleBlocks.add(ObstacleBlock(col: 0, row: 0));
      battle.poisonBlocks.add(PoisonBlock(col: 1, row: 1, countdown: 3));
      battle.weakenedBlocks.add(WeakenedBlock(col: 2, row: 2));

      final cleared = BattleEngine.clearBoardSkillsBySkillEliminate(
        battle, [(0, 0), (1, 1), (2, 2)],
      );
      expect(cleared, hasLength(3));
      expect(battle.obstacleBlocks, isEmpty);
      expect(battle.poisonBlocks, isEmpty);
      expect(battle.weakenedBlocks, isEmpty);
    });

    test('轉色清除弱化和毒格', () {
      final battle = _createMinimalBattle([]);
      battle.weakenedBlocks.add(WeakenedBlock(col: 0, row: 0));
      battle.poisonBlocks.add(PoisonBlock(col: 1, row: 1, countdown: 2));
      battle.obstacleBlocks.add(ObstacleBlock(col: 2, row: 2));

      final cleared = BattleEngine.clearBoardSkillsByConvert(
        battle, [(0, 0), (1, 1), (2, 2)],
      );
      // 轉色只清弱化和毒，不清障礙
      expect(cleared, hasLength(2));
      expect(battle.weakenedBlocks, isEmpty);
      expect(battle.poisonBlocks, isEmpty);
      expect(battle.obstacleBlocks, hasLength(1)); // 障礙仍在
    });
  });

  // ═══════════════════════════════════════
  // 8. 屬性壓制
  // ═══════════════════════════════════════
  group('屬性壓制', () {
    test('initEnemySkills 收集壓制光環', () {
      const enemy = EnemyDefinition(
        id: 'aura', name: 'A', emoji: '🔮',
        attribute: AgentAttribute.attributeE,
        baseHp: 500, baseAtk: 20,
        skills: [EnemySkillDefinition.aura(suppressed: AgentAttribute.attributeB)],
      );
      final instance = EnemyInstance.fromDefinition(enemy);
      final battle = _createMinimalBattle([instance]);
      battle.initEnemySkills();

      expect(battle.isAttributeSuppressed(AgentAttribute.attributeB), true);
      expect(battle.isAttributeSuppressed(AgentAttribute.attributeA), false);
    });
  });

  // ═══════════════════════════════════════
  // 9. Boss 三階段
  // ═══════════════════════════════════════
  group('Boss 三階段', () {
    test('階段依 HP 閾值自動切換', () {
      const boss = EnemyDefinition(
        id: 'boss', name: 'Boss', emoji: '😈',
        attribute: AgentAttribute.attributeE,
        baseHp: 1000, baseAtk: 30, attackInterval: 3,
        skills: [
          EnemySkillDefinition.shield(percent: 0.2),
          EnemySkillDefinition.obstacle(count: 2, cooldown: 3),
        ],
        phases: [
          BossPhaseDefinition(
            hpThreshold: 0.6,
            phaseName: 'Phase 2',
            skills: [
              EnemySkillDefinition.poison(count: 3, countdown: 2, cooldown: 2),
              EnemySkillDefinition.heal(percent: 0.08, cooldown: 3),
            ],
          ),
          BossPhaseDefinition(
            hpThreshold: 0.3,
            phaseName: 'Phase 3',
            skills: [
              EnemySkillDefinition.rage(),
              EnemySkillDefinition.charge(),
            ],
          ),
        ],
      );

      final enemy = EnemyInstance.fromDefinition(boss);
      expect(enemy.skillState.currentPhase, -1); // 初始階段

      // Phase 1: 使用基礎技能
      expect(enemy.hasSkill(EnemySkillType.shield), true);
      expect(enemy.hasSkill(EnemySkillType.obstacle), true);
      expect(enemy.hasSkill(EnemySkillType.poison), false);

      // 打護盾 (200) + 打到 HP < 60%
      enemy.takeDamage(200); // 先打護盾
      expect(enemy.currentHp, 1000); // 本體還是滿的
      enemy.takeDamage(450); // HP = 550 (55%) → Phase 2
      expect(enemy.skillState.currentPhase, 0);
      expect(enemy.skillState.currentPhaseName, 'Phase 2');
      expect(enemy.hasSkill(EnemySkillType.poison), true);
      expect(enemy.hasSkill(EnemySkillType.heal), true);
      expect(enemy.hasSkill(EnemySkillType.obstacle), false); // Phase 1 技能不見了

      // 打到 HP < 30% → Phase 3
      enemy.takeDamage(300); // HP = 250 (25%)
      expect(enemy.skillState.currentPhase, 1);
      expect(enemy.skillState.currentPhaseName, 'Phase 3');
      expect(enemy.hasSkill(EnemySkillType.rage), true);
      expect(enemy.hasSkill(EnemySkillType.charge), true);
      expect(enemy.hasSkill(EnemySkillType.poison), false);
      expect(enemy.skillState.isEnraged, true); // 狂暴自動觸發
      expect(enemy.atk, 60); // 30 * 2
    });

    test('非 Boss 無階段切換', () {
      const normal = EnemyDefinition(
        id: 'normal', name: 'N', emoji: '🍞',
        attribute: AgentAttribute.attributeB,
        baseHp: 500, baseAtk: 10,
      );
      final enemy = EnemyInstance.fromDefinition(normal);
      enemy.takeDamage(400);
      expect(enemy.skillState.currentPhase, -1);
    });
  });

  // ═══════════════════════════════════════
  // 10. 毒格倒數爆炸
  // ═══════════════════════════════════════
  group('毒格倒數爆炸', () {
    test('毒格倒數歸零造成傷害', () {
      const enemy = EnemyDefinition(
        id: 'poisoner', name: 'P', emoji: '☠',
        attribute: AgentAttribute.attributeA,
        baseHp: 500, baseAtk: 40,
        skills: [EnemySkillDefinition.poison(count: 2, countdown: 1, cooldown: 99)],
      );
      final instance = EnemyInstance.fromDefinition(enemy);
      final battle = _createMinimalBattle([instance]);

      // 手動加毒格（倒數 1 = 下一回合爆炸）
      battle.poisonBlocks.add(PoisonBlock(col: 0, row: 0, countdown: 1));
      battle.poisonBlocks.add(PoisonBlock(col: 1, row: 1, countdown: 1));

      final hpBefore = battle.teamCurrentHp;
      final result = BattleEngine.processEnemySkillPhase(battle, 5, 7);

      // 毒格應該爆炸並造成傷害
      final poisonEvents = result.events.where(
        (e) => e.type == EnemySkillType.poison && e.poisonDamage != null && e.poisonDamage! > 0,
      );
      expect(poisonEvents, isNotEmpty);
      expect(battle.teamCurrentHp, lessThan(hpBefore));
      expect(battle.poisonBlocks, isEmpty); // 爆炸後清除
    });

    test('弱化格自動過期', () {
      final battle = _createMinimalBattle([]);
      battle.weakenedBlocks.add(WeakenedBlock(col: 0, row: 0, turnsLeft: 1));

      BattleEngine.processEnemySkillPhase(battle, 5, 7);
      // turnsLeft 1 → 0 → expired → 清除
      expect(battle.weakenedBlocks, isEmpty);
    });
  });

  // ═══════════════════════════════════════
  // 11. stage_data 完整性
  // ═══════════════════════════════════════
  group('stage_data 完整性', () {
    test('60 關全部存在', () {
      expect(StageData.allStages.length, 60);
    });

    test('每章 10 關', () {
      for (int ch = 1; ch <= 6; ch++) {
        final stages = StageData.getChapterStages(ch);
        expect(stages.length, 10, reason: '第 $ch 章應有 10 關');
      }
    });

    test('1-10 Boss 有護盾', () {
      final stage = StageData.getById('1-10');
      expect(stage, isNotNull);
      final boss = stage!.enemies.last;
      expect(boss.skills.any((s) => s.type == EnemySkillType.shield), true);
    });

    test('6-10 最終 Boss 有三階段', () {
      final stage = StageData.getById('6-10');
      expect(stage, isNotNull);
      final boss = stage!.enemies.last;
      expect(boss.hasPhases, true);
      expect(boss.phases.length, 2); // Phase 2 + Phase 3
      expect(boss.phases[0].phaseName, '料理風暴');
      expect(boss.phases[1].phaseName, '最終狂暴');
    });

    test('Ch5 有屬性壓制敵人', () {
      final stage54 = StageData.getById('5-4');
      expect(stage54, isNotNull);
      final hasAura = stage54!.enemies.any(
        (e) => e.skills.any((s) => s.type == EnemySkillType.aura),
      );
      expect(hasAura, true);
    });

    test('所有關卡敵人列表非空', () {
      for (final stage in StageData.allStages) {
        expect(stage.enemies, isNotEmpty, reason: '${stage.id} 敵人列表不應為空');
      }
    });
  });

  // ═══════════════════════════════════════
  // 12. Bug 回歸測試
  // ═══════════════════════════════════════
  group('Bug 回歸：蓄力不卡住', () {
    test('attackInterval=2 的敵人不會永久卡在蓄力狀態', () {
      const charger = EnemyDefinition(
        id: 'fast_charger', name: 'FC', emoji: '⚡',
        attribute: AgentAttribute.attributeD,
        baseHp: 500, baseAtk: 30, attackInterval: 2,
        skills: [EnemySkillDefinition.charge()],
      );
      final enemy = EnemyInstance.fromDefinition(charger);
      final battle = _createMinimalBattle([enemy]);

      // 模擬多個回合：processEnemyPhase → processEnemySkillPhase
      int chargeCount = 0;
      int attackCount = 0;

      for (int turn = 0; turn < 10; turn++) {
        // 1. 敵方攻擊階段
        final attacks = BattleEngine.processEnemyPhase(battle);
        if (attacks.isNotEmpty) attackCount++;

        // 2. 敵方技能階段
        BattleEngine.processEnemySkillPhase(battle, 5, 7);
        if (enemy.skillState.isCharging) chargeCount++;
      }

      // 10 回合中不應該每回合都在蓄力
      // attackInterval=2 → 約 5 次攻擊，蓄力應只在攻擊前 1 回合
      expect(chargeCount, lessThan(6),
          reason: '蓄力回合數不應超過總回合的一半，否則代表卡住了');
      expect(attackCount, greaterThan(3),
          reason: '10 回合中 interval=2 的敵人應攻擊至少 4 次');
    });

    test('attackInterval=3 的敵人蓄力只持續 1 回合', () {
      const charger = EnemyDefinition(
        id: 'charger3', name: 'C3', emoji: '⚡',
        attribute: AgentAttribute.attributeA,
        baseHp: 500, baseAtk: 30, attackInterval: 3,
        skills: [EnemySkillDefinition.charge()],
      );
      final enemy = EnemyInstance.fromDefinition(charger);
      final battle = _createMinimalBattle([enemy]);

      final chargingTurns = <int>[];

      for (int turn = 0; turn < 12; turn++) {
        BattleEngine.processEnemyPhase(battle);
        BattleEngine.processEnemySkillPhase(battle, 5, 7);
        if (enemy.skillState.isCharging) chargingTurns.add(turn);
      }

      // interval=3 → 攻擊在 turn 2,5,8,11
      // 蓄力在攻擊前 1 回合 = turn 1,4,7,10
      // 蓄力不應連續出現
      for (int i = 1; i < chargingTurns.length; i++) {
        expect(chargingTurns[i] - chargingTurns[i - 1], greaterThan(1),
            reason: '蓄力不應連續出現在相鄰回合: $chargingTurns');
      }
    });

    test('蓄力攻擊確實造成 3 倍傷害後清除', () {
      const charger = EnemyDefinition(
        id: 'charger', name: 'C', emoji: '⚡',
        attribute: AgentAttribute.attributeA,
        baseHp: 500, baseAtk: 20, attackInterval: 3,
        skills: [EnemySkillDefinition.charge()],
      );
      final enemy = EnemyInstance.fromDefinition(charger);
      final battle = _createMinimalBattle([enemy]);

      // 快進到蓄力觸發
      bool foundCharge = false;
      for (int turn = 0; turn < 6; turn++) {
        BattleEngine.processEnemyPhase(battle);
        BattleEngine.processEnemySkillPhase(battle, 5, 7);
        if (enemy.skillState.isCharging && !foundCharge) {
          foundCharge = true;
          // 下一回合應該攻擊
          final hpBefore = battle.teamCurrentHp;
          final attacks = BattleEngine.processEnemyPhase(battle);
          expect(attacks, isNotEmpty, reason: '蓄力後下一回合應該攻擊');
          if (attacks.isNotEmpty) {
            expect(attacks.first.damage, 60, reason: 'ATK 20 * 3 = 60'); // 3x
          }
          expect(enemy.skillState.isCharging, false, reason: '攻擊後應清除蓄力');
          expect(battle.teamCurrentHp, lessThan(hpBefore));
          break;
        }
      }
      expect(foundCharge, true, reason: '應該在 6 回合內觸發蓄力');
    });
  });

  group('Bug 回歸：完整回合流程不崩潰', () {
    test('有技能的敵人跑 20 回合不拋異常', () {
      // 用 3-10 Boss（毒+回血+蓄力）
      final stage = StageData.getById('3-10');
      expect(stage, isNotNull);

      final enemies = stage!.enemies.map((def) {
        return EnemyInstance.fromDefinition(def, hpMultiplier: 1.5, atkMultiplier: 1.2);
      }).toList();

      final battle = _createMinimalBattle(enemies);
      battle.initEnemySkills();

      // 模擬 20 回合
      for (int turn = 0; turn < 20; turn++) {
        if (battle.isBattleOver) break;

        // 回合開始
        BattleEngine.processTurnStart(battle);

        // 敵方攻擊
        BattleEngine.processEnemyPhase(battle);

        // 敵方技能
        BattleEngine.processEnemySkillPhase(battle, 5, 7);
      }
      // 跑完不崩就算通過
    });

    test('6-10 最終 Boss 三階段跑完不崩潰', () {
      final stage = StageData.getById('6-10');
      expect(stage, isNotNull);

      final enemies = stage!.enemies.map((def) {
        return EnemyInstance.fromDefinition(def, hpMultiplier: 2.25, atkMultiplier: 1.5);
      }).toList();

      final battle = _createMinimalBattle(enemies);
      battle.initEnemySkills();

      final boss = enemies.last;
      expect(boss.definition.id, 'final_boss');

      // 持續打 Boss 觸發所有階段
      for (int turn = 0; turn < 50; turn++) {
        if (battle.isBattleOver) break;
        BattleEngine.processTurnStart(battle);
        BattleEngine.processEnemyPhase(battle);
        BattleEngine.processEnemySkillPhase(battle, 5, 7);

        // 模擬玩家對 Boss 造成大量傷害（需要穿透護盾+本體）
        if (!boss.isDead) {
          boss.takeDamage(500);
        }
      }
      // 跑完不崩就算通過，檢查階段有切換
      expect(boss.skillState.currentPhase, greaterThanOrEqualTo(0),
          reason: '經過足夠傷害後 Boss 應進入至少 Phase 2');
    });
  });
}

// ─── 測試輔助 ───

BattleState _createMinimalBattle(List<EnemyInstance> enemies) {
  return BattleState(
    team: [],
    enemies: enemies,
    teamMaxHp: 1000,
    teamCurrentHp: 1000,
  );
}
