import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/block.dart';
import '../../../core/models/auto_eliminate_config.dart';
import '../../agents/providers/player_provider.dart';
import '../providers/idle_provider.dart';

/// 自動消除設定面板（BottomSheet）
class AutoEliminateSettings extends StatelessWidget {
  const AutoEliminateSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<IdleProvider, PlayerProvider>(
      builder: (context, idle, player, _) {
        final config = idle.autoConfig;
        final playerLevel = player.data.playerLevel;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 標題
                const Center(
                  child: Text(
                    '自動消除設定',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 能量效率說明
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withAlpha(15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '能量效率對照',
                        style: TextStyle(
                          color: AppTheme.textPrimary.withAlpha(200),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _EfficiencyRow(label: '手動消除', value: '100%', color: Colors.greenAccent),
                      _EfficiencyRow(label: '自動觸發三消', value: '50%', color: Colors.orangeAccent),
                      _EfficiencyRow(label: '自動消除（單顆）', value: '30%', color: Colors.redAccent),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 階段解鎖
                _buildStageSection(config, playerLevel),
                const SizedBox(height: 16),

                // 週期升級
                _buildIntervalSection(context, idle, config, player),

                // Stage 3 顏色選擇
                if (config.unlockedStage == AutoEliminateStage.stage3) ...[
                  const SizedBox(height: 16),
                  _buildColorSection(idle, config),
                ],

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStageSection(AutoEliminateConfig config, int playerLevel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '階段',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _StageChip(
              label: 'Stage 1',
              subtitle: '手動',
              isUnlocked: true,
              isCurrent: config.unlockedStage == AutoEliminateStage.stage1,
            ),
            const SizedBox(width: 8),
            _StageChip(
              label: 'Stage 2',
              subtitle: '隨機消除',
              isUnlocked: config.unlockedStage.index >= AutoEliminateStage.stage2.index,
              isCurrent: config.unlockedStage == AutoEliminateStage.stage2,
              requiredLevel: AutoEliminateConfig.unlockLevelRequirements[AutoEliminateStage.stage2]!,
              playerLevel: playerLevel,
            ),
            const SizedBox(width: 8),
            _StageChip(
              label: 'Stage 3',
              subtitle: '指定顏色',
              isUnlocked: config.unlockedStage.index >= AutoEliminateStage.stage3.index,
              isCurrent: config.unlockedStage == AutoEliminateStage.stage3,
              requiredLevel: AutoEliminateConfig.unlockLevelRequirements[AutoEliminateStage.stage3]!,
              playerLevel: playerLevel,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIntervalSection(
    BuildContext context,
    IdleProvider idle,
    AutoEliminateConfig config,
    PlayerProvider player,
  ) {
    final isUnlocked =
        config.unlockedStage.index >= AutoEliminateStage.stage2.index;
    if (!isUnlocked) return const SizedBox.shrink();

    final currentMs = config.intervalMs;
    final currentLevel = config.intervalLevel;
    final isMax = config.isMaxIntervalLevel;
    final nextCost = config.nextUpgradeCost;
    final canAfford = !isMax && player.data.gold >= nextCost;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '消除週期',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // 當前週期
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accentPrimary.withAlpha(60),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${(currentMs / 1000).toStringAsFixed(1)}s',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 等級指示
            Text(
              'Lv.$currentLevel / ${AutoEliminateConfig.intervalLevels.length - 1}',
              style: TextStyle(
                color: AppTheme.textSecondary.withAlpha(150),
                fontSize: 12,
              ),
            ),
            const Spacer(),
            // 升級按鈕
            if (!isMax)
              ElevatedButton.icon(
                onPressed: canAfford
                    ? () {
                        final success = idle.upgradeInterval((cost) {
                          if (player.data.gold < cost) return false;
                          player.addGold(-cost);
                          return true;
                        });
                        if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('金幣不足')),
                          );
                        }
                      }
                    : null,
                icon: const Text('🪙', style: TextStyle(fontSize: 12)),
                label: Text(
                  '$nextCost',
                  style: const TextStyle(fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentSecondary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white.withAlpha(15),
                  disabledForegroundColor: AppTheme.textSecondary.withAlpha(80),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: const Size(0, 28),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'MAX',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorSection(IdleProvider idle, AutoEliminateConfig config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '目標顏色',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '優先消除指定顏色，不存在時消除備用顏色',
          style: TextStyle(
            color: AppTheme.textSecondary.withAlpha(120),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 8),

        // 主要顏色
        Row(
          children: [
            Text(
              '主要：',
              style: TextStyle(
                color: AppTheme.textSecondary.withAlpha(180),
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            ...BlockColor.values.map((color) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _ColorCircle(
                    color: color,
                    isSelected: config.targetColor == color,
                    onTap: () => idle.setTargetColor(color),
                  ),
                )),
          ],
        ),
        const SizedBox(height: 8),

        // 備用顏色
        Row(
          children: [
            Text(
              '備用：',
              style: TextStyle(
                color: AppTheme.textSecondary.withAlpha(180),
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            ...BlockColor.values.map((color) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _ColorCircle(
                    color: color,
                    isSelected: config.fallbackColor == color,
                    onTap: () => idle.setFallbackColor(color),
                  ),
                )),
          ],
        ),
      ],
    );
  }
}

/// 能量效率說明行
class _EfficiencyRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _EfficiencyRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary.withAlpha(180),
              fontSize: 11,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// 階段標籤
class _StageChip extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isUnlocked;
  final bool isCurrent;
  final int? requiredLevel;
  final int? playerLevel;

  const _StageChip({
    required this.label,
    required this.subtitle,
    required this.isUnlocked,
    required this.isCurrent,
    this.requiredLevel,
    this.playerLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppTheme.accentSecondary.withAlpha(40)
              : isUnlocked
                  ? AppTheme.accentPrimary.withAlpha(30)
                  : Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCurrent
                ? AppTheme.accentSecondary.withAlpha(100)
                : isUnlocked
                    ? AppTheme.accentPrimary.withAlpha(50)
                    : Colors.white.withAlpha(15),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isUnlocked ? AppTheme.textPrimary : AppTheme.textSecondary.withAlpha(100),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isUnlocked
                  ? subtitle
                  : 'Lv.$requiredLevel',
              style: TextStyle(
                color: isUnlocked
                    ? AppTheme.textSecondary.withAlpha(150)
                    : AppTheme.textSecondary.withAlpha(80),
                fontSize: 9,
              ),
            ),
            if (!isUnlocked && requiredLevel != null && playerLevel != null) ...[
              const SizedBox(height: 2),
              Icon(Icons.lock_outline, size: 10, color: AppTheme.textSecondary.withAlpha(60)),
            ],
          ],
        ),
      ),
    );
  }
}

/// 顏色選擇圓圈
class _ColorCircle extends StatelessWidget {
  final BlockColor color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorCircle({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.color.withAlpha(isSelected ? 255 : 80),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withAlpha(30),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.color.withAlpha(100), blurRadius: 6)]
              : null,
        ),
        child: Center(
          child: Text(
            color.symbol,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withAlpha(isSelected ? 255 : 120),
            ),
          ),
        ),
      ),
    );
  }
}
