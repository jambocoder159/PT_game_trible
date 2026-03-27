/// 進化 Widget
/// 顯示角色的進化狀態和進化按鈕
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/evolution_data.dart';
import '../../../config/theme.dart';
import '../../../core/models/cat_agent.dart';
import '../../../core/models/evolution.dart';
import '../../../core/models/material.dart';
import '../providers/player_provider.dart';

class EvolutionWidget extends StatelessWidget {
  final CatAgentDefinition definition;
  final int currentStage;
  final int currentLevel;

  const EvolutionWidget({
    super.key,
    required this.definition,
    required this.currentStage,
    required this.currentLevel,
  });

  @override
  Widget build(BuildContext context) {
    final evolutions = EvolutionData.getEvolutionsForRarity(definition.rarity.name);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 當前進化狀態
          _CurrentStageCard(
            definition: definition,
            currentStage: currentStage,
          ),
          const SizedBox(height: 16),
          // 進化階段列表
          ...evolutions.map((evo) {
            final isUnlocked = currentStage >= evo.stage;
            final isNext = currentStage == evo.stage - 1;
            final canEvolve = isNext && currentLevel >= evo.requiredLevel;

            return _EvolutionStageCard(
              definition: definition,
              evo: evo,
              isUnlocked: isUnlocked,
              isNext: isNext,
              canEvolve: canEvolve,
              currentLevel: currentLevel,
            );
          }),
        ],
      ),
    );
  }
}

class _CurrentStageCard extends StatelessWidget {
  final CatAgentDefinition definition;
  final int currentStage;

  const _CurrentStageCard({
    required this.definition,
    required this.currentStage,
  });

  @override
  Widget build(BuildContext context) {
    final stageName = currentStage == 0
        ? '基礎型態'
        : currentStage == 1
            ? '一階進化'
            : '二階進化';
    final stageColor = currentStage == 0
        ? Colors.grey
        : currentStage == 1
            ? Colors.blue
            : Colors.amber;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: stageColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: stageColor, width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: definition.attribute.blockColor.color.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Center(
              child: Text(definition.attribute.emoji,
                  style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getDisplayName(),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: stageColor.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        stageName,
                        style: TextStyle(
                          color: stageColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (currentStage > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        _getMultiplierText(),
                        style: TextStyle(
                          color: Colors.green.shade300,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // 進化星星指示器
          Row(
            children: List.generate(2, (i) {
              return Icon(
                i < currentStage ? Icons.star : Icons.star_border,
                color: i < currentStage ? Colors.amber : AppTheme.textSecondary.withAlpha(60),
                size: 24,
              );
            }),
          ),
        ],
      ),
    );
  }

  String _getDisplayName() {
    if (currentStage == 0) return definition.name;
    final evolutions = EvolutionData.getEvolutionsForRarity(definition.rarity.name);
    if (currentStage <= evolutions.length) {
      return '${definition.name}${evolutions[currentStage - 1].nameSuffix}';
    }
    return definition.name;
  }

  String _getMultiplierText() {
    final evo = EvolutionData.getEvolution(definition.rarity.name, currentStage);
    if (evo == null) return '';
    final pct = ((evo.atkMultiplier - 1) * 100).round();
    return '數值 +$pct%';
  }
}

class _EvolutionStageCard extends StatelessWidget {
  final CatAgentDefinition definition;
  final EvolutionStageDefinition evo;
  final bool isUnlocked;
  final bool isNext;
  final bool canEvolve;
  final int currentLevel;

  const _EvolutionStageCard({
    required this.definition,
    required this.evo,
    required this.isUnlocked,
    required this.isNext,
    required this.canEvolve,
    required this.currentLevel,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isUnlocked
        ? Colors.green
        : canEvolve
            ? Colors.amber
            : AppTheme.textSecondary.withAlpha(40);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isUnlocked
          ? AppTheme.bgCard
          : AppTheme.bgCard.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: BorderSide(color: borderColor, width: isUnlocked ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: borderColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${evo.stage} 階進化',
                    style: TextStyle(
                      color: borderColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${definition.name}${evo.nameSuffix}',
                  style: TextStyle(
                    color: isUnlocked
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isUnlocked) ...[
                  const Spacer(),
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                ],
              ],
            ),
            const SizedBox(height: 8),
            // 數值加成
            Row(
              children: [
                _BonusChip(
                    'ATK',
                    '+${((evo.atkMultiplier - 1) * 100).round()}%',
                    Colors.red.shade300),
                const SizedBox(width: 6),
                _BonusChip(
                    'DEF',
                    '+${((evo.defMultiplier - 1) * 100).round()}%',
                    Colors.blue.shade300),
                const SizedBox(width: 6),
                _BonusChip(
                    'HP',
                    '+${((evo.hpMultiplier - 1) * 100).round()}%',
                    Colors.green.shade300),
                const SizedBox(width: 6),
                _BonusChip(
                    'Lv上限',
                    '+${evo.maxLevelIncrease}',
                    Colors.amber.shade300),
              ],
            ),
            if (isNext) ...[
              const SizedBox(height: 10),
              // 等級需求
              Row(
                children: [
                  Icon(
                    currentLevel >= evo.requiredLevel
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: currentLevel >= evo.requiredLevel
                        ? Colors.green
                        : Colors.red,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '需要等級 ${evo.requiredLevel}（目前 Lv.$currentLevel）',
                    style: TextStyle(
                      color: currentLevel >= evo.requiredLevel
                          ? Colors.green
                          : Colors.red.shade300,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 進化按鈕
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canEvolve
                      ? () async {
                          final provider = context.read<PlayerProvider>();
                          final success = await provider.evolveAgent(
                            definition.id,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success
                                    ? '進化成功！${definition.name}${evo.nameSuffix}'
                                    : '資源不足'),
                                backgroundColor:
                                    success ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    disabledBackgroundColor: Colors.grey.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome, size: 16),
                      const SizedBox(width: 6),
                      Text(canEvolve ? '進化！' : '等級不足',
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Text(
                        '(${_costText()})',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _costText() {
    final parts = <String>[];
    if (evo.goldCost > 0) parts.add('${evo.goldCost}g');
    for (final entry in evo.materialCost.entries) {
      parts.add('${entry.key.emoji}${entry.value}');
    }
    return parts.join(' ');
  }
}

class _BonusChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _BonusChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
