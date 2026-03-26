/// 關卡選擇畫面 — 全新設計
/// 章節橫幅 + 蜿蜒節點路徑地圖
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/image_assets.dart';
import '../../../config/stage_data.dart';
import '../../../config/theme.dart';
import '../../../core/models/player_data.dart';
import '../../agents/providers/player_provider.dart';
import '../../game/screens/battle_screen.dart';

class StageSelectScreen extends StatefulWidget {
  const StageSelectScreen({super.key});

  @override
  State<StageSelectScreen> createState() => _StageSelectScreenState();
}

class _StageSelectScreenState extends State<StageSelectScreen>
    with TickerProviderStateMixin {
  late int _selectedChapter;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initChapter();

    _pulseController = AnimationController(
      vsync: this,
      duration: AppTheme.animPulse,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initChapter() {
    final progress = context.read<PlayerProvider>().data.stageProgress;
    int latestChapter = 1;
    for (final chapter in StageData.chapters) {
      final stages = StageData.getChapterStages(chapter.number);
      final allCleared = stages.every((s) => progress[s.id]?.cleared == true);
      final anyCleared = stages.any((s) => progress[s.id]?.cleared == true);
      if (anyCleared && !allCleared) {
        latestChapter = chapter.number;
        break;
      } else if (allCleared) {
        latestChapter = chapter.number + 1;
      }
    }
    final maxChapter = StageData.chapters.last.number;
    _selectedChapter = latestChapter.clamp(1, maxChapter);
  }

  void _switchChapter(int direction) {
    final newChapter = _selectedChapter + direction;
    if (newChapter >= 1 && newChapter <= StageData.chapters.last.number) {
      setState(() => _selectedChapter = newChapter);
      // 滾動到頂部
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chapter = StageData.chapters.firstWhere(
      (c) => c.number == _selectedChapter,
    );

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Consumer<PlayerProvider>(
        builder: (context, provider, _) {
          final stages = StageData.getChapterStages(_selectedChapter);
          final stageProgress = provider.data.stageProgress;
          final clearedCount =
              stages.where((s) => stageProgress[s.id]?.cleared == true).length;

          return Column(
            children: [
              // ─── 章節橫幅 ───
              _ChapterBanner(
                chapter: chapter,
                chapterNumber: _selectedChapter,
                clearedCount: clearedCount,
                totalCount: stages.length,
                stamina: provider.data.stamina,
                maxStamina: provider.data.maxStamina,
                onPrev: _selectedChapter > 1
                    ? () => _switchChapter(-1)
                    : null,
                onNext:
                    _selectedChapter < StageData.chapters.last.number
                        ? () => _switchChapter(1)
                        : null,
              ),

              // ─── 節點路徑地圖 ───
              Expanded(
                child: _StagePathMap(
                  scrollController: _scrollController,
                  stages: stages,
                  stageProgress: stageProgress,
                  stamina: provider.data.stamina,
                  pulseAnimation: _pulseAnimation,
                  onStageTap: (stage) =>
                      _startStage(context, stage, provider),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _startStage(
    BuildContext context,
    StageDefinition stage,
    PlayerProvider playerProvider,
  ) {
    if (playerProvider.data.stamina < stage.staminaCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('體力不足！需要 ${stage.staminaCost} 體力'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (playerProvider.data.team.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請先編排隊伍！'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    playerProvider.consumeStamina(stage.staminaCost);
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => BattleScreen(stage: stage),
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

// ═══════════════════════════════════════
// 章節橫幅
// ═══════════════════════════════════════

class _ChapterBanner extends StatelessWidget {
  final ChapterInfo chapter;
  final int chapterNumber;
  final int clearedCount;
  final int totalCount;
  final int stamina;
  final int maxStamina;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _ChapterBanner({
    required this.chapter,
    required this.chapterNumber,
    required this.clearedCount,
    required this.totalCount,
    required this.stamina,
    required this.maxStamina,
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final bgPath = ImageAssets.battleBackground(chapterNumber);

    return Container(
      height: 180,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 背景圖
          if (bgPath != null)
            Image.asset(
              bgPath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppTheme.bgSecondary,
              ),
            )
          else
            Container(color: AppTheme.bgSecondary),

          // 漸層覆蓋
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha(120),
                  Colors.black.withAlpha(60),
                  AppTheme.bgPrimary.withAlpha(240),
                  AppTheme.bgPrimary,
                ],
                stops: const [0.0, 0.4, 0.85, 1.0],
              ),
            ),
          ),

          // 內容
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 頂部：返回 + 體力
                  Row(
                    children: [
                      const Text(
                        '任務選擇',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // 體力顯示
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(100),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GameIcon(
                              assetPath: ImageAssets.energy,
                              fallbackEmoji: '⚡',
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$stamina/$maxStamina',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // 章節資訊 + 切換箭頭
                  Row(
                    children: [
                      // 上一章
                      _NavArrow(
                        icon: Icons.chevron_left,
                        onTap: onPrev,
                      ),
                      const SizedBox(width: 8),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '第${chapter.number}章',
                              style: TextStyle(
                                color: Colors.white.withAlpha(180),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              chapter.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              chapter.description,
                              style: TextStyle(
                                color: Colors.white.withAlpha(150),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 下一章
                      _NavArrow(
                        icon: Icons.chevron_right,
                        onTap: onNext,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // 進度條
                  _ChapterProgress(
                    cleared: clearedCount,
                    total: totalCount,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _NavArrow({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null
              ? Colors.white.withAlpha(25)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: onTap != null
              ? Colors.white.withAlpha(200)
              : Colors.white.withAlpha(40),
          size: 24,
        ),
      ),
    );
  }
}

class _ChapterProgress extends StatelessWidget {
  final int cleared;
  final int total;

  const _ChapterProgress({required this.cleared, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? cleared / total : 0.0;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withAlpha(30),
              valueColor: AlwaysStoppedAnimation<Color>(
                cleared == total
                    ? AppTheme.stageCleared
                    : AppTheme.stageCurrent,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$cleared/$total',
          style: TextStyle(
            color: Colors.white.withAlpha(180),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════
// 蜿蜒節點路徑地圖
// ═══════════════════════════════════════

class _StagePathMap extends StatelessWidget {
  final ScrollController scrollController;
  final List<StageDefinition> stages;
  final Map<String, StageProgress> stageProgress;
  final int stamina;
  final Animation<double> pulseAnimation;
  final void Function(StageDefinition) onStageTap;

  const _StagePathMap({
    required this.scrollController,
    required this.stages,
    required this.stageProgress,
    required this.stamina,
    required this.pulseAnimation,
    required this.onStageTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // 節點佈局參數
    const nodeSize = 56.0;
    const rowHeight = 100.0;
    final leftX = screenWidth * 0.2;
    final rightX = screenWidth * 0.8 - nodeSize;
    final centerX = (screenWidth - nodeSize) / 2;

    // 計算每個節點的位置（S型蜿蜒）
    final nodePositions = <Offset>[];
    for (int i = 0; i < stages.length; i++) {
      final row = i;
      final y = row * rowHeight + 20;
      double x;

      // S型排列：左-中-右-中-左-中-右...
      final pattern = i % 4;
      switch (pattern) {
        case 0:
          x = leftX;
          break;
        case 1:
          x = centerX;
          break;
        case 2:
          x = rightX;
          break;
        case 3:
          x = centerX;
          break;
        default:
          x = centerX;
      }
      nodePositions.add(Offset(x, y));
    }

    final totalHeight = stages.length * rowHeight + 60;

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 40),
      child: SizedBox(
        width: screenWidth,
        height: totalHeight,
        child: Stack(
          children: [
            // ─── 路徑線 ───
            CustomPaint(
              size: Size(screenWidth, totalHeight),
              painter: _PathPainter(
                nodePositions: nodePositions,
                nodeSize: nodeSize,
                stageProgress: stageProgress,
                stages: stages,
              ),
            ),

            // ─── 節點 ───
            ...List.generate(stages.length, (index) {
              final stage = stages[index];
              final pos = nodePositions[index];
              final progress = stageProgress[stage.id];
              final isCleared = progress?.cleared == true;
              final stars = progress?.stars ?? 0;
              final isUnlocked = index == 0 ||
                  (stageProgress[stages[index - 1].id]?.cleared == true);
              final isCurrent = isUnlocked && !isCleared;
              final isBoss = stage.stageNumber == stages.length;

              return Positioned(
                left: pos.dx,
                top: pos.dy,
                child: _StageNode(
                  stage: stage,
                  isCleared: isCleared,
                  isUnlocked: isUnlocked,
                  isCurrent: isCurrent,
                  isBoss: isBoss,
                  stars: stars,
                  stamina: stamina,
                  nodeSize: nodeSize,
                  pulseAnimation: isCurrent ? pulseAnimation : null,
                  onTap: isUnlocked
                      ? () => onStageTap(stage)
                      : null,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// 路徑繪製器
// ═══════════════════════════════════════

class _PathPainter extends CustomPainter {
  final List<Offset> nodePositions;
  final double nodeSize;
  final Map<String, StageProgress> stageProgress;
  final List<StageDefinition> stages;

  _PathPainter({
    required this.nodePositions,
    required this.nodeSize,
    required this.stageProgress,
    required this.stages,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < nodePositions.length - 1; i++) {
      final from = nodePositions[i] + Offset(nodeSize / 2, nodeSize / 2);
      final to = nodePositions[i + 1] + Offset(nodeSize / 2, nodeSize / 2);

      final isActive =
          stageProgress[stages[i].id]?.cleared == true;

      final paint = Paint()
        ..color = isActive
            ? AppTheme.pathActive.withAlpha(180)
            : AppTheme.pathInactive.withAlpha(100)
        ..strokeWidth = isActive ? 3.0 : 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (!isActive) {
        // 虛線效果
        _drawDashedLine(canvas, from, to, paint);
      } else {
        // 實線 + 曲線
        final path = Path()
          ..moveTo(from.dx, from.dy);

        final midY = (from.dy + to.dy) / 2;
        path.cubicTo(
          from.dx, midY,
          to.dx, midY,
          to.dx, to.dy,
        );

        canvas.drawPath(path, paint);

        // 發光效果
        final glowPaint = Paint()
          ..color = AppTheme.pathActive.withAlpha(40)
          ..strokeWidth = 8.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawPath(path, glowPaint);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;

    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final unitDx = dx / distance;
    final unitDy = dy / distance;

    double currentDistance = 0;
    while (currentDistance < distance) {
      final startX = from.dx + unitDx * currentDistance;
      final startY = from.dy + unitDy * currentDistance;
      currentDistance += dashWidth;
      if (currentDistance > distance) currentDistance = distance;
      final endX = from.dx + unitDx * currentDistance;
      final endY = from.dy + unitDy * currentDistance;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
      currentDistance += dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) {
    return oldDelegate.stageProgress != stageProgress;
  }
}

// ═══════════════════════════════════════
// 關卡節點
// ═══════════════════════════════════════

class _StageNode extends StatelessWidget {
  final StageDefinition stage;
  final bool isCleared;
  final bool isUnlocked;
  final bool isCurrent;
  final bool isBoss;
  final int stars;
  final int stamina;
  final double nodeSize;
  final Animation<double>? pulseAnimation;
  final VoidCallback? onTap;

  const _StageNode({
    required this.stage,
    required this.isCleared,
    required this.isUnlocked,
    required this.isCurrent,
    required this.isBoss,
    required this.stars,
    required this.stamina,
    required this.nodeSize,
    this.pulseAnimation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.lightImpact();
          onTap!();
        }
      },
      child: SizedBox(
        width: nodeSize + 100, // 為標籤留空間
        height: nodeSize + 30,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 節點圓圈
            Positioned(
              left: 0,
              top: 0,
              child: pulseAnimation != null
                  ? AnimatedBuilder(
                      animation: pulseAnimation!,
                      builder: (_, child) => Transform.scale(
                        scale: pulseAnimation!.value,
                        child: child,
                      ),
                      child: _buildNodeCircle(),
                    )
                  : _buildNodeCircle(),
            ),

            // 關卡名稱（節點右側）
            Positioned(
              left: nodeSize + 8,
              top: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.name,
                    style: TextStyle(
                      color: isUnlocked
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary.withAlpha(80),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 敵人圖標
                      ...stage.enemies.take(3).map((e) => Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: GameImage(
                              assetPath: ImageAssets.enemyImage(e.id),
                              fallbackEmoji: e.emoji,
                              width: 16,
                              height: 16,
                            ),
                          )),
                      const SizedBox(width: 6),
                      // 體力
                      GameIcon(
                        assetPath: ImageAssets.energy,
                        fallbackEmoji: '⚡',
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${stage.staminaCost}',
                        style: TextStyle(
                          color: stamina >= stage.staminaCost
                              ? AppTheme.textSecondary
                              : Colors.red,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 星星（已通關）
            if (isCleared)
              Positioned(
                left: (nodeSize - 42) / 2,
                top: nodeSize - 2,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    return GameIcon(
                      assetPath: i < stars
                          ? ImageAssets.starFull
                          : ImageAssets.starEmpty,
                      fallbackEmoji: i < stars ? '⭐' : '☆',
                      size: 14,
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeCircle() {
    Color bgColor;
    Color borderColor;
    Widget content;

    if (isCleared) {
      bgColor = AppTheme.stageCleared.withAlpha(40);
      borderColor = AppTheme.stageCleared;
      content = const Icon(Icons.check, color: Colors.white, size: 24);
    } else if (isCurrent) {
      bgColor = AppTheme.stageCurrent.withAlpha(40);
      borderColor = AppTheme.stageCurrent;
      content = Text(
        '${stage.stageNumber}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      );
    } else if (isUnlocked) {
      bgColor = AppTheme.bgCard;
      borderColor = AppTheme.stageCurrent.withAlpha(100);
      content = Text(
        '${stage.stageNumber}',
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      );
    } else {
      bgColor = AppTheme.stageLocked.withAlpha(30);
      borderColor = AppTheme.stageLocked.withAlpha(60);
      content = GameIcon(
        assetPath: ImageAssets.lock,
        fallbackEmoji: '🔒',
        size: 20,
      );
    }

    return Container(
      width: nodeSize,
      height: nodeSize,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: isCurrent ? 3 : 2,
        ),
        boxShadow: [
          if (isCleared)
            BoxShadow(
              color: AppTheme.stageCleared.withAlpha(50),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          if (isCurrent)
            BoxShadow(
              color: AppTheme.stageCurrent.withAlpha(60),
              blurRadius: 14,
              spreadRadius: 3,
            ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          content,
          // Boss 標記
          if (isBoss)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: const Text(
                  '👑',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
