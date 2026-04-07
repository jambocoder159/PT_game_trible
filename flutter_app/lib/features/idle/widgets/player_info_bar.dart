import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../agents/providers/player_provider.dart';

/// 頂部玩家資訊列 — 名稱、等級、經驗條、金幣、鑽石
class PlayerInfoBar extends StatelessWidget {
  const PlayerInfoBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (_, provider, __) {
        if (!provider.isInitialized) return const SizedBox.shrink();

        final data = provider.data;
        final expNeeded = data.playerLevel * 100;
        final expProgress = expNeeded > 0
            ? (data.playerExp / expNeeded).clamp(0.0, 1.0)
            : 0.0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: AppTheme.accentPrimary.withAlpha(60),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 第一行：等級 + 貨幣
              Row(
                children: [
                  // 等級徽章
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.accentPrimary, AppTheme.accentSecondary],
                      ),
                      borderRadius: BorderRadius.circular(12),
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

                  // 經驗條
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: expProgress,
                            minHeight: 6,
                            backgroundColor: AppTheme.bgSecondary,
                            valueColor: const AlwaysStoppedAnimation(
                              AppTheme.accentSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${data.playerExp}/$expNeeded',
                          style: TextStyle(
                            color: AppTheme.textSecondary.withAlpha(150),
                            fontSize: AppTheme.fontLabelSm,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // 金幣（帶計數器動畫）
                  _AnimatedCurrencyChip(icon: '🪙', value: data.gold),
                  const SizedBox(width: 8),

                  // 鑽石
                  _AnimatedCurrencyChip(icon: '💎', value: data.diamonds),
                ],
              ),
            ],
          ),
        );
      },
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
    // 數值跳動時的縮放彈跳
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0)
          .chain(CurveTween(curve: Curves.elasticOut)), weight: 85),
    ]).animate(_ctrl);
  }

  @override
  void didUpdateWidget(_AnimatedCurrencyChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final diff = widget.value - oldWidget.value;
      // 只對增加做動畫（收成），減少直接跳轉
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
        final displayValue = _isAnimating
            ? _countAnim.value.toInt()
            : widget.value;
        final scale = _isAnimating ? _scaleAnim.value : 1.0;
        final color = _isAnimating
            ? Color.lerp(const Color(0xFFFFD43B), AppTheme.textPrimary, _ctrl.value)!
            : AppTheme.textPrimary;

        return Transform.scale(
          scale: scale,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.icon, style: const TextStyle(fontSize: AppTheme.fontBodyLg)),
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
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}
