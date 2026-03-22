import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../config/cat_agent_data.dart';
import '../../../core/models/cat_data.dart';
import '../../../core/models/cat_agent.dart';
import '../../agents/providers/player_provider.dart';
import '../providers/cat_provider.dart';

/// 右側貓咪面板 — 5 隻貓咪的飽食度 + 寶箱堆疊 + 批量開啟
class CatPanel extends StatelessWidget {
  /// GlobalKey map，讓 HomeScreen 能找到每隻貓的位置（用於能量球飛行）
  final Map<String, GlobalKey> catKeys;

  const CatPanel({super.key, required this.catKeys});

  @override
  Widget build(BuildContext context) {
    return Consumer2<CatProvider, PlayerProvider>(
      builder: (context, catProvider, playerProvider, _) {
        if (!catProvider.isInitialized || !playerProvider.isInitialized) {
          return const SizedBox.shrink();
        }

        final playerLevel = playerProvider.data.playerLevel;

        // 計算所有可收集的寶箱總數
        int totalChests = 0;
        for (final def in CatDefinitions.all) {
          final cat = catProvider.cats[def.id];
          if (cat != null && cat.isFull(playerLevel)) {
            totalChests += cat.chestCount(playerLevel);
          }
        }

        return Column(
          children: [
            // 一鍵收集按鈕
            if (totalChests > 0)
              GestureDetector(
                onTap: () => _collectAllRewards(context, catProvider, playerLevel),
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade600, Colors.orange.shade400],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withAlpha(80),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('🎁', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        '收集全部 x$totalChests',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // 貓咪列表
            ...CatDefinitions.all.map((def) {
              final cat = catProvider.cats[def.id];
              if (cat == null) return const SizedBox.shrink();

              catKeys.putIfAbsent(def.id, () => GlobalKey());

              return Expanded(
                child: _CatCard(
                  key: catKeys[def.id],
                  definition: def,
                  status: cat,
                  playerLevel: playerLevel,
                  onCollect: cat.isFull(playerLevel)
                      ? () => _collectReward(context, catProvider, def, playerLevel)
                      : null,
                  onTapDetail: () => _showCatQuickView(context, def, cat, playerLevel),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  /// 找到對應的 AgentDefinition（透過 BlockColor 對應）
  static CatAgentDefinition? _findAgentForCat(CatDefinition catDef) {
    final targetColor = catDef.color;
    for (final agent in CatAgentData.allAgents) {
      if (agent.attribute.blockColor == targetColor) return agent;
    }
    return null;
  }

  void _showCatQuickView(
    BuildContext context,
    CatDefinition catDef,
    CatStatus status,
    int playerLevel,
  ) {
    final agentDef = _findAgentForCat(catDef);
    if (agentDef == null) return;

    final playerProvider = context.read<PlayerProvider>();
    final agentInfo = playerProvider.allAgentInfos.firstWhere(
      (a) => a.definition.id == agentDef.id,
    );

    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CatQuickViewSheet(
        catDef: catDef,
        status: status,
        playerLevel: playerLevel,
        agentDef: agentDef,
        agentInfo: agentInfo,
      ),
    );
  }

  /// 一鍵收集所有貓咪的寶箱
  void _collectAllRewards(
    BuildContext context,
    CatProvider catProvider,
    int playerLevel,
  ) {
    final player = context.read<PlayerProvider>();
    final allRewards = <CatReward>[];
    int totalChests = 0;
    int totalGold = 0;
    int maxRarity = 1;

    for (final def in CatDefinitions.all) {
      final result = catProvider.collectAllRewards(def.id, playerLevel, playerData: player.data);
      if (result == null) continue;
      final (rewards, chestCount) = result;
      allRewards.addAll(rewards);
      totalChests += chestCount;
    }

    if (allRewards.isEmpty) return;

    totalGold = allRewards.fold<int>(0, (sum, r) => sum + r.quantity);
    maxRarity = allRewards.fold<int>(1, (m, r) => r.rarity > m ? r.rarity : m);
    player.addGold(totalGold);

    HapticFeedback.heavyImpact();

    // 用第一隻有寶箱的貓當代表
    final firstCatDef = CatDefinitions.all.first;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => _RewardDialog(
        catDef: firstCatDef,
        rewards: allRewards,
        chestCount: totalChests,
        totalGold: totalGold,
        maxRarity: maxRarity,
      ),
    );
  }

  void _collectReward(
    BuildContext context,
    CatProvider catProvider,
    CatDefinition def,
    int playerLevel,
  ) {
    final player = context.read<PlayerProvider>();
    final result = catProvider.collectAllRewards(def.id, playerLevel, playerData: player.data);
    if (result == null) return;

    final (rewards, chestCount) = result;

    // 合計金幣
    final totalGold = rewards.fold<int>(0, (sum, r) => sum + r.quantity);
    player.addGold(totalGold);

    // 最高稀有度
    final maxRarity = rewards.fold<int>(1, (m, r) => r.rarity > m ? r.rarity : m);

    // 震動
    HapticFeedback.heavyImpact();

    // 顯示開寶箱彈窗
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => _RewardDialog(
        catDef: def,
        rewards: rewards,
        chestCount: chestCount,
        totalGold: totalGold,
        maxRarity: maxRarity,
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 收穫獎勵彈窗 — 支援批量開啟
// ═══════════════════════════════════════════

class _RewardDialog extends StatefulWidget {
  final CatDefinition catDef;
  final List<CatReward> rewards;
  final int chestCount;
  final int totalGold;
  final int maxRarity;

  const _RewardDialog({
    required this.catDef,
    required this.rewards,
    required this.chestCount,
    required this.totalGold,
    required this.maxRarity,
  });

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

  late List<_SparkleParticle> _particles;

  @override
  void initState() {
    super.initState();

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

    _particles = _generateParticles();
    _startAnimation();
  }

  List<_SparkleParticle> _generateParticles() {
    final rng = Random();
    final color = widget.catDef.color.color;
    // 多寶箱 = 更多粒子
    final count = 12 + widget.chestCount * 4;
    return List.generate(count.clamp(12, 32), (i) {
      final angle = (i / count) * 2 * pi + rng.nextDouble() * 0.4;
      return _SparkleParticle(
        angle: angle,
        speed: 0.8 + rng.nextDouble() * 1.5,
        size: 3.0 + rng.nextDouble() * 4.0,
        color: Color.lerp(color, Colors.white, rng.nextDouble() * 0.5)!,
      );
    });
  }

  Future<void> _startAnimation() async {
    await _shakeController.forward();
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));

    setState(() => _phase = 1);
    HapticFeedback.heavyImpact();
    _burstController.forward();
    await Future.delayed(const Duration(milliseconds: 300));

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
    final rarityColor = _rarityColor(widget.maxRarity);
    final rarityLabel = _rarityLabel(widget.maxRarity);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 寶箱 + 爆發
          SizedBox(
            width: 200,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
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
                if (_phase >= 1)
                  AnimatedBuilder(
                    animation: _burstController,
                    builder: (_, __) => CustomPaint(
                      size: const Size(200, 180),
                      painter: _SparklePainter(
                        progress: _burstController.value,
                        particles: _particles,
                        maxRadius: 90,
                      ),
                    ),
                  ),
                if (_phase == 0)
                  AnimatedBuilder(
                    animation: _shakeAnim,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(_shakeAnim.value, 0),
                      child: child,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '🎁',
                          style: TextStyle(fontSize: 56, shadows: [
                            Shadow(
                              color: catColor.withAlpha(150),
                              blurRadius: 20,
                            ),
                          ]),
                        ),
                        if (widget.chestCount > 1)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: catColor.withAlpha(180),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'x${widget.chestCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                if (_phase >= 1 && _phase < 2)
                  Text(
                    '✨',
                    style: TextStyle(fontSize: 56, shadows: [
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
                width: 240,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    const SizedBox(height: 6),

                    // 寶箱數量
                    if (widget.chestCount > 1) ...[
                      Text(
                        '開啟 ${widget.chestCount} 個寶箱',
                        style: TextStyle(
                          color: catColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    // 最高稀有度標籤
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
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
                    const SizedBox(height: 10),

                    // 獎勵明細（批量時分行顯示）
                    if (widget.chestCount <= 3)
                      ...widget.rewards.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  r.name,
                                  style: TextStyle(
                                    color: _rarityColor(r.rarity),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '+${r.quantity} 🪙',
                                  style: const TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          )),

                    // 超過 3 個寶箱只顯示總計
                    if (widget.chestCount > 3) ...[
                      _RewardSummaryRow(
                        label: '普通素材',
                        count: widget.rewards.where((r) => r.rarity == 1).length,
                        color: _rarityColor(1),
                      ),
                      _RewardSummaryRow(
                        label: '進階素材',
                        count: widget.rewards.where((r) => r.rarity == 2).length,
                        color: _rarityColor(2),
                      ),
                      _RewardSummaryRow(
                        label: '稀有素材',
                        count: widget.rewards.where((r) => r.rarity == 3).length,
                        color: _rarityColor(3),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // 總計金幣
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 4),
                          Text(
                            '+${widget.totalGold}',
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

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
        return const Color(0xFFBF6FFF);
      case 2:
        return const Color(0xFF4FAAFF);
      default:
        return const Color(0xFFAABBCC);
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

/// 獎勵摘要行（超過 3 個寶箱時用）
class _RewardSummaryRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _RewardSummaryRow({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12),
          ),
          const SizedBox(width: 6),
          Text(
            'x$count',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(px, py),
            width: r * 2,
            height: r * 2,
          ),
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
// 首頁快速查看貓咪詳情
// ═══════════════════════════════════════════

class _CatQuickViewSheet extends StatelessWidget {
  final CatDefinition catDef;
  final CatStatus status;
  final int playerLevel;
  final CatAgentDefinition agentDef;
  final AgentInfo agentInfo;

  const _CatQuickViewSheet({
    required this.catDef,
    required this.status,
    required this.playerLevel,
    required this.agentDef,
    required this.agentInfo,
  });

  @override
  Widget build(BuildContext context) {
    final blockColor = catDef.color.color;
    final isUnlocked = agentInfo.isUnlocked;
    final progress = status.progress(playerLevel);
    final chestCount = status.chestCount(playerLevel);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 頂部拉條
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // ─── 貓咪頭像 + 名稱 ───
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: blockColor.withAlpha(60),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: blockColor.withAlpha(150), width: 2),
                  ),
                  child: Center(
                    child: Text(catDef.emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            catDef.name,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isUnlocked) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: blockColor.withAlpha(40),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: blockColor.withAlpha(120)),
                              ),
                              child: Text(
                                'Lv.${agentInfo.level}',
                                style: TextStyle(
                                  color: blockColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isUnlocked
                            ? '${agentDef.breed} · ${agentDef.role.label}'
                            : agentDef.role.label,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // 寶箱
                if (chestCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: blockColor.withAlpha(180),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '🎁 x$chestCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // ─── 飽食度進度條 ───
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '飽食度',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                    ),
                    Text(
                      '${status.currentFood} / ${status.maxFood(playerLevel)}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withAlpha(20),
                    valueColor: AlwaysStoppedAnimation(blockColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ─── 屬性面板（已解鎖才顯示） ───
            if (isUnlocked) ...[
              Row(
                children: [
                  _QuickStatBox('ATK', agentInfo.atk, Colors.red.shade300),
                  const SizedBox(width: 8),
                  _QuickStatBox('DEF', agentInfo.def, Colors.blue.shade300),
                  const SizedBox(width: 8),
                  _QuickStatBox('HP', agentInfo.hp, Colors.green.shade300),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // ─── 技能 ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '🎯 ${agentDef.skill.name}',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '⚡${agentDef.skill.energyCost}',
                        style: TextStyle(
                          color: Colors.amber.shade300,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    agentDef.skill.description,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  if (agentDef.skill.boardEffect != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '🧩 ${agentDef.skill.boardEffect!.description}',
                      style: TextStyle(
                        color: Colors.cyan.shade300,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ─── 被動 ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.bgCard.withAlpha(120),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '💡 ${agentDef.passiveDescription}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStatBox extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _QuickStatBox(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 貓咪卡片（含飽食脈衝動畫 + 寶箱數量徽章）
// ═══════════════════════════════════════════

class _CatCard extends StatefulWidget {
  final CatDefinition definition;
  final CatStatus status;
  final int playerLevel;
  final VoidCallback? onCollect;
  final VoidCallback? onTapDetail;

  const _CatCard({
    super.key,
    required this.definition,
    required this.status,
    required this.playerLevel,
    this.onCollect,
    this.onTapDetail,
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
    final chestCount = widget.status.chestCount(widget.playerLevel);
    final blockColor = widget.definition.color.color;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) {
        final glowAlpha = isFull ? (60 + (_pulseAnim.value * 80)).round() : 0;
        final borderWidth = isFull ? 1.5 + _pulseAnim.value * 0.5 : 0.0;
        final emojiScale = isFull ? 1.0 + _pulseAnim.value * 0.15 : 1.0;

        return GestureDetector(
          onTap: isFull ? widget.onCollect : widget.onTapDetail,
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
                // 貓咪 emoji + 名稱 + 寶箱徽章
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
                    // 寶箱數量徽章
                    if (chestCount > 0) ...[
                      const SizedBox(width: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: blockColor.withAlpha(200),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '🎁$chestCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),

                // 飽食度進度條（顯示下一個寶箱的進度）
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: isFull ? (progress == 0 ? 1.0 : progress) : progress,
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

                // 開啟按鈕（有寶箱時顯示）
                if (isFull)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
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
                    child: Text(
                      chestCount > 1 ? '開啟 x$chestCount' : '開啟',
                      style: const TextStyle(
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
