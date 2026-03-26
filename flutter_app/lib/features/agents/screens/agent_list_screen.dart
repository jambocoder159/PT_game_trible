/// 貓咪特工列表畫面 — 全新設計
/// 2列肖像網格 + 篩選/排序 + 底部固定隊伍欄
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/cat_agent_data.dart';
import '../../../config/image_assets.dart';
import '../../../config/theme.dart';
import '../../../core/models/cat_agent.dart';
import '../../../core/widgets/attribute_badge.dart';
import '../providers/player_provider.dart';
import '../widgets/agent_unlock_animation.dart';
import 'agent_detail_screen.dart';

// ─── 排序方式 ───
enum AgentSortBy { rarity, level, atk, name }

class AgentListScreen extends StatefulWidget {
  const AgentListScreen({super.key});

  @override
  State<AgentListScreen> createState() => _AgentListScreenState();
}

class _AgentListScreenState extends State<AgentListScreen> {
  AgentAttribute? _attributeFilter;
  AgentRarity? _rarityFilter;
  AgentSortBy _sortBy = AgentSortBy.rarity;

  List<AgentInfo> _filterAndSort(List<AgentInfo> agents) {
    var filtered = agents.where((a) {
      if (_attributeFilter != null &&
          a.definition.attribute != _attributeFilter) {
        return false;
      }
      if (_rarityFilter != null && a.definition.rarity != _rarityFilter) {
        return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      // 已解鎖優先
      if (a.isUnlocked != b.isUnlocked) {
        return a.isUnlocked ? -1 : 1;
      }
      switch (_sortBy) {
        case AgentSortBy.rarity:
          return b.definition.rarity.tier.compareTo(a.definition.rarity.tier);
        case AgentSortBy.level:
          return b.level.compareTo(a.level);
        case AgentSortBy.atk:
          return b.atk.compareTo(a.atk);
        case AgentSortBy.name:
          return a.definition.name.compareTo(b.definition.name);
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Consumer<PlayerProvider>(
        builder: (context, provider, _) {
          final agents = _filterAndSort(provider.allAgentInfos);

          return Column(
            children: [
              // 主要內容區（可滾動）
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    // ─── SliverAppBar ───
                    SliverAppBar(
                      automaticallyImplyLeading: false,
                      title: const Text('特工名冊'),
                      backgroundColor: AppTheme.bgSecondary,
                      pinned: true,
                      floating: true,
                      actions: [
                        _CurrencyChip(
                          iconPath: ImageAssets.coin,
                          fallbackIcon: '🪙',
                          amount: provider.data.gold,
                        ),
                        const SizedBox(width: 8),
                        _CurrencyChip(
                          iconPath: ImageAssets.diamond,
                          fallbackIcon: '💎',
                          amount: provider.data.diamonds,
                        ),
                        const SizedBox(width: 12),
                      ],
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(84),
                        child: _FilterSection(
                          attributeFilter: _attributeFilter,
                          rarityFilter: _rarityFilter,
                          sortBy: _sortBy,
                          onAttributeChanged: (v) =>
                              setState(() => _attributeFilter = v),
                          onRarityChanged: (v) =>
                              setState(() => _rarityFilter = v),
                          onSortChanged: (v) =>
                              setState(() => _sortBy = v),
                        ),
                      ),
                    ),

                    // ─── 角色網格 ───
                    SliverPadding(
                      padding: const EdgeInsets.all(10),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.72,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final agent = agents[index];
                            return _AgentPortraitCard(
                              agentInfo: agent,
                              isInTeam: provider.data.team
                                  .contains(agent.definition.id),
                              index: index,
                            );
                          },
                          childCount: agents.length,
                        ),
                      ),
                    ),

                    // 底部間距（給隊伍欄留空間）
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 80),
                    ),
                  ],
                ),
              ),

              // ─── 固定底部隊伍欄 ───
              _BottomTeamBar(teamAgents: provider.teamAgents),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════
// 篩選區域
// ═══════════════════════════════════════

class _FilterSection extends StatelessWidget {
  final AgentAttribute? attributeFilter;
  final AgentRarity? rarityFilter;
  final AgentSortBy sortBy;
  final ValueChanged<AgentAttribute?> onAttributeChanged;
  final ValueChanged<AgentRarity?> onRarityChanged;
  final ValueChanged<AgentSortBy> onSortChanged;

  const _FilterSection({
    required this.attributeFilter,
    required this.rarityFilter,
    required this.sortBy,
    required this.onAttributeChanged,
    required this.onRarityChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bgSecondary.withAlpha(200),
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          // 屬性篩選
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _FilterPill(
                  label: '全部',
                  isSelected: attributeFilter == null,
                  onTap: () => onAttributeChanged(null),
                ),
                const SizedBox(width: 6),
                ...AgentAttribute.values.map((attr) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _FilterPill(
                        label: attr.emoji,
                        color: attr.blockColor.color,
                        isSelected: attributeFilter == attr,
                        onTap: () => onAttributeChanged(
                          attributeFilter == attr ? null : attr,
                        ),
                      ),
                    )),
                const SizedBox(width: 8),
                // 稀有度篩選
                ...AgentRarity.values.reversed.map((r) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _FilterPill(
                        label: r.display,
                        color: AppTheme.rarityColor(r.display),
                        isSelected: rarityFilter == r,
                        onTap: () => onRarityChanged(
                          rarityFilter == r ? null : r,
                        ),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // 排序
          SizedBox(
            height: 30,
            child: Row(
              children: [
                const SizedBox(width: 14),
                Text(
                  '排序',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withAlpha(150),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 8),
                ...[
                  (AgentSortBy.rarity, '稀有度'),
                  (AgentSortBy.level, '等級'),
                  (AgentSortBy.atk, 'ATK'),
                  (AgentSortBy.name, '名稱'),
                ].map((e) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _SortChip(
                        label: e.$2,
                        isSelected: sortBy == e.$1,
                        onTap: () => onSortChanged(e.$1),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final Color? color;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.accentPrimary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? c.withAlpha(50) : Colors.white.withAlpha(8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? c.withAlpha(180) : Colors.white.withAlpha(20),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? c : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SortChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentSecondary.withAlpha(40)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppTheme.accentSecondary
                : AppTheme.textSecondary.withAlpha(120),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// 角色肖像卡片
// ═══════════════════════════════════════

class _AgentPortraitCard extends StatelessWidget {
  final AgentInfo agentInfo;
  final bool isInTeam;
  final int index;

  const _AgentPortraitCard({
    required this.agentInfo,
    required this.isInTeam,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final def = agentInfo.definition;
    final isUnlocked = agentInfo.isUnlocked;
    final rarityColors = AppTheme.rarityGradient(def.rarity.display);
    final glowColor = AppTheme.rarityColor(def.rarity.display);
    final avatarPath = ImageAssets.avatarImage(def.id);
    final charPath = ImageAssets.characterImage(def.id);

    return GestureDetector(
      onTap: () => _onTap(context),
      onLongPress: () => _onLongPress(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: isInTeam
                ? Colors.amber.withAlpha(200)
                : isUnlocked
                    ? glowColor.withAlpha(100)
                    : Colors.white.withAlpha(15),
            width: isInTeam ? 2.5 : 1.5,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: glowColor.withAlpha(isInTeam ? 60 : 30),
                    blurRadius: isInTeam ? 16 : 8,
                    spreadRadius: isInTeam ? 2 : 0,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge - 1.5),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ─── 背景 ───
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isUnlocked
                        ? [
                            rarityColors[0].withAlpha(40),
                            AppTheme.bgCard,
                          ]
                        : [
                            Colors.grey.withAlpha(20),
                            AppTheme.bgCard.withAlpha(150),
                          ],
                  ),
                ),
              ),

              // ─── 角色立繪/頭像 ───
              if (isUnlocked)
                Positioned.fill(
                  child: charPath != null
                      ? Image.asset(
                          charPath,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => avatarPath != null
                              ? Image.asset(
                                  avatarPath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _EmojiAvatar(emoji: def.attribute.emoji),
                                )
                              : _EmojiAvatar(emoji: def.attribute.emoji),
                        )
                      : avatarPath != null
                          ? Image.asset(
                              avatarPath,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _EmojiAvatar(emoji: def.attribute.emoji),
                            )
                          : _EmojiAvatar(emoji: def.attribute.emoji),
                )
              else
                Center(
                  child: GameIcon(
                    assetPath: ImageAssets.lock,
                    fallbackEmoji: '🔒',
                    size: 40,
                  ),
                ),

              // ─── 未解鎖灰階覆蓋 ───
              if (!isUnlocked)
                Container(
                  color: Colors.black.withAlpha(120),
                ),

              // ─── 底部漸層遮罩 + 資訊 ───
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withAlpha(180),
                        Colors.black.withAlpha(220),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 名稱
                      Text(
                        isUnlocked ? agentInfo.displayName : '???',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      // 職業 + 等級
                      Row(
                        children: [
                          Text(
                            def.role.label,
                            style: TextStyle(
                              color: Colors.white.withAlpha(180),
                              fontSize: 11,
                            ),
                          ),
                          if (isUnlocked) ...[
                            const Spacer(),
                            Text(
                              'Lv.${agentInfo.level}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ─── 左上：屬性徽章 ───
              Positioned(
                top: 6,
                left: 6,
                child: AttributeBadge(attribute: def.attribute, size: 26),
              ),

              // ─── 右上：稀有度標籤 ───
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: glowColor.withAlpha(isUnlocked ? 180 : 80),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(80),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    def.rarity.display,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // ─── 隊伍標記（金色星星） ───
              if (isInTeam)
                Positioned(
                  top: 6,
                  right: 6 + 30.0 + 6,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Colors.amber.withAlpha(200),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withAlpha(100),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
    HapticFeedback.lightImpact();
    final def = agentInfo.definition;

    if (agentInfo.isUnlocked) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AgentDetailScreen(definition: def),
        ),
      );
    } else {
      _showLockedSheet(context);
    }
  }

  void _onLongPress(BuildContext context) {
    HapticFeedback.mediumImpact();
    _showQuickPreview(context);
  }

  void _showQuickPreview(BuildContext context) {
    final def = agentInfo.definition;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _QuickPreviewSheet(agentInfo: agentInfo),
    );
  }

  void _showLockedSheet(BuildContext context) {
    final def = agentInfo.definition;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _LockedAgentSheet(
        agentInfo: agentInfo,
        onUnlock: () {
          Navigator.pop(ctx);
          _tryUnlock(context);
        },
      ),
    );
  }

  void _tryUnlock(BuildContext context) async {
    final provider = context.read<PlayerProvider>();
    final success = await provider.unlockAgent(agentInfo.definition.id);
    if (context.mounted) {
      if (success) {
        final def = CatAgentData.getById(agentInfo.definition.id);
        if (def != null) {
          final overlay = Overlay.of(context);
          late OverlayEntry entry;
          entry = OverlayEntry(
            builder: (_) => AgentUnlockAnimation(
              definition: def,
              onComplete: () => entry.remove(),
            ),
          );
          overlay.insert(entry);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('條件不足'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ═══════════════════════════════════════
// 快速預覽 BottomSheet
// ═══════════════════════════════════════

class _QuickPreviewSheet extends StatelessWidget {
  final AgentInfo agentInfo;

  const _QuickPreviewSheet({required this.agentInfo});

  @override
  Widget build(BuildContext context) {
    final def = agentInfo.definition;
    final isUnlocked = agentInfo.isUnlocked;
    final rarityColor = AppTheme.rarityColor(def.rarity.display);

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

            // 名稱 + 稀有度
            Row(
              children: [
                GameIcon(
                  assetPath: ImageAssets.attributeIcon(def.attribute),
                  fallbackEmoji: def.attribute.emoji,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  isUnlocked ? agentInfo.displayName : def.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: rarityColor.withAlpha(40),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: rarityColor, width: 1),
                  ),
                  child: Text(
                    def.rarity.display,
                    style: TextStyle(
                      color: rarityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${def.codename} · ${def.breed} · ${def.role.label}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),

            if (isUnlocked) ...[
              const SizedBox(height: 16),
              // 屬性面板
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _QuickStat('ATK', agentInfo.atk),
                  _QuickStat('DEF', agentInfo.def),
                  _QuickStat('HP', agentInfo.hp),
                  _QuickStat('LV', agentInfo.level),
                ],
              ),
            ],

            const SizedBox(height: 16),
            // 技能概要
            Container(
              width: double.infinity,
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
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    def.skill.description,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // 隊伍切換按鈕
            if (isUnlocked) ...[
              const SizedBox(height: 12),
              Consumer<PlayerProvider>(
                builder: (context, provider, _) {
                  final inTeam = provider.data.team.contains(def.id);
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        provider.toggleTeamMember(def.id);
                        HapticFeedback.lightImpact();
                      },
                      icon: Icon(
                        inTeam ? Icons.star : Icons.star_border,
                        size: 18,
                      ),
                      label: Text(inTeam ? '移出隊伍' : '加入隊伍'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: inTeam
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final int value;

  const _QuickStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════
// 鎖定角色 BottomSheet
// ═══════════════════════════════════════

class _LockedAgentSheet extends StatelessWidget {
  final AgentInfo agentInfo;
  final VoidCallback onUnlock;

  const _LockedAgentSheet({
    required this.agentInfo,
    required this.onUnlock,
  });

  @override
  Widget build(BuildContext context) {
    final def = agentInfo.definition;
    final condition = def.unlockCondition;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
            const SizedBox(height: 16),
            Text(
              def.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${def.breed} · ${def.role.label}',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),

            // 解鎖條件
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: Colors.amber.withAlpha(60)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '解鎖條件',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (condition.stageRequirement != null)
                    _ConditionRow('通關', condition.stageRequirement!),
                  if (condition.requireAllStars == true)
                    _ConditionRow('要求', '全三星'),
                  if (condition.goldCost > 0)
                    _ConditionRow('🪙 金幣', '${condition.goldCost}'),
                  if (condition.diamondCost > 0)
                    _ConditionRow('💎 鑽石', '${condition.diamondCost}'),
                ],
              ),
            ),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onUnlock,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('解鎖', style: TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConditionRow extends StatelessWidget {
  final String label;
  final String value;

  const _ConditionRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Text(
            value,
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

// ═══════════════════════════════════════
// 底部固定隊伍欄
// ═══════════════════════════════════════

class _BottomTeamBar extends StatelessWidget {
  final List<AgentInfo> teamAgents;

  const _BottomTeamBar({required this.teamAgents});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        border: Border(
          top: BorderSide(color: Colors.white.withAlpha(15)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 3 個隊伍槽位
            ...List.generate(3, (i) {
              if (i < teamAgents.length) {
                final agent = teamAgents[i];
                final avatarPath =
                    ImageAssets.avatarImage(agent.definition.id);
                return _TeamSlot(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: avatarPath != null
                        ? Image.asset(
                            avatarPath,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _SlotEmoji(
                              agent.definition.attribute.emoji,
                            ),
                          )
                        : _SlotEmoji(agent.definition.attribute.emoji),
                  ),
                  borderColor:
                      agent.definition.attribute.blockColor.color,
                );
              }
              return _TeamSlot(
                child: Icon(
                  Icons.add,
                  color: Colors.white.withAlpha(60),
                  size: 20,
                ),
                borderColor: Colors.white.withAlpha(30),
              );
            }),

            const SizedBox(width: 12),

            // 戰力概要
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '出擊隊伍',
                    style: TextStyle(
                      color: AppTheme.textSecondary.withAlpha(180),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    teamAgents.isEmpty
                        ? '尚未編排'
                        : 'ATK ${teamAgents.fold<int>(0, (sum, a) => sum + a.atk)}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamSlot extends StatelessWidget {
  final Widget child;
  final Color borderColor;

  const _TeamSlot({
    required this.child,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Center(child: child),
    );
  }
}

class _SlotEmoji extends StatelessWidget {
  final String emoji;

  const _SlotEmoji(this.emoji);

  @override
  Widget build(BuildContext context) {
    return Text(emoji, style: const TextStyle(fontSize: 22));
  }
}

class _EmojiAvatar extends StatelessWidget {
  final String emoji;

  const _EmojiAvatar({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(emoji, style: const TextStyle(fontSize: 40)),
    );
  }
}

// ═══════════════════════════════════════
// 貨幣顯示 Chip
// ═══════════════════════════════════════

class _CurrencyChip extends StatelessWidget {
  final String iconPath;
  final String fallbackIcon;
  final int amount;

  const _CurrencyChip({
    required this.iconPath,
    required this.fallbackIcon,
    required this.amount,
  });

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
          GameIcon(
              assetPath: iconPath, fallbackEmoji: fallbackIcon, size: 16),
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
