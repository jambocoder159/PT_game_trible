/// 關卡選擇畫面
/// 章節列表 → 關卡列表 → 開始戰鬥
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/image_assets.dart';
import '../../../config/stage_data.dart';
import '../../../config/theme.dart';
import '../../agents/providers/player_provider.dart';
import '../../game/screens/battle_screen.dart';

class StageSelectScreen extends StatefulWidget {
  const StageSelectScreen({super.key});

  @override
  State<StageSelectScreen> createState() => _StageSelectScreenState();
}

class _StageSelectScreenState extends State<StageSelectScreen> {
  int _selectedChapter = 1;

  @override
  void initState() {
    super.initState();
    _initChapter();
  }

  /// 自動跳到有未完成關卡的最新章節
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('任務選擇'),
        backgroundColor: AppTheme.bgSecondary,
      ),
      body: Column(
        children: [
          // 章節選擇
          _ChapterTabs(
            selectedChapter: _selectedChapter,
            onChapterSelected: (chapter) {
              setState(() => _selectedChapter = chapter);
            },
          ),
          // 關卡列表
          Expanded(
            child: _StageList(chapter: _selectedChapter),
          ),
        ],
      ),
    );
  }
}

class _ChapterTabs extends StatelessWidget {
  final int selectedChapter;
  final void Function(int) onChapterSelected;

  const _ChapterTabs({
    required this.selectedChapter,
    required this.onChapterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: StageData.chapters.map((chapter) {
          final isSelected = chapter.number == selectedChapter;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChapterSelected(chapter.number),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.accentPrimary
                      : AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: isSelected
                      ? null
                      : Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    Text(
                      '第${chapter.number}章',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      chapter.name,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white70
                            : AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StageList extends StatelessWidget {
  final int chapter;

  const _StageList({required this.chapter});

  @override
  Widget build(BuildContext context) {
    final stages = StageData.getChapterStages(chapter);

    return Consumer<PlayerProvider>(
      builder: (context, playerProvider, _) {
        final stageProgress = playerProvider.data.stageProgress;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: stages.length,
          itemBuilder: (context, index) {
            final stage = stages[index];
            final progress = stageProgress[stage.id];
            final isCleared = progress?.cleared == true;
            final stars = progress?.stars ?? 0;

            // 判斷是否解鎖：第一關永遠解鎖，其餘需前一關通過
            final isUnlocked = index == 0 ||
                (stageProgress[stages[index - 1].id]?.cleared == true);

            return _StageCard(
              stage: stage,
              isUnlocked: isUnlocked,
              isCleared: isCleared,
              stars: stars,
              stamina: playerProvider.data.stamina,
              onTap: isUnlocked
                  ? () => _startStage(context, stage, playerProvider)
                  : null,
            );
          },
        );
      },
    );
  }

  void _startStage(
    BuildContext context,
    StageDefinition stage,
    PlayerProvider playerProvider,
  ) {
    // 檢查體力
    if (playerProvider.data.stamina < stage.staminaCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('體力不足！需要 ${stage.staminaCost} 體力'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 檢查隊伍
    if (playerProvider.data.team.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請先編排隊伍！'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 消耗體力
    playerProvider.consumeStamina(stage.staminaCost);

    // 進入戰鬥（淡出過場）
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

class _StageCard extends StatelessWidget {
  final StageDefinition stage;
  final bool isUnlocked;
  final bool isCleared;
  final int stars;
  final int stamina;
  final VoidCallback? onTap;

  const _StageCard({
    required this.stage,
    required this.isUnlocked,
    required this.isCleared,
    required this.stars,
    required this.stamina,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isUnlocked ? AppTheme.bgCard : AppTheme.bgCard.withAlpha(100),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        side: isCleared
            ? const BorderSide(color: Colors.green, width: 1)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // 關卡編號
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? AppTheme.accentPrimary.withAlpha(80)
                      : Colors.grey.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: isUnlocked
                      ? Text(
                          '${stage.stageNumber}',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : GameIcon(
                          assetPath: ImageAssets.lock,
                          fallbackEmoji: '🔒',
                          size: 20,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // 關卡資訊
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stage.name,
                      style: TextStyle(
                        color: isUnlocked
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        // 敵人列表
                        ...stage.enemies.take(4).map((e) => Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: GameImage(
                                assetPath: ImageAssets.enemyImage(e.id),
                                fallbackEmoji: e.emoji,
                                width: 18, height: 18,
                              ),
                            )),
                        if (stage.enemies.length > 4)
                          Text(
                            '+${stage.enemies.length - 4}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        const Spacer(),
                        // 體力消耗
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GameIcon(assetPath: ImageAssets.energy, fallbackEmoji: '⚡', size: 14),
                            const SizedBox(width: 2),
                            Text(
                              '${stage.staminaCost}',
                              style: TextStyle(
                                color: stamina >= stage.staminaCost
                                    ? AppTheme.textSecondary
                                    : Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // 星星
              if (isCleared)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    return GameIcon(
                      assetPath: i < stars
                          ? ImageAssets.starFull
                          : ImageAssets.starEmpty,
                      fallbackEmoji: i < stars ? '⭐' : '☆',
                      size: 18,
                    );
                  }),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
