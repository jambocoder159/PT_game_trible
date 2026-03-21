/// 敵人模型
/// 關卡中出現的敵人定義和實例
import '../models/cat_agent.dart';

/// 敵人定義（靜態數據）
class EnemyDefinition {
  final String id;
  final String name;
  final String emoji; // 簡易圖示
  final AgentAttribute attribute;
  final int baseHp;
  final int baseAtk;
  final int attackInterval; // 每幾回合攻擊一次

  const EnemyDefinition({
    required this.id,
    required this.name,
    required this.emoji,
    required this.attribute,
    required this.baseHp,
    required this.baseAtk,
    this.attackInterval = 3,
  });
}

/// 戰鬥中的敵人實例（可變狀態）
class EnemyInstance {
  final EnemyDefinition definition;
  int currentHp;
  int maxHp;
  int atk;
  int attackCountdown; // 距離下次攻擊的回合數

  EnemyInstance({
    required this.definition,
    required this.maxHp,
    required this.atk,
  })  : currentHp = maxHp,
        attackCountdown = definition.attackInterval;

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

  /// 受到傷害（回傳實際傷害值）
  int takeDamage(int damage) {
    final actual = damage.clamp(0, currentHp);
    currentHp -= actual;
    return actual;
  }

  /// 倒數攻擊計時，回傳是否要攻擊
  bool tickAttack() {
    attackCountdown--;
    if (attackCountdown <= 0) {
      attackCountdown = definition.attackInterval;
      return true;
    }
    return false;
  }
}
