/// 貓咪特工列表畫面
/// 顯示所有角色（已解鎖 + 未解鎖），可查看詳情、升級、編入隊伍
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/cat_agent.dart';
import '../providers/player_provider.dart';
import 'agent_detail_screen.dart';

class AgentListScreen extends StatelessWidget {
  const AgentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('特工名冊'),
        backgroundColor: AppTheme.bgSecondary,
        actions: [
          // 顯示貨幣
          Consumer<PlayerProvider>(
            builder: (_, provider, __) => Row(
              children: [
                _CurrencyChip(
                  icon: '🪙',
                  amount: provider.data.gold,
                ),
                const SizedBox(width: 8),
                _CurrencyChip(
                  icon: '💎',
                  amount: provider.data.diamonds,
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ],
      ),
      body: Consumer<PlayerProvider>(
        builder: (context, provider, _) {
          final agents = provider.allAgentInfos;
          return Column(
            children: [
              // 隊伍預覽
              _TeamPreview(teamAgents: provider.teamAgents),
              const Divider(color: AppTheme.bgCard, height: 1),
              // 角色列表
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: agents.length,
                  itemBuilder: (context, index) {
                    return _AgentCard(
                      agentInfo: agents[index],
                      isInTeam: provider.data.team.contains(
                        agents[index].definition.id,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 隊伍預覽列
class _TeamPreview extends StatelessWidget {
  final List<AgentInfo> teamAgents;

  const _TeamPreview({required this.teamAgents});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.bgSecondary.withValues(alpha: 0.5),
      child: Row(
        children: [
          const Text(
            '出擊隊伍',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          ...List.generate(3, (i) {
            if (i < teamAgents.length) {
              final agent = teamAgents[i];
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: agent.definition.attribute.blockColor.color.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(
                    color: agent.definition.attribute.blockColor.color.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  '${agent.definition.attribute.emoji} ${agent.definition.name}',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                  ),
                ),
              );
            } else {
              return Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Text(
                  '空位',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              );
            }
          }),
        ],
      ),
    );
  }
}

/// 角色卡片
class _AgentCard extends StatelessWidget {
  final AgentInfo agentInfo;
  final bool isInTeam;

  const _AgentCard({
    required this.agentInfo,
    required this.isInTeam,
  });

  @override
  Widget build(BuildContext context) {
    final def = agentInfo.definition;
    final isUnlocked = agentInfo.isUnlocked;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isUnlocked ? AppTheme.bgCard : AppTheme.bgCard.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: isInTeam
            ? BorderSide(color: def.attribute.blockColor.color, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        onTap: () => _showAgentDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // 頭像區域
              _AgentAvatar(
                attribute: def.attribute,
                rarity: def.rarity,
                isUnlocked: isUnlocked,
              ),
              const SizedBox(width: 14),
              // 資訊區域
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 名稱 + 稀有度
                    Row(
                      children: [
                        Text(
                          isUnlocked ? agentInfo.displayName : '???',
                          style: TextStyle(
                            color: isUnlocked
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _RarityBadge(rarity: def.rarity),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // 品種 + 職業
                    Text(
                      isUnlocked
                          ? '${def.breed} · ${def.role.label}'
                          : def.role.label,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    if (isUnlocked) ...[
                      const SizedBox(height: 8),
                      // 等級 + 屬性
                      Row(
                        children: [
                          Text(
                            'Lv.${agentInfo.level}',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          _StatChip('ATK', agentInfo.atk),
                          const SizedBox(width: 6),
                          _StatChip('DEF', agentInfo.def),
                          const SizedBox(width: 6),
                          _StatChip('HP', agentInfo.hp),
                        ],
                      ),
                    ],
                    if (!isUnlocked) ...[
                      const SizedBox(height: 8),
                      _UnlockInfo(condition: def.unlockCondition),
                    ],
                  ],
                ),
              ),
              // 隊伍 / 解鎖按鈕
              if (isUnlocked)
                _TeamToggleButton(
                  agentId: def.id,
                  isInTeam: isInTeam,
                )
              else
                _UnlockButton(agentId: def.id),
            ],
          ),
        ),
      ),
    );
  }

  void _showAgentDetail(BuildContext context) {
    final def = agentInfo.definition;

    // 已解鎖角色：導航到詳情頁（含天賦/技能/被動 Tab）
    if (agentInfo.isUnlocked) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AgentDetailScreen(definition: def),
        ),
      );
      return;
    }

    // 未解鎖角色：仍用底部彈窗
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 名稱
            Row(
              children: [
                Text(
                  '${def.attribute.emoji} ${def.name}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                _RarityBadge(rarity: def.rarity),
              ],
            ),
            Text(
              '${def.codename} · ${def.breed} · ${def.role.label}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            // 技能
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎯 ${def.skill.name}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    def.skill.description,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '能量消耗: ${def.skill.energyCost}',
                    style: TextStyle(
                      color: Colors.amber.shade300,
                      fontSize: 12,
                    ),
                  ),
                  if (def.skill.boardEffect != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '🧩 ${def.skill.boardEffect!.description}',
                      style: TextStyle(
                        color: Colors.cyan.shade300,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 被動
            Text(
              '💡 被動：${def.passiveDescription}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
            if (agentInfo.isUnlocked) ...[
              const SizedBox(height: 16),
              // 屬性面板
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BigStat('ATK', agentInfo.atk),
                  _BigStat('DEF', agentInfo.def),
                  _BigStat('HP', agentInfo.hp),
                  _BigStat('LV', agentInfo.level),
                ],
              ),
              const SizedBox(height: 16),
              // EXP 進度條
              _ExpBar(agentInfo: agentInfo),
              const SizedBox(height: 12),
              // 升級按鈕
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: agentInfo.level < def.maxLevel
                      ? () {
                          // MVP: 消耗 50 金幣獲得 30 EXP
                          final provider = context.read<PlayerProvider>();
                          if (provider.data.gold >= 50) {
                            provider.addGold(-50);
                            provider.levelUpAgent(def.id, 30);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('獲得 30 EXP！(消耗 50 金幣)'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('金幣不足！'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    agentInfo.level < def.maxLevel
                        ? '訓練 (🪙50 → +30 EXP)'
                        : '已達最高等級',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── 輔助 Widget ───

class _CurrencyChip extends StatelessWidget {
  final String icon;
  final int amount;

  const _CurrencyChip({required this.icon, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '$amount',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentAvatar extends StatelessWidget {
  final AgentAttribute attribute;
  final AgentRarity rarity;
  final bool isUnlocked;

  const _AgentAvatar({
    required this.attribute,
    required this.rarity,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: isUnlocked
            ? attribute.blockColor.color.withValues(alpha: 0.3)
            : Colors.grey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: isUnlocked
              ? attribute.blockColor.color.withValues(alpha: 0.6)
              : Colors.grey.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          isUnlocked ? attribute.emoji : '🔒',
          style: const TextStyle(fontSize: 28),
        ),
      ),
    );
  }
}

class _RarityBadge extends StatelessWidget {
  final AgentRarity rarity;

  const _RarityBadge({required this.rarity});

  Color get _color {
    switch (rarity) {
      case AgentRarity.n:
        return Colors.grey;
      case AgentRarity.r:
        return Colors.blue;
      case AgentRarity.sr:
        return Colors.purple;
      case AgentRarity.ssr:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _color, width: 1),
      ),
      child: Text(
        rarity.display,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;

  const _StatChip(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String label;
  final int value;

  const _BigStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ExpBar extends StatelessWidget {
  final AgentInfo agentInfo;

  const _ExpBar({required this.agentInfo});

  @override
  Widget build(BuildContext context) {
    final def = agentInfo.definition;
    final currentLevelExp = def.expRequiredForLevel(agentInfo.level);
    final nextLevelExp = def.expRequiredForLevel(agentInfo.level + 1);
    final expForThisLevel = nextLevelExp - currentLevelExp;
    final progress = expForThisLevel > 0
        ? agentInfo.currentExp / expForThisLevel
        : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'EXP',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            Text(
              '${agentInfo.currentExp} / $expForThisLevel',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
          ),
        ),
      ],
    );
  }
}

class _UnlockInfo extends StatelessWidget {
  final UnlockCondition condition;

  const _UnlockInfo({required this.condition});

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    if (condition.stageRequirement != null) {
      parts.add('通關 ${condition.stageRequirement}');
    }
    if (condition.requireAllStars == true) {
      parts.add('全三星');
    }
    if (condition.goldCost > 0) {
      parts.add('🪙${condition.goldCost}');
    }
    if (condition.diamondCost > 0) {
      parts.add('💎${condition.diamondCost}');
    }

    return Text(
      '解鎖條件：${parts.join(' + ')}',
      style: const TextStyle(
        color: Colors.amber,
        fontSize: 12,
      ),
    );
  }
}

class _TeamToggleButton extends StatelessWidget {
  final String agentId;
  final bool isInTeam;

  const _TeamToggleButton({
    required this.agentId,
    required this.isInTeam,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        context.read<PlayerProvider>().toggleTeamMember(agentId);
      },
      icon: Icon(
        isInTeam ? Icons.star : Icons.star_border,
        color: isInTeam ? Colors.amber : Colors.white38,
        size: 28,
      ),
    );
  }
}

class _UnlockButton extends StatelessWidget {
  final String agentId;

  const _UnlockButton({required this.agentId});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final provider = context.read<PlayerProvider>();
        final success = await provider.unlockAgent(agentId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success ? '解鎖成功！' : '條件不足'),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accentPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
      ),
      child: const Text('解鎖', style: TextStyle(fontSize: 13)),
    );
  }
}
