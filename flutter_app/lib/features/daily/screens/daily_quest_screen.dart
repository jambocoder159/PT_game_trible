/// 任務中心畫面 — 每日任務 / 七日打卡 / 新手任務
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/player_data.dart';
import '../../agents/providers/player_provider.dart';
import '../../tutorial/widgets/tutorial_highlight_overlay.dart';
import '../../tutorial/widgets/tutorial_dialogue_box.dart';
import '../../tutorial/widgets/tutorial_floating_hint.dart';
import '../../tutorial/models/tutorial_dialogue_data.dart';

class DailyQuestScreen extends StatefulWidget {
  /// 教學模式：高亮領取獎勵按鈕，領取後自動 pop
  final bool tutorialMode;

  const DailyQuestScreen({
    super.key,
    this.tutorialMode = false,
  });

  @override
  State<DailyQuestScreen> createState() => _DailyQuestScreenState();
}

class _DailyQuestScreenState extends State<DailyQuestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static final GlobalKey _claimButtonKey = GlobalKey();
  bool _rewardWasClaimed = false;
  bool _showFeatureHint = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    final provider = context.read<PlayerProvider>();
    if (widget.tutorialMode) {
      _rewardWasClaimed = provider.data.dailyQuests.rewardsClaimed;
    }
    // 延遲教學：首次進入每日任務頁
    if (!widget.tutorialMode &&
        provider.data.tutorialCompleted &&
        !provider.data.shownFeatureHints.contains('dailyQuest')) {
      _showFeatureHint = true;
      provider.markFeatureHintShown('dailyQuest');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppTheme.bgPrimary,
          appBar: AppBar(
            title: const Text('任務中心'),
            backgroundColor: AppTheme.bgSecondary,
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.accentSecondary,
              labelColor: AppTheme.textPrimary,
              unselectedLabelColor: AppTheme.textSecondary,
              labelStyle: const TextStyle(fontSize: AppTheme.fontBodyLg, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: AppTheme.fontBodyLg),
              tabs: const [
                Tab(text: '每日任務'),
                Tab(text: '七日打卡'),
                Tab(text: '新手任務'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _DailyTab(
                tutorialMode: widget.tutorialMode,
                claimButtonKey: widget.tutorialMode ? _claimButtonKey : null,
              ),
              const _WeeklyTab(),
              const _NewbieTab(),
            ],
          ),
        ),
        // ─── 教學 overlay ───
        if (widget.tutorialMode)
          Consumer<PlayerProvider>(
            builder: (context, provider, _) {
              final claimed = provider.data.dailyQuests.rewardsClaimed;
              if (claimed && !_rewardWasClaimed) {
                // 領取完成 → pop
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) Navigator.of(context).pop(true);
                });
              }
              if (!claimed) {
                return Stack(
                  children: [
                    TutorialHighlightOverlay(
                      highlightKey: _claimButtonKey,
                      passthrough: true,
                    ),
                    TutorialDialogueBox(
                      dialogue: TutorialDialogues.t049,
                      onTap: () {},
                      showTapHint: false,
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        // 延遲教學提示
        if (_showFeatureHint)
          TutorialFloatingHint(
            text: '每天完成任務拿額外獎勵！',
            emoji: '📋',
            displayDuration: const Duration(seconds: 4),
            onDismissed: () {
              if (mounted) setState(() => _showFeatureHint = false);
            },
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════
// Tab 1: 每日任務
// ═══════════════════════════════════════════════════

class _DailyTab extends StatelessWidget {
  final bool tutorialMode;
  final GlobalKey? claimButtonKey;

  const _DailyTab({
    this.tutorialMode = false,
    this.claimButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, _) {
        if (!provider.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        final quests = provider.data.dailyQuests;
        if (quests.needsReset) quests.reset();
        if (!quests.hasLoggedIn) provider.claimDailyLogin();

        final tasks = [
          _TaskData(
            title: '每日登入',
            description: '登入遊戲',
            icon: Icons.login,
            progress: quests.hasLoggedIn ? 1 : 0,
            goal: 1,
            reward: '🪙 50',
            isDone: quests.hasLoggedIn,
          ),
          _TaskData(
            title: '完成 3 關',
            description: '通關任意 3 個關卡',
            icon: Icons.flag,
            progress: quests.stagesCompleted.clamp(0, 3),
            goal: 3,
            reward: '🪙 100 + ⚡ 10',
            isDone: quests.stagesCompleted >= 3,
          ),
          _TaskData(
            title: '消除 200 方塊',
            description: '累計消除 200 個方塊',
            icon: Icons.grid_view,
            progress: quests.blocksEliminated.clamp(0, 200),
            goal: 200,
            reward: '✨ 1 EXP 素材',
            isDone: quests.blocksEliminated >= 200,
          ),
        ];

        final allDone = quests.allCompleted;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...tasks.map((t) => _TaskCard(task: t)),
            const SizedBox(height: 16),
            KeyedSubtree(
              key: claimButtonKey ?? GlobalKey(),
              child: _BonusRewardCard(
                title: '全完成獎勵',
                subtitle: '完成以上全部任務',
                reward: '💎 10',
                isReady: allDone && !quests.rewardsClaimed,
                isClaimed: quests.rewardsClaimed,
                onClaim: () {
                  provider.claimDailyReward();
                  _showSnack(context, '獲得 💎 10 鑽石！');
                },
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '${tasks.where((t) => t.isDone).length}/3 完成',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: AppTheme.fontBodyLg),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════
// Tab 2: 七日打卡
// ═══════════════════════════════════════════════════

/// 七日打卡每日獎勵定義
class _DayReward {
  final int day;
  final String label;
  final int gold;
  final int diamonds;

  const _DayReward({
    required this.day,
    required this.label,
    this.gold = 0,
    this.diamonds = 0,
  });
}

const _weeklyRewards = [
  _DayReward(day: 1, label: '🪙 100', gold: 100),
  _DayReward(day: 2, label: '🪙 150', gold: 150),
  _DayReward(day: 3, label: '💎 5', diamonds: 5),
  _DayReward(day: 4, label: '🪙 200', gold: 200),
  _DayReward(day: 5, label: '💎 10', diamonds: 10),
  _DayReward(day: 6, label: '🪙 300', gold: 300),
  _DayReward(day: 7, label: '💎 20', diamonds: 20),
];

class _WeeklyTab extends StatelessWidget {
  const _WeeklyTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, _) {
        if (!provider.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        final wc = provider.data.weeklyCheckIn;
        // 週期結束自動開新週期
        if (wc.isCycleComplete) wc.resetCycle();
        // 跨日刷新
        if (wc.needsRefresh) wc.refreshDay();

        final currentDay = wc.currentDay;
        final todayChecked = wc.todayChecked;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 打卡按鈕
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: todayChecked
                    ? null
                    : LinearGradient(
                        colors: [
                          AppTheme.accentSecondary.withAlpha(60),
                          AppTheme.accentPrimary.withAlpha(60),
                        ],
                      ),
                color: todayChecked ? AppTheme.bgCard : null,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: todayChecked
                      ? Colors.green.withAlpha(100)
                      : AppTheme.accentSecondary.withAlpha(120),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    todayChecked ? '今日已打卡' : '第 $currentDay 天',
                    style: TextStyle(
                      color: todayChecked ? Colors.green : AppTheme.textPrimary,
                      fontSize: AppTheme.fontTitleLg,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '累計打卡 ${wc.totalChecked} / 7 天',
                    style: TextStyle(
                      color: AppTheme.textSecondary.withAlpha(180),
                      fontSize: AppTheme.fontBodyMd,
                    ),
                  ),
                  if (!todayChecked) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final success = await provider.weeklyCheckIn();
                          if (success && context.mounted) {
                            // 發放當天獎勵
                            final reward = _weeklyRewards[currentDay - 1];
                            await provider.claimWeeklyReward(
                              gold: reward.gold,
                              diamonds: reward.diamonds,
                            );
                            if (context.mounted) {
                              _showSnack(context, '打卡成功！獲得 ${reward.label}');
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          '打卡簽到',
                          style: TextStyle(fontSize: AppTheme.fontTitleMd, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 7 天獎勵格子
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.85,
              ),
              itemCount: 7,
              itemBuilder: (context, index) {
                final reward = _weeklyRewards[index];
                final isChecked = wc.checkedDays.contains(reward.day);
                final isToday = reward.day == currentDay;

                return Container(
                  decoration: BoxDecoration(
                    color: isChecked
                        ? Colors.green.withAlpha(30)
                        : isToday
                            ? AppTheme.accentSecondary.withAlpha(20)
                            : AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isChecked
                          ? Colors.green.withAlpha(120)
                          : isToday
                              ? AppTheme.accentSecondary.withAlpha(80)
                              : AppTheme.accentSecondary.withAlpha(60),
                      width: isToday ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Day ${reward.day}',
                        style: TextStyle(
                          color: isChecked
                              ? Colors.green
                              : AppTheme.textSecondary.withAlpha(180),
                          fontSize: AppTheme.fontLabelLg,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (isChecked)
                        const Icon(Icons.check_circle, color: Colors.green, size: 22)
                      else
                        Text(
                          reward.label,
                          style: TextStyle(
                            color: isToday
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary.withAlpha(120),
                            fontSize: AppTheme.fontBodyMd,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════
// Tab 3: 新手任務
// ═══════════════════════════════════════════════════

class _NewbieQuestDef {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String reward;
  final int gold;
  final int diamonds;

  const _NewbieQuestDef({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.reward,
    this.gold = 0,
    this.diamonds = 0,
  });
}

const _newbieQuests = [
  _NewbieQuestDef(
    id: 'tutorial',
    title: '完成教學',
    description: '完成新手引導教學',
    icon: Icons.school,
    reward: '🪙 200',
    gold: 200,
  ),
  _NewbieQuestDef(
    id: 'unlock_agent',
    title: '招募夥伴',
    description: '解鎖第 2 個點心夥伴',
    icon: Icons.person_add,
    reward: '💎 10',
    diamonds: 10,
  ),
  _NewbieQuestDef(
    id: 'clear_1_3',
    title: '初試身手',
    description: '通關關卡 1-3',
    icon: Icons.flag,
    reward: '🪙 300',
    gold: 300,
  ),
  _NewbieQuestDef(
    id: 'full_team',
    title: '組建隊伍',
    description: '組滿 3 人隊伍',
    icon: Icons.groups,
    reward: '💎 15',
    diamonds: 15,
  ),
  _NewbieQuestDef(
    id: 'reach_lv5',
    title: '成長茁壯',
    description: '玩家等級達到 Lv.5',
    icon: Icons.trending_up,
    reward: '🪙 500',
    gold: 500,
  ),
  _NewbieQuestDef(
    id: 'eliminate_500',
    title: '消除達人',
    description: '累計消除 500 個方塊',
    icon: Icons.auto_awesome,
    reward: '💎 10',
    diamonds: 10,
  ),
  _NewbieQuestDef(
    id: 'daily_all',
    title: '勤奮烘焙師',
    description: '完成一次每日全任務並領取獎勵',
    icon: Icons.task_alt,
    reward: '💎 20',
    diamonds: 20,
  ),
];

class _NewbieTab extends StatelessWidget {
  const _NewbieTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (context, provider, _) {
        if (!provider.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }

        // 自動檢查完成狀態
        provider.refreshNewbieQuests();
        final nq = provider.data.newbieQuests;

        final completedCount =
            _newbieQuests.where((q) => nq.isCompleted(q.id)).length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 進度總覽
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.accentSecondary.withAlpha(60)),
              ),
              child: Row(
                children: [
                  Icon(
                    completedCount >= _newbieQuests.length
                        ? Icons.emoji_events
                        : Icons.assignment,
                    color: completedCount >= _newbieQuests.length
                        ? Colors.amber
                        : AppTheme.textSecondary,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '新手任務進度',
                    style: TextStyle(
                      color: AppTheme.textPrimary.withAlpha(200),
                      fontSize: AppTheme.fontBodyLg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$completedCount / ${_newbieQuests.length}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: AppTheme.fontBodyLg,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 任務列表
            ..._newbieQuests.map((quest) {
              final isCompleted = nq.isCompleted(quest.id);
              final isClaimed = nq.isClaimed(quest.id);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: AppTheme.bgCard,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  side: isClaimed
                      ? const BorderSide(color: Colors.green, width: 1)
                      : isCompleted
                          ? BorderSide(color: Colors.amber.withAlpha(150), width: 1)
                          : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // 圖示
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isClaimed
                              ? Colors.green.withAlpha(40)
                              : isCompleted
                                  ? Colors.amber.withAlpha(40)
                                  : AppTheme.accentPrimary.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isClaimed
                              ? Icons.check_circle
                              : quest.icon,
                          color: isClaimed
                              ? Colors.green
                              : isCompleted
                                  ? Colors.amber
                                  : AppTheme.textSecondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // 資訊
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              quest.title,
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: AppTheme.fontBodyLg,
                                decoration: isClaimed
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            Text(
                              quest.description,
                              style: TextStyle(
                                color: AppTheme.textSecondary.withAlpha(150),
                                fontSize: AppTheme.fontLabelLg,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 獎勵 / 領取按鈕
                      if (isClaimed)
                        const Text(
                          '已領取',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: AppTheme.fontLabelLg,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else if (isCompleted)
                        ElevatedButton(
                          onPressed: () async {
                            final ok = await provider.claimNewbieReward(
                              quest.id,
                              gold: quest.gold,
                              diamonds: quest.diamonds,
                            );
                            if (ok && context.mounted) {
                              _showSnack(context, '獲得 ${quest.reward}！');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade700,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            minimumSize: const Size(0, 28),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            quest.reward,
                            style: const TextStyle(fontSize: AppTheme.fontLabelLg),
                          ),
                        )
                      else
                        Text(
                          quest.reward,
                          style: TextStyle(
                            color: AppTheme.textSecondary.withAlpha(100),
                            fontSize: AppTheme.fontLabelLg,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════
// 共用元件
// ═══════════════════════════════════════════════════

void _showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: Colors.green),
  );
}

class _TaskData {
  final String title;
  final String description;
  final IconData icon;
  final int progress;
  final int goal;
  final String reward;
  final bool isDone;

  const _TaskData({
    required this.title,
    required this.description,
    required this.icon,
    required this.progress,
    required this.goal,
    required this.reward,
    required this.isDone,
  });
}

class _TaskCard extends StatelessWidget {
  final _TaskData task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: AppTheme.bgCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: task.isDone
            ? const BorderSide(color: Colors.green, width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: task.isDone
                    ? Colors.green.withAlpha(40)
                    : AppTheme.accentPrimary.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                task.isDone ? Icons.check_circle : task.icon,
                color: task.isDone ? Colors.green : AppTheme.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      decoration: task.isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: task.goal > 0 ? task.progress / task.goal : 0,
                      minHeight: 4,
                      backgroundColor: AppTheme.bgSecondary,
                      valueColor: AlwaysStoppedAnimation(
                        task.isDone ? Colors.green : AppTheme.accentPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${task.progress}/${task.goal}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: AppTheme.fontLabelLg,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              task.reward,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: AppTheme.fontBodyMd),
            ),
          ],
        ),
      ),
    );
  }
}

class _BonusRewardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String reward;
  final bool isReady;
  final bool isClaimed;
  final VoidCallback onClaim;

  const _BonusRewardCard({
    required this.title,
    required this.subtitle,
    required this.reward,
    required this.isReady,
    required this.isClaimed,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isReady ? Colors.amber.withAlpha(30) : AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: isReady || isClaimed
              ? Colors.amber.withAlpha(150)
              : AppTheme.accentSecondary.withAlpha(60),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isReady || isClaimed ? Icons.card_giftcard : Icons.lock_outline,
                color: isReady || isClaimed ? Colors.amber : AppTheme.textSecondary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: AppTheme.fontTitleMd,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: AppTheme.fontBodyMd,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                reward,
                style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: AppTheme.fontTitleMd,
                ),
              ),
            ],
          ),
          if (isReady) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onClaim,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                ),
                child: const Text('領取獎勵'),
              ),
            ),
          ],
          if (isClaimed)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '已領取',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
