/// 角色進化動畫（寶可夢剪影進化風格）
///
/// 動畫流程：
/// 1. 全畫面暗幕 + 橫幅展開
/// 2. 進化前角色立繪顯示
/// 3. 角色縮小 → 變為暗色剪影（輪廓發光）
/// 4. 剪影脈動 + 閃爍 + 放大
/// 5. 白色閃光爆發
/// 6. 進化後角色立繪顯現 + 粒子噴發
/// 7. 新名稱 + 進化階段淡入
/// 8. 短暫停留後收合
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/image_assets.dart';
import '../../../config/theme.dart';
import '../../../core/models/cat_agent.dart';
import '../../game/widgets/cat_placeholder.dart';

class AgentEvolutionAnimation extends StatefulWidget {
  final CatAgentDefinition definition;
  final int fromStage;
  final int toStage;
  final String newDisplayName;
  final VoidCallback onComplete;

  const AgentEvolutionAnimation({
    super.key,
    required this.definition,
    required this.fromStage,
    required this.toStage,
    required this.newDisplayName,
    required this.onComplete,
  });

  @override
  State<AgentEvolutionAnimation> createState() =>
      _AgentEvolutionAnimationState();
}

class _AgentEvolutionAnimationState extends State<AgentEvolutionAnimation>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _particleController;

  // 階段動畫
  late Animation<double> _bannerOpen;
  late Animation<double> _showOldChar;
  late Animation<double> _shrinkToSilhouette;
  late Animation<double> _silhouetteGlow;
  late Animation<double> _flashBurst;
  late Animation<double> _revealNewChar;
  late Animation<double> _textFade;
  late Animation<double> _bannerClose;
  late Animation<double> _pulseAnim;

  // 粒子
  late List<_EvoParticle> _particles;

  @override
  void initState() {
    super.initState();

    // 主時間軸 4.5 秒（比解鎖動畫長，更有進化感）
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );

    // 脈動
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 粒子控制器
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Timeline (4500ms):
    // 0%-5%:     黑色橫幅展開
    // 5%-15%:    進化前角色顯示
    // 15%-30%:   角色縮小變為剪影
    // 30%-55%:   剪影發光 + 脈動 + 閃爍
    // 55%-65%:   白色閃光爆發
    // 62%-78%:   進化後角色顯現 + 粒子噴射
    // 72%-85%:   名稱+進化階段淡入
    // 90%-100%:  橫幅收合

    _bannerOpen = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.05, curve: Curves.easeOut),
      ),
    );

    _showOldChar = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 50),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
    ]).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.05, 0.15),
      ),
    );

    _shrinkToSilhouette = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.15, 0.30, curve: Curves.easeInOut),
      ),
    );

    _silhouetteGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.30, 0.55, curve: Curves.easeIn),
      ),
    );

    _flashBurst = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 65),
    ]).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.55, 0.68, curve: Curves.easeOut),
      ),
    );

    _revealNewChar = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.62, 0.78, curve: Curves.easeOutCubic),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.72, 0.85, curve: Curves.easeIn),
      ),
    );

    _bannerClose = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.90, 1.0, curve: Curves.easeInCubic),
      ),
    );

    _particles = _generateParticles(40);

    _startSequence();
  }

  List<_EvoParticle> _generateParticles(int count) {
    final rng = Random();
    return List.generate(count, (_) {
      final angle = rng.nextDouble() * 2 * pi;
      return _EvoParticle(
        angle: angle,
        speed: 0.6 + rng.nextDouble() * 2.4,
        size: 3.0 + rng.nextDouble() * 7.0,
        cosA: cos(angle),
        sinA: sin(angle),
        hue: rng.nextDouble() * 80 - 40,
      );
    });
  }

  Future<void> _startSequence() async {
    HapticFeedback.mediumImpact();

    _mainController.addListener(_checkPulseStart);
    _mainController.forward();

    // 剪影脈動階段 — 中震動
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) HapticFeedback.mediumImpact();

    // 閃光爆發 — 重震動
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) HapticFeedback.heavyImpact();

    // 粒子噴射
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) _particleController.forward();

    // 等主動畫完成
    await _mainController.forward().orCancel.catchError((_) {});
    if (mounted) widget.onComplete();
  }

  void _checkPulseStart() {
    if (_mainController.value >= 0.30 && _mainController.value < 0.55) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
    } else if (_mainController.value >= 0.55) {
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
    final bannerHeight = screenSize.height * 0.50;
    final charSize = bannerHeight * 0.50;
    final attrColor = widget.definition.attribute.blockColor.color;

    final oldCharPath = ImageAssets.characterImage(
      widget.definition.id,
      evolutionStage: widget.fromStage,
    );
    final newCharPath = ImageAssets.characterImage(
      widget.definition.id,
      evolutionStage: widget.toStage,
    );

    return AnimatedBuilder(
      animation: Listenable.merge(
          [_mainController, _pulseController, _particleController]),
      builder: (context, _) {
        final bannerScale = _mainController.value < 0.90
            ? _bannerOpen.value
            : _bannerClose.value;

        if (bannerScale <= 0.01) return const SizedBox.shrink();

        final showOld = _showOldChar.value > 0 && _revealNewChar.value < 0.3;
        final showSilhouette =
            _shrinkToSilhouette.value > 0 && _revealNewChar.value < 1.0;
        final showNew = _revealNewChar.value > 0;
        final showFlash = _flashBurst.value > 0.01;

        // 進化前角色的縮放：正常大小 → 縮小 → 剪影放大
        final oldCharScale = showOld
            ? 1.0 - _shrinkToSilhouette.value * 0.3
            : 1.0;
        final oldCharOpacity = showOld
            ? (1.0 - _shrinkToSilhouette.value).clamp(0.0, 1.0)
            : 0.0;

        // 剪影的放大效果
        final silhouetteScale = showSilhouette
            ? 0.7 + _silhouetteGlow.value * 0.5
            : 0.7;

        // 進化階段顏色
        final stageColor = widget.toStage == 1
            ? Colors.blue.shade300
            : Colors.amber.shade400;

        return Stack(
          children: [
            // 全畫面暗幕
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black.withAlpha((bannerScale * 200).round()),
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
                        stops: const [0.0, 0.08, 0.5, 0.92, 1.0],
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        // 上下彩色裝飾線
                        Positioned(
                          top: bannerHeight * 0.06,
                          left: 0,
                          right: 0,
                          child: Container(
                              height: 2,
                              color: stageColor.withAlpha(180)),
                        ),
                        Positioned(
                          bottom: bannerHeight * 0.06,
                          left: 0,
                          right: 0,
                          child: Container(
                              height: 2,
                              color: stageColor.withAlpha(180)),
                        ),

                        // ── 進化前角色（原形） ──
                        if (showOld)
                          Transform.scale(
                            scale: oldCharScale,
                            child: Opacity(
                              opacity: oldCharOpacity,
                              child: SizedBox(
                                width: charSize,
                                height: charSize,
                                child: _buildCharImage(
                                    oldCharPath, attrColor, charSize),
                              ),
                            ),
                          ),

                        // ── 剪影（暗色輪廓 + 發光） ──
                        if (showSilhouette)
                          Transform.scale(
                            scale: silhouetteScale * _pulseAnim.value,
                            child: Opacity(
                              opacity:
                                  (_shrinkToSilhouette.value *
                                          (1.0 - _revealNewChar.value))
                                      .clamp(0.0, 1.0),
                              child: _EvolutionSilhouette(
                                charPath: newCharPath,
                                attrColor: stageColor,
                                size: charSize,
                                glowIntensity: _silhouetteGlow.value,
                                definition: widget.definition,
                                flickerPhase: _mainController.value,
                              ),
                            ),
                          ),

                        // ── 粒子噴發 ──
                        if (_particleController.value > 0)
                          CustomPaint(
                            size: Size(screenSize.width, bannerHeight),
                            painter: _EvoParticlePainter(
                              progress: _particleController.value,
                              particles: _particles,
                              color: stageColor,
                              center: Offset(
                                  screenSize.width / 2, bannerHeight / 2),
                              maxRadius: charSize * 1.8,
                            ),
                          ),

                        // ── 白色閃光爆發 ──
                        if (showFlash)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    radius: 1.0,
                                    colors: [
                                      Colors.white.withAlpha(
                                          (_flashBurst.value * 255).round()),
                                      stageColor.withAlpha(
                                          (_flashBurst.value * 180).round()),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.35, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // ── 進化後角色顯現 ──
                        if (showNew)
                          Transform.scale(
                            scale: 0.5 + _revealNewChar.value * 0.5,
                            child: Opacity(
                              opacity: _revealNewChar.value,
                              child: SizedBox(
                                width: charSize,
                                height: charSize,
                                child: _buildCharImage(
                                    newCharPath, attrColor, charSize),
                              ),
                            ),
                          ),

                        // ── 進化文字 ──
                        Positioned(
                          bottom: bannerHeight * 0.10,
                          left: 0,
                          right: 0,
                          child: Opacity(
                            opacity: _textFade.value,
                            child: Column(
                              children: [
                                // 「進化完成」
                                Text(
                                  '— 進化完成 —',
                                  style: TextStyle(
                                    color: stageColor.withAlpha(220),
                                    fontSize: AppTheme.fontBodyMd,
                                    letterSpacing: 4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                // 新名稱
                                Text(
                                  widget.newDisplayName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: AppTheme.fontDisplayLg,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 4,
                                    shadows: [
                                      Shadow(
                                          color: stageColor.withAlpha(200),
                                          blurRadius: 14),
                                      const Shadow(
                                          color: Colors.black, blurRadius: 4),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                // 進化階段 badge
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: stageColor.withAlpha(50),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: stageColor.withAlpha(120)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.auto_awesome,
                                              color: stageColor, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${widget.toStage} 階進化',
                                            style: TextStyle(
                                              color: stageColor,
                                              fontSize: AppTheme.fontBodyMd,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // 進化星星
                                    ...List.generate(
                                      widget.toStage,
                                      (_) => Icon(Icons.star,
                                          color: stageColor, size: 16),
                                    ),
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
                  if (_mainController.value > 0.65) {
                    _mainController.value = 0.89;
                  }
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCharImage(String? path, Color attrColor, double size) {
    if (path != null) {
      return Image.asset(
        path,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            CatPlaceholder(color: attrColor, size: size),
      );
    }
    return CatPlaceholder(color: attrColor, size: size);
  }
}

// ═══════════════════════════════════════════
// 進化剪影（暗色輪廓 + 邊緣發光 + 閃爍）
// ═══════════════════════════════════════════

class _EvolutionSilhouette extends StatelessWidget {
  final String? charPath;
  final Color attrColor;
  final double size;
  final double glowIntensity;
  final CatAgentDefinition definition;
  final double flickerPhase;

  const _EvolutionSilhouette({
    required this.charPath,
    required this.attrColor,
    required this.size,
    required this.glowIntensity,
    required this.definition,
    required this.flickerPhase,
  });

  @override
  Widget build(BuildContext context) {
    // 閃爍效果：在剪影階段快速明暗交替
    final flicker = (sin(flickerPhase * 40) * 0.15 + 0.85).clamp(0.7, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 外部發光
          if (glowIntensity > 0)
            Container(
              width: size * (1.0 + glowIntensity * 0.4),
              height: size * (1.0 + glowIntensity * 0.4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: attrColor
                        .withAlpha((glowIntensity * 150 * flicker).round()),
                    blurRadius: 40 * glowIntensity,
                    spreadRadius: 15 * glowIntensity,
                  ),
                ],
              ),
            ),
          // 剪影
          Opacity(
            opacity: flicker,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Color.lerp(
                  const Color(0xFF0A0A15),
                  attrColor,
                  glowIntensity * 0.5,
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
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 粒子噴發 Painter
// ═══════════════════════════════════════════

class _EvoParticlePainter extends CustomPainter {
  final double progress;
  final List<_EvoParticle> particles;
  final Color color;
  final Offset center;
  final double maxRadius;

  _EvoParticlePainter({
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
      final r = p.size * (1.0 - t * 0.5);

      if (r <= 0) continue;

      final hsl = HSLColor.fromColor(color);
      final particleColor = hsl
          .withHue((hsl.hue + p.hue) % 360)
          .withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0))
          .toColor()
          .withAlpha(alpha);

      final paint = Paint()..color = particleColor;

      // 菱形 + 光暈
      final path = Path()
        ..moveTo(px, py - r)
        ..lineTo(px + r * 0.6, py)
        ..lineTo(px, py + r)
        ..lineTo(px - r * 0.6, py)
        ..close();
      canvas.drawPath(path, paint);

      if (r > 3) {
        final glowPaint = Paint()
          ..color = particleColor.withAlpha((alpha * 0.35).round())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset(px, py), r * 0.9, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_EvoParticlePainter old) => old.progress != progress;
}

/// 粒子資料
class _EvoParticle {
  final double angle;
  final double speed;
  final double size;
  final double cosA;
  final double sinA;
  final double hue;

  const _EvoParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.cosA,
    required this.sinA,
    required this.hue,
  });
}
