import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/block.dart';
import '../../../core/models/auto_eliminate_config.dart';
import '../providers/idle_provider.dart';
import 'auto_eliminate_settings.dart';

/// 自動消除狀態列 — 顯示在棋盤上方
class AutoEliminateBar extends StatelessWidget {
  const AutoEliminateBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<IdleProvider>(
      builder: (context, idle, _) {
        final config = idle.autoConfig;
        final isUnlocked =
            config.unlockedStage.index >= AutoEliminateStage.stage2.index;

        return GestureDetector(
          onTap: () => _showSettings(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isUnlocked ? AppTheme.bgCard : AppTheme.bgCard.withAlpha(200),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: config.isAutoActive
                    ? AppTheme.accentSecondary
                    : Colors.white.withAlpha(15),
              ),
            ),
            child: isUnlocked
                ? _buildUnlockedContent(idle, config)
                : _buildLockedContent(config),
          ),
        );
      },
    );
  }

  Widget _buildLockedContent(AutoEliminateConfig config) {
    final requiredLevel =
        AutoEliminateConfig.unlockLevelRequirements[AutoEliminateStage.stage2]!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_outline, size: 11, color: AppTheme.textSecondary.withAlpha(100)),
        const SizedBox(width: 4),
        Text(
          'Lv.$requiredLevel 解鎖自動消除',
          style: TextStyle(
            color: AppTheme.textSecondary.withAlpha(100),
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _buildUnlockedContent(IdleProvider idle, AutoEliminateConfig config) {
    final stageLabel = config.unlockedStage == AutoEliminateStage.stage3
        ? 'S3'
        : 'S2';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 開關
        SizedBox(
          width: 28,
          height: 16,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Switch(
              value: config.isEnabled,
              onChanged: (v) => idle.toggleAutoEliminate(v),
              activeColor: AppTheme.accentSecondary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
        const SizedBox(width: 4),

        // 階段標籤
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: config.isAutoActive
                ? AppTheme.accentSecondary.withAlpha(60)
                : Colors.white.withAlpha(15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            stageLabel,
            style: TextStyle(
              color: config.isAutoActive
                  ? AppTheme.accentSecondary
                  : AppTheme.textSecondary.withAlpha(120),
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // 倒計時（僅啟用時顯示）
        if (config.isAutoActive) ...[
          const SizedBox(width: 4),
          _CountdownIndicator(
            countdownMs: idle.autoCountdownMs,
            totalMs: config.intervalMs,
          ),
        ],

        // Stage 3 目標顏色
        if (config.isAutoActive &&
            config.unlockedStage == AutoEliminateStage.stage3 &&
            config.targetColor != null) ...[
          const SizedBox(width: 4),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: config.targetColor!.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withAlpha(80), width: 1),
            ),
          ),
        ],

        // 設定齒輪
        const SizedBox(width: 4),
        Icon(Icons.settings, size: 11, color: AppTheme.textSecondary.withAlpha(100)),
      ],
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const AutoEliminateSettings(),
    );
  }
}

/// 環形倒計時指示器
class _CountdownIndicator extends StatelessWidget {
  final int countdownMs;
  final int totalMs;

  const _CountdownIndicator({
    required this.countdownMs,
    required this.totalMs,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalMs > 0 ? (1.0 - countdownMs / totalMs).clamp(0.0, 1.0) : 0.0;
    final seconds = (countdownMs / 1000).toStringAsFixed(1);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 2,
            backgroundColor: Colors.white.withAlpha(20),
            valueColor: const AlwaysStoppedAnimation(AppTheme.accentSecondary),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          '${seconds}s',
          style: TextStyle(
            color: AppTheme.textSecondary.withAlpha(150),
            fontSize: 8,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
