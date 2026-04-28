import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/auto_eliminate_config.dart';
import '../../../core/models/block.dart';
import '../../agents/providers/player_provider.dart';
import '../providers/bottle_provider.dart';
import '../providers/idle_provider.dart';

/// 自動化設定面板（BottomSheet）
class AutoEliminateSettings extends StatelessWidget {
  const AutoEliminateSettings({super.key});

  static const _machineAsset =
      'assets/images/output/background/auto_settings_machine.png';

  @override
  Widget build(BuildContext context) {
    return Consumer2<IdleProvider, PlayerProvider>(
      builder: (context, idle, player, _) {
        final bp = context.watch<BottleProvider>();
        final config = idle.autoConfig;
        final progress = player.data.stageProgress;
        final harvestUnlocked =
            progress[AutoEliminateConfig.autoHarvestUnlockStage]?.cleared ??
                false;
        final eliminateUnlocked =
            config.unlockedStage.index >= AutoEliminateStage.stage2.index;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.accentSecondary.withAlpha(80),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _AutomationHero(
                  assetPath: _machineAsset,
                  isRunning: bp.autoHarvestEnabled || config.isAutoActive,
                ),
                const SizedBox(height: 16),
                _AutomationToggleCard(
                  icon: Icons.inventory_2_rounded,
                  title: '自動收成',
                  description: harvestUnlocked ? '瓶子達標後自動製作並售出' : '通關 1-5 解鎖',
                  isEnabled: harvestUnlocked && bp.autoHarvestEnabled,
                  isUnlocked: harvestUnlocked,
                  activeColor: const Color(0xFFFFB83D),
                  onChanged: harvestUnlocked ? bp.setAutoHarvest : null,
                ),
                const SizedBox(height: 10),
                _AutomationToggleCard(
                  icon: Icons.auto_awesome_rounded,
                  title: '自動消除',
                  description: eliminateUnlocked
                      ? '每 ${(config.intervalMs / 1000).toStringAsFixed(1)} 秒隨機消除 1 顆方塊'
                      : '通關 1-10 解鎖',
                  isEnabled: eliminateUnlocked && config.isEnabled,
                  isUnlocked: eliminateUnlocked,
                  activeColor: AppTheme.accentPrimary,
                  onChanged:
                      eliminateUnlocked ? idle.toggleAutoEliminate : null,
                ),
                const SizedBox(height: 16),
                const _SectionPanel(
                  title: '能量效率',
                  child: Column(
                    children: [
                      _EfficiencyRow(
                        label: '手動消除',
                        value: '100%',
                        color: Color(0xFF41B96D),
                      ),
                      _EfficiencyRow(
                        label: '自動觸發三消',
                        value: '50%',
                        color: Color(0xFFFFA53D),
                      ),
                      _EfficiencyRow(
                        label: '自動消除（單顆）',
                        value: '30%',
                        color: Color(0xFFE9625A),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildStageSection(config, player.data.playerLevel),
                if (eliminateUnlocked) ...[
                  const SizedBox(height: 12),
                  _buildIntervalSection(context, idle, config, player),
                ],
                if (config.unlockedStage == AutoEliminateStage.stage3) ...[
                  const SizedBox(height: 12),
                  _buildColorSection(idle, config),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStageSection(AutoEliminateConfig config, int playerLevel) {
    return _SectionPanel(
      title: '階段',
      child: Row(
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
            isUnlocked:
                config.unlockedStage.index >= AutoEliminateStage.stage2.index,
            isCurrent: config.unlockedStage == AutoEliminateStage.stage2,
            requiredLevel: AutoEliminateConfig
                .unlockLevelRequirements[AutoEliminateStage.stage2],
            playerLevel: playerLevel,
          ),
          const SizedBox(width: 8),
          _StageChip(
            label: 'Stage 3',
            subtitle: '指定顏色',
            isUnlocked:
                config.unlockedStage.index >= AutoEliminateStage.stage3.index,
            isCurrent: config.unlockedStage == AutoEliminateStage.stage3,
            requiredLevel: AutoEliminateConfig
                .unlockLevelRequirements[AutoEliminateStage.stage3],
            playerLevel: playerLevel,
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalSection(
    BuildContext context,
    IdleProvider idle,
    AutoEliminateConfig config,
    PlayerProvider player,
  ) {
    final isMax = config.isMaxIntervalLevel;
    final nextCost = config.nextUpgradeCost;
    final canAfford = !isMax && player.data.gold >= nextCost;

    return _SectionPanel(
      title: '消除週期',
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD08B), Color(0xFFFFA05A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentPrimary.withAlpha(55),
                  offset: const Offset(0, 4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              '${(config.intervalMs / 1000).toStringAsFixed(1)}s',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: AppTheme.fontTitleMd,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Lv.${config.intervalLevel} / '
            '${AutoEliminateConfig.intervalLevels.length - 1}',
            style: TextStyle(
              color: AppTheme.textSecondary.withAlpha(170),
              fontSize: AppTheme.fontBodyMd,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (isMax)
            const _MaxBadge()
          else
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
              icon: const Icon(Icons.monetization_on_rounded, size: 16),
              label: Text('$nextCost'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentSecondary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.textSecondary.withAlpha(20),
                disabledForegroundColor: AppTheme.textSecondary.withAlpha(95),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(0, 34),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildColorSection(IdleProvider idle, AutoEliminateConfig config) {
    return _SectionPanel(
      title: '目標顏色',
      subtitle: '優先消除指定顏色，不存在時消除備用顏色',
      child: Column(
        children: [
          _ColorPickerRow(
            label: '主要',
            selected: config.targetColor,
            onSelected: idle.setTargetColor,
          ),
          const SizedBox(height: 12),
          _ColorPickerRow(
            label: '備用',
            selected: config.fallbackColor,
            onSelected: idle.setFallbackColor,
          ),
        ],
      ),
    );
  }
}

class _AutomationHero extends StatelessWidget {
  final String assetPath;
  final bool isRunning;

  const _AutomationHero({
    required this.assetPath,
    required this.isRunning,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E8), Color(0xFFFFDFA6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withAlpha(210), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            offset: Offset(0, 8),
            blurRadius: 18,
          ),
          BoxShadow(
            color: Color(0x99FFFFFF),
            offset: Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            bottom: -34,
            child: Image.asset(
              assetPath,
              width: 225,
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 138, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '自動化設定',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: AppTheme.fontDisplayMd,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _StatusBadge(
                  label: isRunning ? '運轉中' : '待命',
                  color: isRunning
                      ? const Color(0xFF41B96D)
                      : AppTheme.textSecondary.withAlpha(150),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AutomationToggleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isEnabled;
  final bool isUnlocked;
  final Color activeColor;
  final ValueChanged<bool>? onChanged;

  const _AutomationToggleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.isEnabled,
    required this.isUnlocked,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isEnabled ? activeColor : AppTheme.textSecondary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled
              ? activeColor.withAlpha(115)
              : AppTheme.accentSecondary.withAlpha(35),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentSecondary.withAlpha(24),
            offset: const Offset(0, 5),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(isUnlocked ? 34 : 18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: iconColor.withAlpha(50)),
            ),
            child: Icon(
              isUnlocked ? icon : Icons.lock_rounded,
              color: iconColor.withAlpha(isUnlocked ? 255 : 120),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isUnlocked
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary.withAlpha(120),
                    fontSize: AppTheme.fontBodyLg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.textSecondary.withAlpha(150),
                    fontSize: AppTheme.fontLabelLg,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: isEnabled,
            onChanged: onChanged,
            activeThumbColor: activeColor,
            activeTrackColor: activeColor.withAlpha(80),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppTheme.textSecondary.withAlpha(45),
          ),
        ],
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _SectionPanel({
    required this.title,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1D5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(175)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentSecondary.withAlpha(18),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 5,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.accentPrimary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.fontBodyLg,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                color: AppTheme.textSecondary.withAlpha(140),
                fontSize: AppTheme.fontLabelLg,
              ),
            ),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withAlpha(80), blurRadius: 5),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary.withAlpha(190),
              fontSize: AppTheme.fontBodyMd,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: AppTheme.fontBodyMd,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

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
    final borderColor = isCurrent
        ? AppTheme.accentPrimary
        : isUnlocked
            ? AppTheme.accentSecondary.withAlpha(60)
            : AppTheme.textSecondary.withAlpha(28);

    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          gradient: isCurrent
              ? const LinearGradient(
                  colors: [Color(0xFFFFD8A8), Color(0xFFFFB36E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isCurrent
              ? null
              : isUnlocked
                  ? Colors.white.withAlpha(175)
                  : Colors.white.withAlpha(70),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: AppTheme.accentPrimary.withAlpha(45),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isUnlocked
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary.withAlpha(95),
                fontSize: AppTheme.fontLabelLg,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              isUnlocked ? subtitle : 'Lv.$requiredLevel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isUnlocked
                    ? AppTheme.textSecondary.withAlpha(165)
                    : AppTheme.textSecondary.withAlpha(95),
                fontSize: AppTheme.fontLabelSm,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!isUnlocked && requiredLevel != null && playerLevel != null)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 11,
                  color: AppTheme.textSecondary.withAlpha(80),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ColorPickerRow extends StatelessWidget {
  final String label;
  final BlockColor? selected;
  final ValueChanged<BlockColor> onSelected;

  const _ColorPickerRow({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 42,
          child: Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary.withAlpha(180),
              fontSize: AppTheme.fontBodyMd,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...BlockColor.values.map(
          (color) => Expanded(
            child: Center(
              child: _ColorCircle(
                color: color,
                isSelected: selected == color,
                onTap: () => onSelected(color),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

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
      child: AnimatedContainer(
        duration: AppTheme.animSwap,
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.color.withAlpha(isSelected ? 255 : 120),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withAlpha(70),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.color.withAlpha(isSelected ? 110 : 35),
              offset: const Offset(0, 3),
              blurRadius: isSelected ? 8 : 4,
            ),
          ],
        ),
        child: Center(
          child: Text(
            color.symbol,
            style: TextStyle(
              fontSize: AppTheme.fontLabelLg,
              color: Colors.white.withAlpha(isSelected ? 255 : 180),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(32),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(95)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
              color: color,
              fontSize: AppTheme.fontLabelLg,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _MaxBadge extends StatelessWidget {
  const _MaxBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF41B96D).withAlpha(34),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF41B96D).withAlpha(90)),
      ),
      child: const Text(
        'MAX',
        style: TextStyle(
          color: Color(0xFF2F9A57),
          fontSize: AppTheme.fontLabelLg,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
