/// 玩家資訊頁面 — 點心屋風格
/// 個人資料卡 + 2×3 統計網格 + 章節進度 + 角色收集進度
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/image_assets.dart';
import '../../../config/stage_data.dart';
import '../../../config/theme.dart';
import '../../agents/providers/player_provider.dart';

class PlayerProfileScreen extends StatelessWidget {
  const PlayerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Consumer<PlayerProvider>(
        builder: (context, provider, _) {
          if (!provider.isInitialized) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accentSecondary),
            );
          }
          return CustomScrollView(
            slivers: [
              // ─── 收合式頂部 ───
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: AppTheme.bgSecondary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: _ProfileHeader(provider: provider),
                ),
              ),

              // ─── 主體內容 ───
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ═══ 統計數據網格 ═══
                    _SectionTitle(icon: Icons.analytics_rounded, title: '生涯數據'),
                    const SizedBox(height: 8),
                    _StatsGrid(provider: provider),

                    const SizedBox(height: 24),

                    // ═══ 章節進度 ═══
                    _SectionTitle(icon: Icons.map_rounded, title: '章節進度'),
                    const SizedBox(height: 8),
                    _ChapterProgressList(provider: provider),

                    const SizedBox(height: 24),

                    // ═══ 角色收集 ═══
                    _SectionTitle(icon: Icons.people_rounded, title: '夥伴收集'),
                    const SizedBox(height: 8),
                    _AgentCollectionGrid(provider: provider),

                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════
// 頂部檔案卡
// ═══════════════════════════════════════

class _ProfileHeader extends StatelessWidget {
  final PlayerProvider provider;
  const _ProfileHeader({required this.provider});

  @override
  Widget build(BuildContext context) {
    final data = provider.data;
    final expNeeded = data.playerLevel * 100;
    final expProgress =
        expNeeded > 0 ? (data.playerExp / expNeeded).clamp(0.0, 1.0) : 0.0;

    // 取得隊長資訊（第一個隊員）
    final teamLeader = provider.teamAgents.isNotEmpty
        ? provider.teamAgents.first
        : null;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.bgSecondary,
            AppTheme.bgPrimary,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
          child: Row(
            children: [
              // 隊長頭像
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.accentSecondary,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentSecondary.withAlpha(60),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: teamLeader != null &&
                          ImageAssets.avatarImage(teamLeader.definition.id) !=
                              null
                      ? Image.asset(
                          ImageAssets.avatarImage(teamLeader.definition.id)!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppTheme.bgCard,
                            child: const Icon(Icons.person,
                                color: AppTheme.textSecondary, size: 40),
                          ),
                        )
                      : Container(
                          color: AppTheme.bgCard,
                          child: const Icon(Icons.person,
                              color: AppTheme.textSecondary, size: 40),
                        ),
                ),
              ),
              const SizedBox(width: 16),

              // 玩家資訊
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 等級標籤
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppTheme.accentPrimary,
                            AppTheme.accentSecondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Lv.${data.playerLevel}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppTheme.fontBodyLg,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 經驗條
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: expProgress,
                            minHeight: 8,
                            backgroundColor: AppTheme.bgSecondary,
                            valueColor: const AlwaysStoppedAnimation(
                                AppTheme.accentSecondary),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'EXP ${data.playerExp} / $expNeeded',
                          style: TextStyle(
                            color: AppTheme.textSecondary.withAlpha(180),
                            fontSize: AppTheme.fontLabelLg,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 貨幣列
                    Row(
                      children: [
                        _CurrencyBadge(
                          icon: Icons.monetization_on_rounded,
                          color: Colors.amber,
                          value: data.gold,
                        ),
                        const SizedBox(width: 12),
                        _CurrencyBadge(
                          icon: Icons.diamond_rounded,
                          color: Colors.cyanAccent,
                          value: data.diamonds,
                        ),
                        const SizedBox(width: 12),
                        _CurrencyBadge(
                          icon: Icons.bolt_rounded,
                          color: Colors.greenAccent,
                          value: data.stamina,
                          suffix: '/${data.maxStamina}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencyBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;
  final String? suffix;

  const _CurrencyBadge({
    required this.icon,
    required this.color,
    required this.value,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        Text(
          '$value${suffix ?? ''}',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: AppTheme.fontBodyMd,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════
// 統計網格（2×3）
// ═══════════════════════════════════════

class _StatsGrid extends StatelessWidget {
  final PlayerProvider provider;
  const _StatsGrid({required this.provider});

  @override
  Widget build(BuildContext context) {
    final data = provider.data;
    final clearedStages =
        data.stageProgress.values.where((s) => s.cleared).length;
    final totalStars =
        data.stageProgress.values.fold<int>(0, (sum, s) => sum + s.stars);
    final unlockedAgents =
        data.agents.values.where((a) => a.isUnlocked).length;
    final totalAgents = provider.allAgentInfos.length;
    final teamAtk = provider.teamAgents.fold<int>(0, (sum, a) => sum + a.atk);

    final stats = [
      _StatData(
          icon: Icons.military_tech_rounded,
          label: '已通關',
          value: '$clearedStages',
          color: AppTheme.stageCleared),
      _StatData(
          icon: Icons.star_rounded,
          label: '總星數',
          value: '$totalStars',
          color: Colors.amber),
      _StatData(
          icon: Icons.people_rounded,
          label: '已收集',
          value: '$unlockedAgents/$totalAgents',
          color: AppTheme.rarityR),
      _StatData(
          icon: Icons.bolt_rounded,
          label: '體力',
          value: '${data.stamina}/${data.maxStamina}',
          color: Colors.greenAccent),
      _StatData(
          icon: Icons.flash_on_rounded,
          label: '隊伍戰力',
          value: '$teamAtk',
          color: AppTheme.accentSecondary),
      _StatData(
          icon: Icons.calendar_today_rounded,
          label: '打卡天數',
          value: '${data.weeklyCheckIn.totalChecked}',
          color: AppTheme.raritySR),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.1,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: stat.color.withAlpha(40)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(stat.icon, size: 22, color: stat.color),
              const SizedBox(height: 6),
              Text(
                stat.value,
                style: TextStyle(
                  color: stat.color,
                  fontSize: AppTheme.fontTitleMd,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                stat.label,
                style: TextStyle(
                  color: AppTheme.textSecondary.withAlpha(180),
                  fontSize: AppTheme.fontLabelLg,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

// ═══════════════════════════════════════
// 章節進度列表
// ═══════════════════════════════════════

class _ChapterProgressList extends StatelessWidget {
  final PlayerProvider provider;
  const _ChapterProgressList({required this.provider});

  @override
  Widget build(BuildContext context) {
    final chapters = StageData.chapters;
    final data = provider.data;

    return Column(
      children: chapters.map((chapter) {
        final stages = StageData.getChapterStages(chapter.number);
        final clearedCount = stages
            .where((s) => data.stageProgress[s.id]?.cleared == true)
            .length;
        final totalStars = stages.fold<int>(
            0, (sum, s) => sum + (data.stageProgress[s.id]?.stars ?? 0));
        final maxStars = stages.length * 3;
        final progress =
            stages.isNotEmpty ? clearedCount / stages.length : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: AppTheme.accentSecondary.withAlpha(60)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 章節名稱
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentPrimary.withAlpha(60),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '第${chapter.number}章',
                      style: const TextStyle(
                        color: AppTheme.accentSecondary,
                        fontSize: AppTheme.fontLabelLg,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chapter.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: AppTheme.fontBodyLg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // 星星數
                  Icon(Icons.star_rounded,
                      size: 14, color: Colors.amber.withAlpha(200)),
                  const SizedBox(width: 2),
                  Text(
                    '$totalStars/$maxStars',
                    style: TextStyle(
                      color: AppTheme.textSecondary.withAlpha(180),
                      fontSize: AppTheme.fontBodyMd,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 進度條
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: AppTheme.bgSecondary,
                        valueColor: AlwaysStoppedAnimation(
                          progress >= 1.0
                              ? AppTheme.stageCleared
                              : AppTheme.stageCurrent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$clearedCount/${stages.length}',
                    style: TextStyle(
                      color: progress >= 1.0
                          ? AppTheme.stageCleared
                          : AppTheme.textSecondary,
                      fontSize: AppTheme.fontBodyMd,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════
// 角色收集網格
// ═══════════════════════════════════════

class _AgentCollectionGrid extends StatelessWidget {
  final PlayerProvider provider;
  const _AgentCollectionGrid({required this.provider});

  @override
  Widget build(BuildContext context) {
    final agents = provider.allAgentInfos;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 0.8,
      ),
      itemCount: agents.length,
      itemBuilder: (context, index) {
        final agent = agents[index];
        final rarityLabel = agent.definition.rarity.name.toUpperCase();
        final color = AppTheme.rarityColor(rarityLabel);

        return Container(
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(
              color: agent.isUnlocked ? color.withAlpha(120) : AppTheme.accentSecondary.withAlpha(60),
              width: agent.isUnlocked ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 頭像
              SizedBox(
                width: 36,
                height: 36,
                child: agent.isUnlocked &&
                        ImageAssets.avatarImage(agent.definition.id) != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          ImageAssets.avatarImage(agent.definition.id)!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person,
                            color: color,
                            size: 24,
                          ),
                        ),
                      )
                    : Icon(Icons.lock_rounded,
                        color: AppTheme.accentSecondary.withAlpha(60), size: 20),
              ),
              const SizedBox(height: 4),
              // 名稱
              Text(
                agent.isUnlocked ? agent.definition.codename : '???',
                style: TextStyle(
                  color: agent.isUnlocked
                      ? AppTheme.textPrimary
                      : AppTheme.textSecondary.withAlpha(80),
                  fontSize: AppTheme.fontLabelSm,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // 等級
              if (agent.isUnlocked)
                Text(
                  'Lv.${agent.level}',
                  style: TextStyle(
                    color: color.withAlpha(200),
                    fontSize: AppTheme.fontLabelSm,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════
// 共用元件
// ═══════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: AppTheme.fontBodyLg,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
