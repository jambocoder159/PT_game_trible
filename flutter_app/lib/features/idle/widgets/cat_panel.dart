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
import '../providers/idle_provider.dart';

/// 右側貓咪面板 — 顯示實際擁有的角色，點擊施放技能
class CatPanel extends StatelessWidget {
  /// GlobalKey map，讓 HomeScreen 能找到每隻貓的位置（用於能量球飛行）
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

        // 自動收集所有貓咪寶箱
        _autoCollectChests(context, catProvider, playerProvider, playerLevel);

        return Column(
          children: [
            // 顯示隊伍中的角色卡
            ...team.map((agentId) {
              final agentDef = _findAgent(agentId);
              if (agentDef == null) return const SizedBox.shrink();

              // 找到對應的貓
              final catDef = _findCatForAgent(agentDef);
              final catStatus = catDef != null ? catProvider.cats[catDef.id] : null;

              catKeys.putIfAbsent(agentId, () => GlobalKey());

              return Expanded(
                child: _AgentCard(
                  key: catKeys[agentId],
                  agentDef: agentDef,
                  agentId: agentId,
                  catDef: catDef,
                  catStatus: catStatus,
                  playerLevel: playerLevel,
                  idleProvider: idleProvider,
                  onTapDetail: () => _showAgentQuickView(
                    context, agentDef, agentId, catDef, catStatus, playerLevel,
                  ),
                ),
              );
            }),

            // 未編入隊伍的貓咪（只顯示飽食度，不佔太多空間）
            ...CatDefinitions.all.where((catDef) {
              // 過濾掉已經在隊伍中顯示的貓咪
              final agent = _findAgentForCat(catDef);
              return agent == null || !team.contains(agent.id);
            }).map((catDef) {
              final cat = catProvider.cats[catDef.id];
              if (cat == null) return const SizedBox.shrink();
              catKeys.putIfAbsent(catDef.id, () => GlobalKey());
              return _MiniCatRow(
                key: catKeys[catDef.id],
                definition: catDef,
                status: cat,
                playerLevel: playerLevel,
              );
            }),
          ],
        );
      },
    );
  }

  static CatAgentDefinition? _findAgent(String agentId) {
    for (final a in CatAgentData.allAgents) {
      if (a.id == agentId) return a;
    }
    return null;
  }

  static CatAgentDefinition? _findAgentForCat(CatDefinition catDef) {
    final targetColor = catDef.color;
    for (final agent in CatAgentData.allAgents) {
      if (agent.attribute.blockColor == targetColor) return agent;
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

  /// 自動收集所有已滿的貓咪寶箱
  void _autoCollectChests(
    BuildContext context,
    CatProvider catProvider,
    PlayerProvider playerProvider,
    int playerLevel,
  ) {
    for (final def in CatDefinitions.all) {
      final cat = catProvider.cats[def.id];
      if (cat != null && cat.isFull(playerLevel)) {
        final result = catProvider.collectAllRewards(
          def.id, playerLevel, playerData: playerProvider.data,
        );
        if (result != null) {
          final (rewards, _) = result;
          final totalGold = rewards.fold<int>(0, (sum, r) => sum + r.quantity);
          playerProvider.addGold(totalGold);
        }
      }
    }
  }

  void _showAgentQuickView(
    BuildContext context,
    CatAgentDefinition agentDef,
    String agentId,
    CatDefinition? catDef,
    CatStatus? catStatus,
    int playerLevel,
  ) {
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
      builder: (_) => _AgentQuickViewSheet(
        agentDef: agentDef,
        agentInfo: agentInfo,
        catDef: catDef,
        catStatus: catStatus,
        playerLevel: playerLevel,
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 角色卡片 — 顯示技能能量 + 點擊施放
// ═══════════════════════════════════════════

class _AgentCard extends StatefulWidget {
  final CatAgentDefinition agentDef;
  final String agentId;
  final CatDefinition? catDef;
  final CatStatus? catStatus;
  final int playerLevel;
  final IdleProvider idleProvider;
  final VoidCallback? onTapDetail;

  const _AgentCard({
    super.key,
    required this.agentDef,
    required this.agentId,
    this.catDef,
    this.catStatus,
    required this.playerLevel,
    required this.idleProvider,
    this.onTapDetail,
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
    final attrColor = _attrColor(widget.agentDef.attribute);

    // 飽食度進度（如果有對應的貓）
    final foodProgress = widget.catStatus?.progress(widget.playerLevel) ?? 0.0;

    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, child) {
        final glowAlpha = isReady ? (60 + (_pulseAnim.value * 80)).round() : 0;
        final borderWidth = isReady ? 1.5 + _pulseAnim.value * 0.5 : 0.0;

        return GestureDetector(
          onTap: isReady
              ? () {
                  HapticFeedback.mediumImpact();
                  widget.idleProvider.activateSkill(widget.agentId);
                }
              : widget.onTapDetail,
          onLongPress: widget.onTapDetail,
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.bgCard.withAlpha(isReady ? 220 : 140),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              border: isReady
                  ? Border.all(
                      color: attrColor.withAlpha(180),
                      width: borderWidth,
                    )
                  : null,
              boxShadow: isReady
                  ? [
                      BoxShadow(
                        color: attrColor.withAlpha(glowAlpha),
                        blurRadius: 8 + _pulseAnim.value * 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 角色 emoji + 名稱
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.agentDef.attribute.emoji,
                      style: TextStyle(fontSize: isReady ? 16 : 14),
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        widget.agentDef.name,
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

                // 技能能量條
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: Colors.white.withAlpha(20),
                    valueColor: AlwaysStoppedAnimation(
                      isReady ? attrColor : attrColor.withAlpha(150),
                    ),
                  ),
                ),

                // 能量數值
                Text(
                  '$energy/$cost',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withAlpha(150),
                    fontSize: 8,
                  ),
                ),

                // 飽食度小條（如果有對應貓咪）
                if (widget.catStatus != null) ...[
                  const SizedBox(height: 1),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: foodProgress,
                      minHeight: 2,
                      backgroundColor: Colors.white.withAlpha(10),
                      valueColor: AlwaysStoppedAnimation(
                        Colors.amber.withAlpha(120),
                      ),
                    ),
                  ),
                ],

                // 施放按鈕
                if (isReady)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [attrColor, attrColor.withAlpha(180)],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: attrColor.withAlpha(80 + glowAlpha ~/ 2),
                          blurRadius: 4 + _pulseAnim.value * 4,
                        ),
                      ],
                    ),
                    child: Text(
                      '施放技能',
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

  Color _attrColor(AgentAttribute attr) {
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
// 未在隊伍中的貓咪 — 只顯示迷你飽食度條
// ═══════════════════════════════════════════

class _MiniCatRow extends StatelessWidget {
  final CatDefinition definition;
  final CatStatus status;
  final int playerLevel;

  const _MiniCatRow({
    super.key,
    required this.definition,
    required this.status,
    required this.playerLevel,
  });

  @override
  Widget build(BuildContext context) {
    final progress = status.progress(playerLevel);
    final blockColor = definition.color.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.bgCard.withAlpha(80),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Text(definition.emoji, style: const TextStyle(fontSize: 10)),
          const SizedBox(width: 4),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: Colors.white.withAlpha(10),
                valueColor: AlwaysStoppedAnimation(blockColor.withAlpha(120)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// 角色快速查看彈窗
// ═══════════════════════════════════════════

class _AgentQuickViewSheet extends StatelessWidget {
  final CatAgentDefinition agentDef;
  final AgentInfo agentInfo;
  final CatDefinition? catDef;
  final CatStatus? catStatus;
  final int playerLevel;

  const _AgentQuickViewSheet({
    required this.agentDef,
    required this.agentInfo,
    this.catDef,
    this.catStatus,
    required this.playerLevel,
  });

  @override
  Widget build(BuildContext context) {
    final attrColor = agentDef.attribute.blockColor.color;
    final isUnlocked = agentInfo.isUnlocked;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拉條
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // 角色頭像 + 名稱
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: attrColor.withAlpha(60),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: attrColor.withAlpha(150), width: 2),
                  ),
                  child: Center(
                    child: Text(agentDef.attribute.emoji,
                        style: const TextStyle(fontSize: 24)),
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
                            agentDef.name,
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
                                horizontal: 6, vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: attrColor.withAlpha(40),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: attrColor.withAlpha(120)),
                              ),
                              child: Text(
                                'Lv.${agentInfo.level}',
                                style: TextStyle(
                                  color: attrColor,
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
                        '${agentDef.breed} · ${agentDef.role.label}',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 技能資訊
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withAlpha(15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('⚔️', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        agentDef.skill.name,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '⚡ ${agentDef.skill.energyCost}',
                        style: TextStyle(
                          color: attrColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    agentDef.skill.description,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  if (agentDef.skill.boardEffect != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: attrColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '🎯 ${agentDef.skill.boardEffect!.description}',
                        style: TextStyle(
                          color: attrColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),

            // 使用說明
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '消除方塊累積能量，能量滿時點擊角色卡片施放技能',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
