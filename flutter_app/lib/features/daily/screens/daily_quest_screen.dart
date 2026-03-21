/// 每日任務畫面
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/models/player_data.dart';
import '../../agents/providers/player_provider.dart';

class DailyQuestScreen extends StatelessWidget {
  const DailyQuestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: const Text('每日任務'),
        backgroundColor: AppTheme.bgSecondary,
      ),
      body: Consumer<PlayerProvider>(
        builder: (context, provider, _) {
          if (!provider.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          final quests = provider.data.dailyQuests;

          // 自動重置
          if (quests.needsReset) {
            quests.reset();
          }

          // 自動登入
          if (!quests.hasLoggedIn) {
            provider.claimDailyLogin();
          }

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

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 任務列表
                ...tasks.map((task) => _TaskCard(task: task)),

                const SizedBox(height: 20),

                // 全完成獎勵
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: allDone && !quests.rewardsClaimed
                        ? Colors.amber.withAlpha(30)
                        : AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(
                      color: allDone
                          ? Colors.amber.withAlpha(150)
                          : Colors.white12,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            allDone
                                ? Icons.card_giftcard
                                : Icons.lock_outline,
                            color: allDone ? Colors.amber : AppTheme.textSecondary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '全完成獎勵',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '完成以上全部任務',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            '💎 10',
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      if (allDone && !quests.rewardsClaimed) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              provider.claimDailyReward();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('獲得 💎 10 鑽石！'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade700,
                            ),
                            child: const Text('領取獎勵'),
                          ),
                        ),
                      ],
                      if (quests.rewardsClaimed)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            '已領取',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const Spacer(),

                // 進度摘要
                Text(
                  '${tasks.where((t) => t.isDone).length}/3 完成',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
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
            // 狀態圖示
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
            // 任務資訊
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      decoration:
                          task.isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // 進度條
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: task.goal > 0 ? task.progress / task.goal : 0,
                      minHeight: 4,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        task.isDone ? Colors.green : AppTheme.accentPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${task.progress}/${task.goal}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 獎勵
            Text(
              task.reward,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
