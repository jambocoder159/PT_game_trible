import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/cat_data.dart';
import '../../agents/providers/player_provider.dart';
import '../providers/cat_provider.dart';

/// 右側貓咪面板 — 5 隻貓咪的飽食度 + 收穫按鈕
class CatPanel extends StatelessWidget {
  const CatPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<CatProvider, PlayerProvider>(
      builder: (context, catProvider, playerProvider, _) {
        if (!catProvider.isInitialized || !playerProvider.isInitialized) {
          return const SizedBox.shrink();
        }

        final playerLevel = playerProvider.data.playerLevel;

        return Column(
          children: CatDefinitions.all.map((def) {
            final cat = catProvider.cats[def.id];
            if (cat == null) return const SizedBox.shrink();
            return Expanded(
              child: _CatCard(
                definition: def,
                status: cat,
                playerLevel: playerLevel,
                onCollect: cat.isFull(playerLevel)
                    ? () => _collectReward(context, catProvider, def.id, playerLevel)
                    : null,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _collectReward(
    BuildContext context,
    CatProvider catProvider,
    String catId,
    int playerLevel,
  ) {
    final def = CatDefinitions.getById(catId);
    if (def == null) return;

    final reward = catProvider.collectReward(catId, playerLevel);
    if (reward == null) return;

    // 獎勵金幣加到玩家
    final player = context.read<PlayerProvider>();
    player.addGold(reward.quantity);

    // 震動回饋
    HapticFeedback.heavyImpact();

    // 顯示開寶箱動畫彈窗
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => _RewardDialog(
        catDef: def,
        reward: reward,
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 收穫獎勵彈窗 — 開寶箱動畫
// ═══════════════════════════════════════════

class _RewardDialog extends StatefulWidget {
  final CatDefinition catDef;
  final CatReward reward;

  const _RewardDialog({required this.catDef, required this.reward});

  @override
  State<_RewardDialog> createState() => _RewardDialogState();
}

class _RewardDialogState extends State<_RewardDialog>
    with TickerProviderStateMixin {
  // 階段: 0=寶箱搖晃, 1=打開爆發, 2=顯示獎勵
  int _phase = 0;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;

  late AnimationController _burstController;
  late Animation<double> _burstScale;
  late Animation<double> _burstOpacity;

  late AnimationController _rewardController;
  late Animation<double> _rewardScale;
  late Animation<double> _rewardOpacity;

  // 粒子
  late List<_SparkleParticle> _particles;

  @override
  void initState() {
    super.initState();

    // 搖晃動畫
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 10),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 8, end: -10), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 10, end: -12), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -12, end: 12), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 12, end: 0), weight: 15),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));

    // 爆發動畫
    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _burstScale = Tween<double>(begin: 0.5, end: 2.5).animate(
      CurvedAnimation(parent: _burstController, curve: Curves.easeOut),
    );
    _burstOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _burstController, curve: Curves.easeIn),
    );

    // 獎勵顯示動畫
    _rewardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _rewardScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rewardController, curve: Curves.elasticOut),
    );
    _rewardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _rewardController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // 生成粒子
    _particles = _generateParticles();

    // 啟動動畫序列
    _startAnimation();
  }

  List<_SparkleParticle> _generateParticles() {
    final rng = Random();
    final color = widget.catDef.color.color;
    return List.generate(16, (i) {
      final angle = (i / 16) * 2 * pi + rng.nextDouble() * 0.4;
      return _SparkleParticle(
        angle: angle,
        speed: 0.8 + rng.nextDouble() * 1.5,
        size: 3.0 + rng.nextDouble() * 4.0,
        color: Color.lerp(color, Colors.white, rng.nextDouble() * 0.5)!,
      );
    });
  }

  Future<void> _startAnimation() async {
    // Phase 0: 搖晃
    await _shakeController.forward();
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));

    // Phase 1: 爆發
    setState(() => _phase = 1);
    HapticFeedback.heavyImpact();
    _burstController.forward();
    await Future.delayed(const Duration(milliseconds: 300));

    // Phase 2: 顯示獎勵
    setState(() => _phase = 2);
    _rewardController.forward();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _burstController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catColor = widget.catDef.color.color;
    final rarityColor = _rarityColor(widget.reward.rarity);
    final rarityLabel = _rarityLabel(widget.reward.rarity);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 寶箱 + 爆發效果
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 爆發光環
                if (_phase >= 1)
                  AnimatedBuilder(
                    animation: _burstController,
                    builder: (_, __) => Opacity(
                      opacity: _burstOpacity.value,
                      child: Transform.scale(
                        scale: _burstScale.value,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                catColor.withAlpha(200),
                                catColor.withAlpha(0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // 粒子
                if (_phase >= 1)
                  AnimatedBuilder(
                    animation: _burstController,
                    builder: (_, __) => CustomPaint(
                      size: const Size(200, 200),
                      painter: _SparklePainter(
                        progress: _burstController.value,
                        particles: _particles,
                        maxRadius: 90,
                      ),
                    ),
                  ),

                // 寶箱 emoji
                if (_phase == 0)
                  AnimatedBuilder(
                    animation: _shakeAnim,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(_shakeAnim.value, 0),
                      child: child,
                    ),
                    child: Text(
                      '🎁',
                      style: TextStyle(fontSize: 64, shadows: [
                        Shadow(
                          color: catColor.withAlpha(150),
                          blurRadius: 20,
                        ),
                      ]),
                    ),
                  ),

                // 打開的寶箱
                if (_phase >= 1 && _phase < 2)
                  Text(
                    '✨',
                    style: TextStyle(fontSize: 64, shadows: [
                      Shadow(
                        color: catColor.withAlpha(200),
                        blurRadius: 30,
                      ),
                    ]),
                  ),
              ],
            ),
          ),

          // 獎勵卡片
          if (_phase >= 2)
            AnimatedBuilder(
              animation: _rewardController,
              builder: (_, child) => Opacity(
                opacity: _rewardOpacity.value,
                child: Transform.scale(
                  scale: _rewardScale.value,
                  child: child,
                ),
              ),
              child: Container(
                width: 220,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: rarityColor.withAlpha(180), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: rarityColor.withAlpha(60),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 貓咪名稱
                    Text(
                      '${widget.catDef.emoji} ${widget.catDef.name}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 稀有度標籤
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: rarityColor.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: rarityColor.withAlpha(100)),
                      ),
                      child: Text(
                        rarityLabel,
                        style: TextStyle(
                          color: rarityColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 獎勵內容
                    Text(
                      widget.reward.name,
                      style: TextStyle(
                        color: rarityColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 4),
                        Text(
                          '+${widget.reward.quantity}',
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 關閉按鈕
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: rarityColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          '太棒了！',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _rarityColor(int rarity) {
    switch (rarity) {
      case 3:
        return const Color(0xFFBF6FFF); // 紫色 - 稀有
      case 2:
        return const Color(0xFF4FAAFF); // 藍色 - 進階
      default:
        return const Color(0xFFAABBCC); // 灰藍 - 普通
    }
  }

  String _rarityLabel(int rarity) {
    switch (rarity) {
      case 3:
        return '★★★ 稀有';
      case 2:
        return '★★ 進階';
      default:
        return '★ 普通';
    }
  }
}

// ═══════════════════════════════════════════
// 粒子系統
// ═══════════════════════════════════════════

class _SparkleParticle {
  final double angle;
  final double speed;
  final double size;
  final Color color;

  const _SparkleParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });
}

class _SparklePainter extends CustomPainter {
  final double progress;
  final List<_SparkleParticle> particles;
  final double maxRadius;

  const _SparklePainter({
    required this.progress,
    required this.particles,
    required this.maxRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.05) return;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final t = progress;
    final alpha = ((1.0 - t) * 255).round().clamp(0, 255);
    if (alpha <= 0) return;

    for (final p in particles) {
      final dist = maxRadius * t * p.speed;
      final px = cx + cos(p.angle) * dist;
      final py = cy + sin(p.angle) * dist;
      final r = p.size * (1.0 - t * 0.6);

      if (r <= 0) continue;

      final paint = Paint()
        ..color = p.color.withAlpha(alpha)
        ..style = PaintingStyle.fill;

      // 星形粒子（小菱形）
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(px, py), width: r * 2, height: r * 2),
          Radius.circular(r * 0.3),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.progress != progress;
}

// ═══════════════════════════════════════════
// 貓咪卡片（含飽食脈衝動畫）
// ═══════════════════════════════════════════

class _CatCard extends StatefulWidget {
  final CatDefinition definition;
  final CatStatus status;
  final int playerLevel;
  final VoidCallback? onCollect;

  const _CatCard({
    required this.definition,
    required this.status,
    required this.playerLevel,
    this.onCollect,
  });

  @override
  State<_CatCard> createState() => _CatCardState();
}

class _CatCardState extends State<_CatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.status.isFull(widget.playerLevel)) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _CatCard old) {
    super.didUpdateWidget(old);
    final isFull = widget.status.isFull(widget.playerLevel);
    if (isFull && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!isFull && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.status.progress(widget.playerLevel);
    final isFull = widget.status.isFull(widget.playerLevel);
    final blockColor = widget.definition.color.color;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) {
        final glowAlpha = isFull ? (60 + (_pulseAnim.value * 80)).round() : 0;
        final borderWidth = isFull ? 1.5 + _pulseAnim.value * 0.5 : 0.0;
        final emojiScale = isFull ? 1.0 + _pulseAnim.value * 0.15 : 1.0;

        return GestureDetector(
          onTap: isFull ? widget.onCollect : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.bgCard.withAlpha(isFull ? 220 : 140),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: isFull
                  ? Border.all(
                      color: blockColor.withAlpha(180),
                      width: borderWidth,
                    )
                  : null,
              boxShadow: isFull
                  ? [
                      BoxShadow(
                        color: blockColor.withAlpha(glowAlpha),
                        blurRadius: 8 + _pulseAnim.value * 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 貓咪 emoji + 名稱
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scale: emojiScale,
                      child: Text(
                        widget.definition.emoji,
                        style: TextStyle(fontSize: isFull ? 18 : 14),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        widget.definition.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),

                // 飽食度進度條
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: Colors.white.withAlpha(20),
                    valueColor: AlwaysStoppedAnimation(
                      isFull ? blockColor : blockColor.withAlpha(180),
                    ),
                  ),
                ),

                // 數值
                Text(
                  '${widget.status.currentFood}/${widget.status.maxFood(widget.playerLevel)}',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withAlpha(150),
                    fontSize: 8,
                  ),
                ),

                // 收穫按鈕（吃飽時顯示）
                if (isFull)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [blockColor, blockColor.withAlpha(180)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: blockColor.withAlpha(80 + glowAlpha ~/ 2),
                          blurRadius: 4 + _pulseAnim.value * 4,
                        ),
                      ],
                    ),
                    child: const Text(
                      '開啟',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
