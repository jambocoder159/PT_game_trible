import 'package:flutter/material.dart';
import '../../../config/image_assets.dart';
import '../../../config/theme.dart';
import '../../../core/models/block.dart';

/// 方塊上的敵人技能狀態覆蓋
enum BlockSkillOverlay {
  none,
  obstacle, // 灰色障礙格
  obstaclesCracked, // 裂紋障礙格（已被相鄰消 1 次）
  poison, // 毒格（帶倒數）
  weakened, // 弱化標記
}

/// 單一方塊的視覺元件 — 含消除動畫（膨脹 pop + 淡出）
/// 粒子飛射效果由上層 BoardAttackEffect 負責
class BlockWidget extends StatefulWidget {
  final Block block;
  final double size;
  final int combo;
  final BlockSkillOverlay skillOverlay;
  final int poisonCountdown; // 毒格倒數數字

  const BlockWidget({
    super.key,
    required this.block,
    this.size = AppTheme.blockSize,
    this.combo = 0,
    this.skillOverlay = BlockSkillOverlay.none,
    this.poisonCountdown = 0,
  });

  @override
  State<BlockWidget> createState() => _BlockWidgetState();
}

class _BlockWidgetState extends State<BlockWidget>
    with TickerProviderStateMixin {
  late AnimationController _elimController;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  // ── 入場動畫（新方塊降落彈跳） ──
  late AnimationController _enterController;
  late Animation<double> _enterScale;
  late Animation<double> _enterOpacity;

  bool _wasEliminating = false;

  @override
  void initState() {
    super.initState();
    _elimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    // 快速膨脹然後消失（pop 效果）
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.0), weight: 80),
    ]).animate(CurvedAnimation(
      parent: _elimController,
      curve: Curves.easeOutCubic,
    ));

    _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _elimController,
        curve: const Interval(0.25, 1.0, curve: Curves.easeIn),
      ),
    );

    // ── 入場：壓扁→彈起的著陸感 ──
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _enterScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 1.15), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.92), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.92, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(
      parent: _enterController,
      curve: Curves.easeOutCubic,
    ));
    _enterOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _enterController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    if (widget.block.isEliminating) {
      _wasEliminating = true;
      _elimController.forward();
    } else {
      // 新方塊播放入場動畫
      _enterController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant BlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.block.isEliminating && !_wasEliminating) {
      _wasEliminating = true;
      _elimController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _elimController.dispose();
    _enterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isObstacle = widget.skillOverlay == BlockSkillOverlay.obstacle ||
        widget.skillOverlay == BlockSkillOverlay.obstaclesCracked;
    final color = isObstacle || widget.block.isBlackened
        ? Colors.grey.shade800
        : widget.block.color.color;
    final darkerColor = Color.lerp(color, Colors.black, 0.3)!;
    final size = widget.size;

    Widget blockContent;

    if (isObstacle) {
      blockContent = _buildObstacleBlock(size);
    } else if (_wasEliminating) {
      blockContent = AnimatedBuilder(
        animation: _elimController,
        builder: (context, child) {
          return Center(
            child: Opacity(
              opacity: _opacityAnim.value,
              child: Transform.scale(
                scale: _scaleAnim.value,
                child: child!,
              ),
            ),
          );
        },
        child: _buildBlockContainer(color, darkerColor, size),
      );
    } else {
      // 入場動畫包裹
      blockContent = AnimatedBuilder(
        animation: _enterController,
        builder: (context, child) {
          if (_enterController.isCompleted) return child!;
          return Center(
            child: Opacity(
              opacity: _enterOpacity.value,
              child: Transform.scale(
                scale: _enterScale.value,
                child: child!,
              ),
            ),
          );
        },
        child: _buildBlockContainer(color, darkerColor, size),
      );
    }

    // 覆蓋層：毒格或弱化
    if (widget.skillOverlay == BlockSkillOverlay.poison) {
      return Stack(
        children: [
          blockContent,
          _buildPoisonOverlay(size),
        ],
      );
    } else if (widget.skillOverlay == BlockSkillOverlay.weakened) {
      return Stack(
        children: [
          Opacity(opacity: 0.5, child: blockContent),
          _buildWeakenOverlay(size),
        ],
      );
    }

    return blockContent;
  }

  Widget _buildBlockContainer(Color color, Color darkerColor, double size) {
    final imagePath = ImageAssets.blockImage(
      widget.block.color,
      dark: widget.block.isBlackened,
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusBlock),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(80),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusBlock),
        child: Image.asset(
          imagePath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _buildFallbackBlock(color, darkerColor, size),
        ),
      ),
    );
  }

  /// 圖片載入失敗時的 fallback（原始漸層樣式）
  Widget _buildFallbackBlock(Color color, Color darkerColor, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, darkerColor],
        ),
      ),
      child: Center(
        child: Text(
          widget.block.isBlackened ? '✕' : widget.block.color.symbol,
          style: TextStyle(
            fontSize: size * 0.4,
            color: Colors.white.withAlpha(200),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ─── 敵人技能視覺效果 ───

  /// 障礙格：灰色石頭方塊
  Widget _buildObstacleBlock(double size) {
    final isCracked = widget.skillOverlay == BlockSkillOverlay.obstaclesCracked;
    final imagePath = isCracked
        ? ImageAssets.blockObstacleCracked
        : ImageAssets.blockObstacle;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusBlock),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusBlock),
        child: Image.asset(
          imagePath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildObstacleFallback(size, isCracked),
        ),
      ),
    );
  }

  Widget _buildObstacleFallback(double size, bool isCracked) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey.shade600, Colors.grey.shade800],
        ),
        border: Border.all(color: Colors.grey.shade500, width: 1.5),
      ),
      child: Center(
        child: Text(
          isCracked ? '💥' : '🧱',
          style: TextStyle(fontSize: size * 0.4),
        ),
      ),
    );
  }

  /// 毒格覆蓋：毒格素材 + 倒數數字
  Widget _buildPoisonOverlay(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusBlock),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withAlpha(80),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusBlock),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              ImageAssets.blockPoison,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.purple.withAlpha(120),
              ),
            ),
            Center(
              child: Text(
                '${widget.poisonCountdown}',
                style: TextStyle(
                  fontSize: size * 0.45,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: const [
                    Shadow(color: Colors.purple, blurRadius: 8),
                    Shadow(color: Colors.purple, blurRadius: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 弱化覆蓋：弱化素材
  Widget _buildWeakenOverlay(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusBlock),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withAlpha(50),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusBlock),
        child: Image.asset(
          ImageAssets.blockWeakened,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildWeakenFallback(size),
        ),
      ),
    );
  }

  Widget _buildWeakenFallback(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusBlock),
        color: Colors.black.withAlpha(80),
        border: Border.all(color: Colors.grey.shade600, width: 1),
      ),
      child: Center(
        child: Text(
          '▼',
          style: TextStyle(
            fontSize: size * 0.3,
            color: Colors.red.shade300,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
