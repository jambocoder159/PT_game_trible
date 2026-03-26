import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/image_assets.dart';
import '../../../config/theme.dart';
import '../../../config/cat_agent_data.dart';
import '../../../core/models/cat_data.dart';
import '../../../core/models/cat_agent.dart';
import '../../agents/providers/player_provider.dart';
import '../providers/cat_provider.dart';
import '../providers/idle_provider.dart';

/// 右側貓咪面板 — 顯示隊伍角色（可施放技能）+ 寶箱收集
class CatPanel extends StatelessWidget {
  final Map<String, GlobalKey> catKeys;

  const CatPanel({super.key, required this.catKeys});

  @override
  Widget build(BuildContext context) {
    return Consumer3<CatProvider, PlayerProvider, IdleProvider>(
      builder: (context, catProvider, playerProvider, idleProvider, _) {
        if (!catProvider.isInitialized || !playerProvider.isInitialized) {
          return const SizedBox.shrink();
        }

        final playerLevel = playerProvider.data.playerLevel;
        final team = playerProvider.data.team;

        // 計算可收集的寶箱數
        int totalChests = 0;
        for (final def in CatDefinitions.all) {
          final cat = catProvider.cats[def.id];
          if (cat != null && cat.isFull(playerLevel)) {
            totalChests += cat.chestCount(playerLevel);
          }
        }

        return Column(
          children: [
            // ─── 寶箱收集按鈕 ───
            if (totalChests > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _CollectButton(
                  totalChests: totalChests,
                  onTap: () => _collectAllRewards(context, catProvider, playerLevel),
                ),
              ),

            // ─── 3 個隊伍欄位（固定 3 格） ───
            for (int i = 0; i < 3; i++)
              _buildSlot(context, i, team, playerLevel, idleProvider, catProvider),

            // ─── 飽食度總覽 ───
            const SizedBox(height: 4),
            _FoodOverview(catProvider: catProvider, playerLevel: playerLevel),
          ],
        );
      },
    );
  }

  Widget _buildSlot(
    BuildContext context,
    int index,
    List<String> team,
    int playerLevel,
    IdleProvider idleProvider,
    CatProvider catProvider,
  ) {
    if (index < team.length) {
      final agentId = team[index];
      final agentDef = _findAgent(agentId);
      if (agentDef == null) {
        return _EmptySlot(
          index: index,
          onTap: () => _showAgentPicker(context, index),
        );
      }

      final catDef = _findCatForAgent(agentDef);
      final catStatus = catDef != null ? catProvider.cats[catDef.id] : null;
      catKeys.putIfAbsent(agentId, () => GlobalKey());

      return _AgentCard(
        key: catKeys[agentId],
        agentDef: agentDef,
        agentId: agentId,
        catStatus: catStatus,
        playerLevel: playerLevel,
        idleProvider: idleProvider,
        onTap: () => _onAgentTap(context, agentDef, agentId, idleProvider),
        onLongPress: () => _showAgentPicker(context, index),
      );
    } else {
      return _EmptySlot(
        index: index,
        onTap: () => _showAgentPicker(context, index),
      );
    }
  }

  void _onAgentTap(
    BuildContext context,
    CatAgentDefinition agentDef,
    String agentId,
    IdleProvider idleProvider,
  ) {
    if (idleProvider.isSkillReady(agentId)) {
      _showSkillConfirmDialog(context, agentDef, agentId, idleProvider);
    }
  }

  /// 技能確認視窗
  void _showSkillConfirmDialog(
    BuildContext context,
    CatAgentDefinition agentDef,
    String agentId,
    IdleProvider idleProvider,
  ) {
    final attrColor = _attrColorFor(agentDef.attribute);
    final effect = agentDef.skill.boardEffect;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: attrColor.withAlpha(120), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 角色圖示
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: attrColor.withAlpha(40),
                  shape: BoxShape.circle,
                  border: Border.all(color: attrColor.withAlpha(150), width: 2),
                ),
                child: ClipOval(
                  child: _buildAgentImage(agentId, agentDef, 44),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${agentDef.name} — ${agentDef.skill.name}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              if (effect != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: attrColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🎯 ${effect.description}',
                    style: TextStyle(
                      color: attrColor,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: BorderSide(color: Colors.white.withAlpha(30)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        HapticFeedback.mediumImpact();
                        idleProvider.activateSkill(agentId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: attrColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('施放！'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 角色選擇器
  void _showAgentPicker(BuildContext context, int slotIndex) {
    final playerProvider = context.read<PlayerProvider>();
    final idleProvider = context.read<IdleProvider>();
    final unlocked = playerProvider.unlockedAgents;
    final currentTeam = List<String>.from(playerProvider.data.team);

    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '選擇欄位 ${slotIndex + 1} 的角色',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // 清空按鈕（如果該欄位有角色）
              if (slotIndex < currentTeam.length)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GestureDetector(
                    onTap: () {
                      currentTeam.removeAt(slotIndex);
                      playerProvider.setTeam(currentTeam);
                      idleProvider.setTeam(currentTeam);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withAlpha(60)),
                      ),
                      child: const Center(
                        child: Text(
                          '移除此欄位角色',
                          style: TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ),
              // 角色列表
              ...unlocked.map((info) {
                final inTeam = currentTeam.contains(info.definition.id);
                final attrColor = _attrColorFor(info.definition.attribute);
                return GestureDetector(
                  onTap: inTeam
                      ? null
                      : () {
                          // 放入欄位
                          if (slotIndex < currentTeam.length) {
                            currentTeam[slotIndex] = info.definition.id;
                          } else {
                            currentTeam.add(info.definition.id);
                          }
                          playerProvider.setTeam(currentTeam);
                          idleProvider.setTeam(currentTeam);
                          Navigator.pop(ctx);
                        },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: inTeam
                          ? AppTheme.bgCard.withAlpha(80)
                          : AppTheme.bgCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: inTeam
                            ? Colors.white.withAlpha(10)
                            : attrColor.withAlpha(80),
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: _buildAgentImage(info.definition.id, info.definition, 28),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                info.definition.name,
                                style: TextStyle(
                                  color: inTeam
                                      ? AppTheme.textSecondary
                                      : AppTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${info.definition.role.label} · Lv.${info.level}',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (inTeam)
                          const Text(
                            '已上陣',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

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
      final result = catProvider.collectAllRewards(
        def.id, playerLevel, playerData: player.data,
      );
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

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => _RewardDialog(
        rewards: allRewards,
        chestCount: totalChests,
        totalGold: totalGold,
        maxRarity: maxRarity,
      ),
    );
  }

  static Widget _buildAgentImage(String agentId, CatAgentDefinition agentDef, double size) {
    final iconPath = ImageAssets.iconImage(agentId);
    if (iconPath == null) {
      return Center(
        child: GameIcon(
          assetPath: ImageAssets.attributeIcon(agentDef.attribute),
          fallbackEmoji: agentDef.attribute.emoji,
          size: size * 0.5,
        ),
      );
    }
    return Image.asset(
      iconPath,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Center(
        child: GameIcon(
          assetPath: ImageAssets.attributeIcon(agentDef.attribute),
          fallbackEmoji: agentDef.attribute.emoji,
          size: size * 0.5,
        ),
      ),
    );
  }

  static CatAgentDefinition? _findAgent(String agentId) {
    for (final a in CatAgentData.allAgents) {
      if (a.id == agentId) return a;
    }
    return null;
  }

  static CatDefinition? _findCatForAgent(CatAgentDefinition agentDef) {
    final targetColor = agentDef.attribute.blockColor;
    for (final cat in CatDefinitions.all) {
      if (cat.color == targetColor) return cat;
    }
    return null;
  }

  static Color _attrColorFor(AgentAttribute attr) {
    switch (attr) {
      case AgentAttribute.attributeA:
        return const Color(0xFFFF6B6B);
      case AgentAttribute.attributeB:
        return const Color(0xFF51CF66);
      case AgentAttribute.attributeC:
        return const Color(0xFF4DABF7);
      case AgentAttribute.attributeD:
        return const Color(0xFFFFD43B);
      case AgentAttribute.attributeE:
        return const Color(0xFFCC5DE8);
    }
  }
}

// ═══════════════════════════════════════════
// 收集寶箱按鈕
// ═══════════════════════════════════════════

class _CollectButton extends StatelessWidget {
  final int totalChests;
  final VoidCallback onTap;

  const _CollectButton({required this.totalChests, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
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
              '收集寶箱 x$totalChests',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 角色卡片 — 橫向長方形，緊湊設計
// ═══════════════════════════════════════════

class _AgentCard extends StatefulWidget {
  final CatAgentDefinition agentDef;
  final String agentId;
  final CatStatus? catStatus;
  final int playerLevel;
  final IdleProvider idleProvider;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _AgentCard({
    super.key,
    required this.agentDef,
    required this.agentId,
    this.catStatus,
    required this.playerLevel,
    required this.idleProvider,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_AgentCard> createState() => _AgentCardState();
}

class _AgentCardState extends State<_AgentCard>
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
    _checkReady();
  }

  @override
  void didUpdateWidget(covariant _AgentCard old) {
    super.didUpdateWidget(old);
    _checkReady();
  }

  void _checkReady() {
    final isReady = widget.idleProvider.isSkillReady(widget.agentId);
    if (isReady && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!isReady && _pulseController.isAnimating) {
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
    final isReady = widget.idleProvider.isSkillReady(widget.agentId);
    final energy = widget.idleProvider.getEnergy(widget.agentId);
    final cost = widget.agentDef.skill.energyCost;
    final progress = (energy / cost).clamp(0.0, 1.0);
    final attrColor = CatPanel._attrColorFor(widget.agentDef.attribute);

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) {
        final glowAlpha = isReady ? (40 + (_pulseAnim.value * 60)).round() : 0;

        return GestureDetector(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: Container(
            margin: const EdgeInsets.only(bottom: 3),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.bgCard.withAlpha(isReady ? 220 : 140),
              borderRadius: BorderRadius.circular(8),
              border: isReady
                  ? Border.all(color: attrColor.withAlpha(180), width: 1.5)
                  : Border.all(color: Colors.white.withAlpha(10), width: 0.5),
              boxShadow: isReady
                  ? [
                      BoxShadow(
                        color: attrColor.withAlpha(glowAlpha),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // 角色圖示
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CatPanel._buildAgentImage(
                    widget.agentId, widget.agentDef, 20,
                  ),
                ),
                const SizedBox(width: 5),
                // 名稱 + 能量條
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.agentDef.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // 能量條
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: Colors.white.withAlpha(15),
                          valueColor: AlwaysStoppedAnimation(
                            isReady ? attrColor : attrColor.withAlpha(120),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // 右側：能量數值 or 施放標籤
                if (isReady)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: attrColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      '施放',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  Text(
                    '$energy/$cost',
                    style: TextStyle(
                      color: AppTheme.textSecondary.withAlpha(120),
                      fontSize: 8,
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

// ═══════════════════════════════════════════
// 空欄位 — 點擊選擇角色
// ═══════════════════════════════════════════

class _EmptySlot extends StatelessWidget {
  final int index;
  final VoidCallback onTap;

  const _EmptySlot({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.bgCard.withAlpha(60),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withAlpha(15),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withAlpha(30)),
              ),
              child: const Icon(
                Icons.add,
                size: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '欄位 ${index + 1}',
              style: TextStyle(
                color: AppTheme.textSecondary.withAlpha(120),
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
// 飽食度總覽（所有貓咪）
// ═══════════════════════════════════════════

class _FoodOverview extends StatelessWidget {
  final CatProvider catProvider;
  final int playerLevel;

  const _FoodOverview({
    required this.catProvider,
    required this.playerLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.bgCard.withAlpha(60),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: CatDefinitions.all.map((catDef) {
          final cat = catProvider.cats[catDef.id];
          if (cat == null) return const SizedBox.shrink();
          final progress = cat.progress(playerLevel);
          final isFull = cat.isFull(playerLevel);
          final blockColor = catDef.color.color;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              children: [
                Text(catDef.emoji, style: const TextStyle(fontSize: 9)),
                const SizedBox(width: 3),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: isFull ? 1.0 : progress,
                      minHeight: 3,
                      backgroundColor: Colors.white.withAlpha(10),
                      valueColor: AlwaysStoppedAnimation(
                        isFull ? blockColor : blockColor.withAlpha(100),
                      ),
                    ),
                  ),
                ),
                if (isFull)
                  const Padding(
                    padding: EdgeInsets.only(left: 2),
                    child: Text('🎁', style: TextStyle(fontSize: 8)),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 寶箱獎勵彈窗
// ═══════════════════════════════════════════

class _RewardDialog extends StatefulWidget {
  final List<CatReward> rewards;
  final int chestCount;
  final int totalGold;
  final int maxRarity;

  const _RewardDialog({
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
  int _phase = 0; // 0=搖晃, 1=爆發, 2=獎勵

  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;
  late AnimationController _rewardController;
  late Animation<double> _rewardScale;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 8, end: -10), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 10, end: 0), weight: 25),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));

    _rewardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _rewardScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rewardController, curve: Curves.elasticOut),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await _shakeController.forward();
    HapticFeedback.heavyImpact();
    setState(() => _phase = 1);
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() => _phase = 2);
    _rewardController.forward();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = _rarityColor(widget.maxRarity);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 寶箱動畫
          SizedBox(
            height: 100,
            child: Center(
              child: _phase == 0
                  ? AnimatedBuilder(
                      animation: _shakeAnim,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(_shakeAnim.value, 0),
                        child: child,
                      ),
                      child: Text(
                        '🎁',
                        style: TextStyle(fontSize: 48, shadows: [
                          Shadow(color: rarityColor.withAlpha(150), blurRadius: 20),
                        ]),
                      ),
                    )
                  : Text('✨', style: TextStyle(fontSize: 48, shadows: [
                      Shadow(color: rarityColor.withAlpha(200), blurRadius: 30),
                    ])),
            ),
          ),
          // 獎勵卡片
          if (_phase >= 2)
            AnimatedBuilder(
              animation: _rewardController,
              builder: (_, child) => Transform.scale(
                scale: _rewardScale.value,
                child: child,
              ),
              child: Container(
                width: 220,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: rarityColor.withAlpha(180), width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.chestCount > 1)
                      Text(
                        '開啟 ${widget.chestCount} 個寶箱',
                        style: TextStyle(
                          color: rarityColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: rarityColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _rarityLabel(widget.maxRarity),
                        style: TextStyle(
                          color: rarityColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 金幣
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 4),
                        Text(
                          '+${widget.totalGold}',
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: rarityColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('太棒了！'),
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
      case 3: return const Color(0xFFBF6FFF);
      case 2: return const Color(0xFF4FAAFF);
      default: return const Color(0xFFAABBCC);
    }
  }

  String _rarityLabel(int rarity) {
    switch (rarity) {
      case 3: return '★★★ 稀有';
      case 2: return '★★ 進階';
      default: return '★ 普通';
    }
  }
}
