/// 角色解鎖動畫（寶可夢進化風格）
///
/// 動畫流程：
/// 1. 黑色橫幅展開
/// 2. 角色剪影（暗色輪廓）出現在中央
/// 3. 剪影開始發光、脈動
/// 4. 白色閃光爆發
/// 5. 剪影淡出 → 角色立繪顯現 + 粒子噴發
/// 6. 角色名稱 + 稀有度淡入
/// 7. 短暫停留後收合
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/image_assets.dart';
import '../../config/theme.dart';
import '../../core/models/cat_agent.dart';
import '../game/widgets/cat_placeholder.dart';

class AgentUnlockAnimation extends StatefulWidget {
  final CatAgentDefinition definition;
  final VoidCallback onComplete;

  const AgentUnlockAnimation({
    super.key,
    required this.definition,
    required this.onComplete,
  });

  @override
  State<AgentUnlockAnimation> createState() => _AgentUnlockAnimationState();
}

class _AgentUnlockAnimationState extends State<AgentUnlockAnimation>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _particleController;

  // 階段動畫
  late Animation<double> _bannerOpen;
  late Animation<double> _silhouetteAppear;
  late Animation<double> _silhouetteGlow;
  late Animation<double> _flashBurst;
  late Animation<double> _revealChar;
  late Animation<double> _textFade;
  late Animation<double> _bannerClose;
  late Animation<double> _pulseAnim;

  // 粒子
  late List<_UnlockParticle> _particles;

  @override
  void initState() {
    super.initState();

    // 主時間軸 3 秒
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    // 脈動（剪影階段使用）
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 粒子控制器
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Timeline:
    // 0%-8%:     黑色橫幅展開
    // 8%-22%:    剪影浮現
    // 18%-42%:   剪影發光 + 脈動
    // 42%-52%:   白色閃光爆發
    // 50%-70%:   角色立繪顯現 + 粒子噴射
    // 62%-78%:   名稱+稀有度淡入
    // 85%-100%:  橫幅收合

    _bannerOpen = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.08, curve: Curves.easeOut),
      ),
    );

    _silhouetteAppear = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.08, 0.22, curve: Curves.easeOut),
      ),
    );

    _silhouetteGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.18, 0.42, curve: Curves.easeIn),
      ),
    );

    _flashBurst = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 60),
    ]).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.42, 0.55, curve: Curves.easeOut),
      ),
    );

    _revealChar = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.50, 0.68, curve: Curves.easeOutCubic),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.62, 0.78, curve: Curves.easeIn),
      ),
    );

    _bannerClose = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.85, 1.0, curve: Curves.easeInCubic),
      ),
    );

    // 預生成粒子
    _particles = _generateParticles(30);

    _startSequence();
  }

  List<_UnlockParticle> _generateParticles(int count) {
    final rng = Random();
    return List.generate(count, (_) {
      final angle = rng.nextDouble() * 2 * pi;
      return _UnlockParticle(
        angle: angle,
        speed: 0.8 + rng.nextDouble() * 2.0,
        size: 3.0 + rng.nextDouble() * 6.0,
        cosA: cos(angle),
        sinA: sin(angle),
        hue: rng.nextDouble() * 60 - 30, // 偏移色相
      );
    });
  }

  Future<void> _startSequence() async {
    HapticFeedback.mediumImpact();

    _mainController.addListener(_checkPulseStart);
    _mainController.forward();

    // 在閃光時觸發重震動
    await Future.delayed(const Duration(milliseconds: 1350));
    if (mounted) HapticFeedback.heavyImpact();

    // 觸發粒子
    await Future.delayed(const Duration(milliseconds: 250));
    if (mounted) _particleController.forward();

    // 等主動畫完成
    await _mainController.forward().orCancel.catchError((_) {});
    if (mounted) widget.onComplete();
  }

  void _checkPulseStart() {
    // 在剪影發光階段啟動脈動
    if (_mainController.value >= 0.18 && _mainController.value < 0.42) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else if (_mainController.value >= 0.42) {
      if (_pulseController.isAnimating) {
        _pulseController.stop();
        _pulseController.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _mainController.removeListener(_checkPulseStart);
    _mainController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bannerHeight = screenSize.height * 0.45;
    final charSize = bannerHeight * 0.55;
    final attrColor = widget.definition.attribute.blockColor.color;
    final charPath = ImageAssets.characterImage(widget.definition.id);

    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _pulseController, _particleController]),
      builder: (context, _) {
        final bannerScale = _mainController.value < 0.85
            ? _bannerOpen.value
            : _bannerClose.value;

        if (bannerScale <= 0.01) return const SizedBox.shrink();

        // 判斷目前階段
        final showSilhouette = _silhouetteAppear.value > 0 && _revealChar.value < 1.0;
        final showChar = _revealChar.value > 0;
        final showFlash = _flashBurst.value > 0.01;

        return Stack(
          children: [
            // 全畫面暗幕
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black.withAlpha((bannerScale * 180).round()),
                ),
              ),
            ),

            // 中央橫幅
            Center(
              child: ClipRect(
                child: Align(
                  alignment: Alignment.center,
                  heightFactor: bannerScale.clamp(0.0, 1.0),
                  child: Container(
                    width: screenSize.width,
                    height: bannerHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(0),
                          Colors.black.withAlpha(230),
                          Colors.black.withAlpha(250),
                          Colors.black.withAlpha(230),
                          Colors.black.withAlpha(0),
                        ],
                        stops: const [0.0, 0.1, 0.5, 0.9, 1.0],
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        // 上下彩色裝飾線
                        Positioned(
                          top: bannerHeight * 0.08,
                          left: 0, right: 0,
                          child: Container(height: 2, color: attrColor.withAlpha(150)),
                        ),
                        Positioned(
                          bottom: bannerHeight * 0.08,
                          left: 0, right: 0,
                          child: Container(height: 2, color: attrColor.withAlpha(150)),
                        ),

                        // ── 剪影（暗色輪廓） ──
                        if (showSilhouette)
                          Transform.scale(
                            scale: _pulseAnim.value,
                            child: Opacity(
                              opacity: _silhouetteAppear.value * (1.0 - _revealChar.value),
                              child: _SilhouetteImage(
                                charPath: charPath,
                                attrColor: attrColor,
                                size: charSize,
                                glowIntensity: _silhouetteGlow.value,
                                definition: widget.definition,
                              ),
                            ),
                          ),

                        // ── 粒子噴發 ──
                        if (_particleController.value > 0)
                          CustomPaint(
                            size: Size(screenSize.width, bannerHeight),
                            painter: _ParticleBurstPainter(
                              progress: _particleController.value,
                              particles: _particles,
                              color: attrColor,
                              center: Offset(screenSize.width / 2, bannerHeight / 2),
                              maxRadius: charSize * 1.5,
                            ),
                          ),

                        // ── 白色閃光爆發 ──
                        if (showFlash)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    radius: 0.8,
                                    colors: [
                                      Colors.white.withAlpha((_flashBurst.value * 255).round()),
                                      attrColor.withAlpha((_flashBurst.value * 150).round()),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.4, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // ── 角色立繪顯現 ──
                        if (showChar)
                          Transform.scale(
                            scale: 0.6 + _revealChar.value * 0.4,
                            child: Opacity(
                              opacity: _revealChar.value,
                              child: SizedBox(
                                width: charSize,
                                height: charSize,
                                child: charPath != null
                                    ? Image.asset(
                                        charPath,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) =>
                                            CatPlaceholder(
                                          color: attrColor,
                                          size: charSize,
                                        ),
                                      )
                                    : CatPlaceholder(
                                        color: attrColor,
                                        size: charSize,
                                      ),
                              ),
                            ),
                          ),

                        // ── 角色名稱 + 稀有度 ──
                        Positioned(
                          bottom: bannerHeight * 0.12,
                          left: 0, right: 0,
                          child: Opacity(
                            opacity: _textFade.value,
                            child: Column(
                              children: [
                                // 「新特工加入」
                                Text(
                                  '— 新特工加入 —',
                                  style: TextStyle(
                                    color: attrColor.withAlpha(200),
                                    fontSize: 12,
                                    letterSpacing: 4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                // 角色名
                                Text(
                                  widget.definition.name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 4,
                                    shadows: [
                                      Shadow(color: attrColor.withAlpha(200), blurRadius: 12),
                                      const Shadow(color: Colors.black, blurRadius: 4),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                // 代號 + 稀有度
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      widget.definition.codename,
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _buildRarityBadge(),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 點擊跳過
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  if (_mainController.value > 0.6) {
                    _mainController.value = 0.84;
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRarityBadge() {
    final rarity = widget.definition.rarity;
    final colors = [
      Colors.grey.shade400,
      Colors.blue.shade300,
      Colors.purple.shade300,
      Colors.amber.shade400,
    ];
    final color = colors[rarity.tier - 1];
    final stars = List.generate(
      rarity.tier,
      (_) => Icon(Icons.star, color: color, size: 12),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: color.withAlpha(40),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withAlpha(100)),
          ),
          child: Text(
            rarity.display,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 4),
        ...stars,
      ],
    );
  }
}

// ═══════════════════════════════════════════
// 剪影 Widget（暗色輪廓 + 邊緣發光）
// ═══════════════════════════════════════════

class _SilhouetteImage extends StatelessWidget {
  final String? charPath;
  final Color attrColor;
  final double size;
  final double glowIntensity;
  final CatAgentDefinition definition;

  const _SilhouetteImage({
    required this.charPath,
    required this.attrColor,
    required this.size,
    required this.glowIntensity,
    required this.definition,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 外部發光
          if (glowIntensity > 0)
            Container(
              width: size * (1.0 + glowIntensity * 0.3),
              height: size * (1.0 + glowIntensity * 0.3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: attrColor.withAlpha((glowIntensity * 120).round()),
                    blurRadius: 30 * glowIntensity,
                    spreadRadius: 10 * glowIntensity,
                  ),
                ],
              ),
            ),
          // 剪影（用 ColorFiltered 把圖片變成暗色輪廓）
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Color.lerp(
                const Color(0xFF0A0A15),
                attrColor,
                glowIntensity * 0.4,
              )!,
              BlendMode.srcATop,
            ),
            child: charPath != null
                ? Image.asset(
                    charPath!,
                    width: size * 0.85,
                    height: size * 0.85,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => CatPlaceholder(
                      color: const Color(0xFF0A0A15),
                      size: size * 0.85,
                    ),
                  )
                : CatPlaceholder(
                    color: const Color(0xFF0A0A15),
                    size: size * 0.85,
                  ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 粒子噴發 Painter
// ═══════════════════════════════════════════

class _ParticleBurstPainter extends CustomPainter {
  final double progress;
  final List<_UnlockParticle> particles;
  final Color color;
  final Offset center;
  final double maxRadius;

  _ParticleBurstPainter({
    required this.progress,
    required this.particles,
    required this.color,
    required this.center,
    required this.maxRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final t = progress;
    final alpha = ((1.0 - t) * 255).round().clamp(0, 255);
    if (alpha <= 0) return;

    for (final p in particles) {
      final dist = maxRadius * t * p.speed;
      final px = center.dx + p.cosA * dist;
      final py = center.dy + p.sinA * dist;
      final r = p.size * (1.0 - t * 0.6);

      if (r <= 0) continue;

      // 根據粒子色相偏移產生多彩效果
      final hsl = HSLColor.fromColor(color);
      final particleColor = hsl
          .withHue((hsl.hue + p.hue) % 360)
          .withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0))
          .toColor()
          .withAlpha(alpha);

      final paint = Paint()..color = particleColor;

      // 繪製菱形粒子（更有寶可夢感）
      final path = Path()
        ..moveTo(px, py - r)
        ..lineTo(px + r * 0.6, py)
        ..lineTo(px, py + r)
        ..lineTo(px - r * 0.6, py)
        ..close();
      canvas.drawPath(path, paint);

      // 小光暈
      if (r > 3) {
        final glowPaint = Paint()
          ..color = particleColor.withAlpha((alpha * 0.3).round())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(Offset(px, py), r * 0.8, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_ParticleBurstPainter old) => old.progress != progress;
}

/// 粒子資料
class _UnlockParticle {
  final double angle;
  final double speed;
  final double size;
  final double cosA;
  final double sinA;
  final double hue;

  const _UnlockParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.cosA,
    required this.sinA,
    required this.hue,
  });
}
