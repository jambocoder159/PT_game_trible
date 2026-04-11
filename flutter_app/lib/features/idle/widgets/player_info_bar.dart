import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../agents/providers/player_provider.dart';

/// 頂部玩家資訊列（單行版）
/// 左：等級徽章 + 體力  |  右：金幣 + 鑽石 + 任務/數據/設置按鈕
class PlayerInfoBar extends StatelessWidget {
  final VoidCallback? onSettings;
  final VoidCallback? onStats;
  final VoidCallback? onDailyQuest;

  const PlayerInfoBar({
    super.key,
    this.onSettings,
    this.onStats,
    this.onDailyQuest,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (_, provider, __) {
        if (!provider.isInitialized) return const SizedBox.shrink();

        final data = provider.data;

        // 計算紅點：任務有可領取獎勵
        bool hasQuestReward = false;
        if (data.tutorialCompleted) {
          provider.refreshNewbieQuests();
          final nq = data.newbieQuests;
          final dq = data.dailyQuests;
          hasQuestReward = _nextQuestIds.any(
                (id) => nq.isCompleted(id) && !nq.isClaimed(id),
              ) ||
              (dq.allCompleted && !dq.rewardsClaimed);
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: AppTheme.accentSecondary.withAlpha(50),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // ── 等級徽章 ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.accentPrimary, AppTheme.accentSecondary],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Lv.${data.playerLevel}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppTheme.fontBodyLg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // ── 體力 ──
              _StaminaDisplay(
                stamina: data.stamina,
                maxStamina: data.maxStamina,
                lastRecover: data.lastStaminaRecover,
              ),

              const Spacer(),

              // ── 金幣 ──
              _AnimatedCurrencyChip(icon: '🪙', value: data.gold),
              const SizedBox(width: 6),

              // ── 鑽石 ──
              _AnimatedCurrencyChip(icon: '💎', value: data.diamonds),

              const SizedBox(width: 8),

              // ── 分隔線 ──
              Container(
                width: 1,
                height: 18,
                color: AppTheme.accentSecondary.withAlpha(40),
              ),

              const SizedBox(width: 4),

              // ── 任務（帶紅點） ──
              _HeaderIconButton(
                icon: Icons.task_alt_rounded,
                onTap: onDailyQuest,
                showBadge: hasQuestReward,
              ),

              // ── 數據 ──
              _HeaderIconButton(
                icon: Icons.bar_chart_rounded,
                onTap: onStats,
              ),

              // ── 設置 ──
              _HeaderIconButton(
                icon: Icons.settings_rounded,
                onTap: onSettings,
              ),
            ],
          ),
        );
      },
    );
  }
}

// 新手任務 ID（用於紅點判斷）
const _nextQuestIds = [
  'tutorial',
  'unlock_agent',
  'clear_1_3',
  'full_team',
  'reach_lv5',
  'eliminate_500',
  'daily_all',
];

/// 體力顯示：⚡ 45/60（滿時脈動）
class _StaminaDisplay extends StatelessWidget {
  final int stamina;
  final int maxStamina;
  final DateTime lastRecover;

  const _StaminaDisplay({
    required this.stamina,
    required this.maxStamina,
    required this.lastRecover,
  });

  @override
  Widget build(BuildContext context) {
    final isFull = stamina >= maxStamina;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('⚡', style: TextStyle(fontSize: AppTheme.fontBodyLg)),
        const SizedBox(width: 2),
        Text(
          '$stamina/$maxStamina',
          style: TextStyle(
            color: isFull ? AppTheme.accentPrimary : AppTheme.textPrimary,
            fontSize: AppTheme.fontBodyMd,
            fontWeight: FontWeight.bold,
          ),
        ),
        // 未滿時顯示下一點恢復倒數
        if (!isFull) _StaminaTimer(lastRecover: lastRecover),
      ],
    );
  }
}

/// 體力恢復倒數計時器
class _StaminaTimer extends StatefulWidget {
  final DateTime lastRecover;
  const _StaminaTimer({required this.lastRecover});

  @override
  State<_StaminaTimer> createState() => _StaminaTimerState();
}

class _StaminaTimerState extends State<_StaminaTimer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 每 8 分鐘恢復 1 點
    const recoverSeconds = 8 * 60;
    final elapsed = DateTime.now().difference(widget.lastRecover).inSeconds;
    final remaining = recoverSeconds - (elapsed % recoverSeconds);
    final min = remaining ~/ 60;
    final sec = remaining % 60;

    return Padding(
      padding: const EdgeInsets.only(left: 3),
      child: Text(
        '$min:${sec.toString().padLeft(2, '0')}',
        style: TextStyle(
          color: AppTheme.textSecondary.withAlpha(150),
          fontSize: AppTheme.fontLabelSm,
        ),
      ),
    );
  }
}

/// Header 小按鈕（icon only，可帶紅點）
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool showBadge;

  const _HeaderIconButton({
    required this.icon,
    this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              icon,
              color: AppTheme.textSecondary,
              size: 20,
            ),
            if (showBadge)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5252),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 帶計數器跳動動畫的貨幣顯示
class _AnimatedCurrencyChip extends StatefulWidget {
  final String icon;
  final int value;

  const _AnimatedCurrencyChip({required this.icon, required this.value});

  @override
  State<_AnimatedCurrencyChip> createState() => _AnimatedCurrencyChipState();
}

class _AnimatedCurrencyChipState extends State<_AnimatedCurrencyChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _countAnim;
  late Animation<double> _scaleAnim;
  int _prevValue = 0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _prevValue = widget.value;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _countAnim = Tween<double>(
      begin: widget.value.toDouble(),
      end: widget.value.toDouble(),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 15),
      TweenSequenceItem(
          tween: Tween(begin: 1.3, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 85),
    ]).animate(_ctrl);
  }

  @override
  void didUpdateWidget(_AnimatedCurrencyChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final diff = widget.value - oldWidget.value;
      if (diff > 0) {
        _prevValue = oldWidget.value;
        _countAnim = Tween<double>(
          begin: _prevValue.toDouble(),
          end: widget.value.toDouble(),
        ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
        _ctrl.reset();
        _ctrl.forward();
        _isAnimating = true;
        _ctrl.addStatusListener(_onAnimEnd);
      } else {
        _prevValue = widget.value;
      }
    }
  }

  void _onAnimEnd(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _isAnimating = false;
      _ctrl.removeStatusListener(_onAnimEnd);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final displayValue =
            _isAnimating ? _countAnim.value.toInt() : widget.value;
        final scale = _isAnimating ? _scaleAnim.value : 1.0;
        final color = _isAnimating
            ? Color.lerp(
                const Color(0xFFFFD43B), AppTheme.textPrimary, _ctrl.value)!
            : AppTheme.textPrimary;

        return Transform.scale(
          scale: scale,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.icon,
                  style: const TextStyle(fontSize: AppTheme.fontBodyMd)),
              const SizedBox(width: 2),
              Text(
                _formatNumber(displayValue),
                style: TextStyle(
                  color: color,
                  fontSize: AppTheme.fontBodyMd,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}
