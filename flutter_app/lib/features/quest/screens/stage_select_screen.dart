/// 關卡選擇畫面 — 全新設計
/// 章節橫幅 + 蜿蜒節點路徑地圖
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../config/image_assets.dart';
import '../../../config/stage_data.dart';
import '../../../config/theme.dart';
import '../../../core/models/player_data.dart';
import '../../agents/providers/player_provider.dart';
import '../../game/screens/battle_screen.dart';

class StageSelectScreen extends StatefulWidget {
  const StageSelectScreen({super.key});

  @override
  State<StageSelectScreen> createState() => _StageSelectScreenState();
}

class _StageSelectScreenState extends State<StageSelectScreen>
    with TickerProviderStateMixin {
  late int _selectedChapter;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initChapter();

    _pulseController = AnimationController(
      vsync: this,
      duration: AppTheme.animPulse,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

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

  /// 計算玩家能進入的最高章節
  int _getMaxAccessibleChapter(Map<String, StageProgress> progress) {
    for (final chapter in StageData.chapters) {
      final stages = StageData.getChapterStages(chapter.number);
      final allCleared = stages.every((s) => progress[s.id]?.cleared == true);
      if (!allCleared) {
        return chapter.number; // 本章還沒全通 → 最高可進入的章節
      }
    }
    return StageData.chapters.last.number; // 全通關
  }

  void _switchChapter(int direction) {
    final newChapter = _selectedChapter + direction;
    if (newChapter < 1 || newChapter > StageData.chapters.last.number) return;

    // 檢查章節是否可進入
    final progress = context.read<PlayerProvider>().data.stageProgress;
    final maxAccessible = _getMaxAccessibleChapter(progress);
    if (newChapter > maxAccessible) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('請先通關第 $maxAccessible 章所有關卡！'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _selectedChapter = newChapter);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chapter = StageData.chapters.firstWhere(
      (c) => c.number == _selectedChapter,
    );

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: Consumer<PlayerProvider>(
        builder: (context, provider, _) {
          final stages = StageData.getChapterStages(_selectedChapter);
          final stageProgress = provider.data.stageProgress;
          final clearedCount =
              stages.where((s) => stageProgress[s.id]?.cleared == true).length;

          return Column(
            children: [
              // ─── 章節橫幅 ───
              _ChapterBanner(
                chapter: chapter,
                chapterNumber: _selectedChapter,
                clearedCount: clearedCount,
                totalCount: stages.length,
                stamina: provider.data.stamina,
                maxStamina: provider.data.maxStamina,
                onPrev: _selectedChapter > 1
                    ? () => _switchChapter(-1)
                    : null,
                onNext: _selectedChapter < StageData.chapters.last.number
                    ? () => _switchChapter(1)
                    : null,
                isNextLocked: _selectedChapter < StageData.chapters.last.number &&
                    (_selectedChapter + 1) > _getMaxAccessibleChapter(stageProgress),
              ),

              // ─── 節點路徑地圖 ───
              Expanded(
                child: _StagePathMap(
                  scrollController: _scrollController,
                  stages: stages,
                  stageProgress: stageProgress,
                  stamina: provider.data.stamina,
                  pulseAnimation: _pulseAnimation,
                  onStageTap: (stage) =>
                      _startStage(context, stage, provider),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _startStage(
    BuildContext context,
    StageDefinition stage,
    PlayerProvider playerProvider,
  ) {
    // 顯示關卡摘要彈窗
    _showStageSummary(context, stage, playerProvider);
  }

  void _showStageSummary(
    BuildContext context,
    StageDefinition stage,
    PlayerProvider playerProvider,
  ) {
    final progress = playerProvider.data.stageProgress[stage.id];
    final isFirstClear = progress?.cleared != true;
    final bgPath = ImageAssets.battleBackground(stage.chapter);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        var isEditingTeam = false;
        return StatefulBuilder(
        builder: (context, setModalState) {
          return Consumer<PlayerProvider>(
            builder: (_, playerProv, __) {
              final teamAgents = playerProv.teamAgents;
              final hasEnoughStamina =
                  playerProv.data.stamina >= stage.staminaCost;
              final hasTeam = playerProv.data.team.isNotEmpty;
              return Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: bgPath != null
                      ? Colors.transparent
                      : AppTheme.bgSecondary,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(color: Colors.white.withAlpha(20)),
                ),
                child: Stack(
                  children: [
                    // ─── 背景圖層（模糊 + 暗化）───
                    if (bgPath != null)
                      Positioned.fill(
                        child: ImageFiltered(
                          imageFilter:
                              ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Image.asset(
                            bgPath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: AppTheme.bgSecondary),
                          ),
                        ),
                      ),
                    if (bgPath != null)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withAlpha(160),
                        ),
                      ),
                    // ─── 前景內容 ───
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ─── 標題列 ───
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.fromLTRB(20, 16, 20, 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.accentPrimary.withAlpha(40),
                                Colors.transparent,
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppTheme.radiusLarge),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.stageCurrent.withAlpha(40),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: AppTheme.stageCurrent
                                          .withAlpha(100)),
                                ),
                                child: Text(
                                  stage.id,
                                  style: const TextStyle(
                                    color: AppTheme.stageCurrent,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  stage.name,
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (!isFirstClear)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.stageCleared.withAlpha(30),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle,
                                          color: AppTheme.stageCleared,
                                          size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${progress?.stars ?? 0}/3',
                                        style: const TextStyle(
                                          color: AppTheme.stageCleared,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),

                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ─── 敵人情報（卡片式）───
                              Text(
                                '敵人情報',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              SizedBox(
                                height: 130,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: stage.enemies.length,
                                  itemBuilder: (_, i) {
                                    final e = stage.enemies[i];
                                    final eColor =
                                        e.attribute.blockColor.color;
                                    return Container(
                                      width: 110,
                                      margin:
                                          const EdgeInsets.only(right: 10),
                                      clipBehavior: Clip.antiAlias,
                                      decoration: BoxDecoration(
                                        color:
                                            AppTheme.bgCard.withAlpha(220),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        border: Border.all(
                                          color: eColor.withAlpha(120),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: eColor.withAlpha(30),
                                            blurRadius: 8,
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          // 大圖區域
                                          Expanded(
                                            child: Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    eColor.withAlpha(30),
                                                    Colors.black26,
                                                  ],
                                                ),
                                              ),
                                              child: Stack(
                                                children: [
                                                  Center(
                                                    child: GameImage(
                                                      assetPath:
                                                          ImageAssets.enemyImage(
                                                              e.id),
                                                      fallbackEmoji: e.emoji,
                                                      width: 64,
                                                      height: 64,
                                                    ),
                                                  ),
                                                  // 屬性色帶
                                                  Positioned(
                                                    top: 0,
                                                    left: 0,
                                                    right: 0,
                                                    child: Container(
                                                      height: 3,
                                                      color: eColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          // 底部資訊區
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 8,
                                                vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.black38,
                                            ),
                                            child: Column(
                                              mainAxisSize:
                                                  MainAxisSize.min,
                                              children: [
                                                Text(
                                                  e.name,
                                                  style:
                                                      const TextStyle(
                                                    color: AppTheme
                                                        .textPrimary,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                  ),
                                                  overflow: TextOverflow
                                                      .ellipsis,
                                                ),
                                                const SizedBox(
                                                    height: 3),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .center,
                                                  children: [
                                                    Icon(
                                                        Icons.favorite,
                                                        size: 10,
                                                        color: Colors
                                                            .green
                                                            .shade300),
                                                    const SizedBox(
                                                        width: 2),
                                                    Text(
                                                      '${e.baseHp}',
                                                      style: TextStyle(
                                                        color: Colors
                                                            .green
                                                            .shade300,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight
                                                                .bold,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width: 8),
                                                    Icon(
                                                        Icons
                                                            .flash_on,
                                                        size: 10,
                                                        color: Colors
                                                            .red
                                                            .shade300),
                                                    const SizedBox(
                                                        width: 2),
                                                    Text(
                                                      '${e.baseAtk}',
                                                      style: TextStyle(
                                                        color: Colors
                                                            .red
                                                            .shade300,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight
                                                                .bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 14),

                              // ─── 關卡資訊列 ───
                              Row(
                                children: [
                                  _InfoChip(
                                    icon: Icons.bolt_rounded,
                                    label: '體力',
                                    value: '${stage.staminaCost}',
                                    color: hasEnoughStamina
                                        ? Colors.greenAccent
                                        : Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  _InfoChip(
                                    icon: Icons.swap_vert_rounded,
                                    label: '步數',
                                    value: stage.moveLimit > 0
                                        ? '${stage.moveLimit}'
                                        : '∞',
                                    color: Colors.cyan,
                                  ),
                                  const SizedBox(width: 8),
                                  _InfoChip(
                                    icon: Icons.monetization_on_rounded,
                                    label: '金幣',
                                    value: '${stage.reward.gold}',
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 8),
                                  _InfoChip(
                                    icon: Icons.auto_awesome,
                                    label: '經驗',
                                    value: '${stage.reward.exp}',
                                    color: Colors.lightBlueAccent,
                                  ),
                                ],
                              ),

                              // 解鎖角色提示
                              if (stage.reward.unlockAgentId != null &&
                                  isFirstClear) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withAlpha(20),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    border: Border.all(
                                        color:
                                            Colors.amber.withAlpha(60)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Text('🎉',
                                          style:
                                              TextStyle(fontSize: 16)),
                                      const SizedBox(width: 8),
                                      Text(
                                        '首次通關可解鎖新特工！',
                                        style: TextStyle(
                                          color: Colors.amber.shade300,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 14),

                              // ─── 出戰隊伍（可快速編輯）───
                              Row(
                                children: [
                                  Text(
                                    '出戰隊伍',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () {
                                      isEditingTeam = !isEditingTeam;
                                      setModalState(() {});
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isEditingTeam
                                              ? Icons.check_rounded
                                              : Icons.edit_rounded,
                                          size: 14,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isEditingTeam ? '完成' : '編輯',
                                          style: const TextStyle(
                                            color: Colors.amber,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              if (!hasTeam && !isEditingTeam)
                                const Text(
                                  '尚未編排隊伍',
                                  style: TextStyle(
                                      color: Colors.red, fontSize: 12),
                                )
                              else if (isEditingTeam)
                                // ─── 快速編隊選擇器 ───
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '最多 3 名（點擊選取/取消）',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary
                                            .withAlpha(150),
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: playerProv.unlockedAgents
                                          .map((agent) {
                                        final isInTeam = playerProv
                                            .data.team
                                            .contains(
                                                agent.definition.id);
                                        final aColor = agent.definition
                                            .attribute.blockColor.color;
                                        final avatarPath =
                                            ImageAssets.avatarImage(
                                                agent.definition.id);
                                        return GestureDetector(
                                          onTap: () async {
                                            await playerProv
                                                .toggleTeamMember(
                                                    agent.definition.id);
                                          },
                                          child: Container(
                                            padding:
                                                const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      8),
                                              border: Border.all(
                                                color: isInTeam
                                                    ? Colors.amber
                                                    : Colors.white24,
                                                width:
                                                    isInTeam ? 2 : 1,
                                              ),
                                              color: isInTeam
                                                  ? Colors.amber
                                                      .withAlpha(30)
                                                  : Colors.transparent,
                                            ),
                                            child: Column(
                                              mainAxisSize:
                                                  MainAxisSize.min,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(6),
                                                  child: avatarPath !=
                                                          null
                                                      ? Image.asset(
                                                          avatarPath,
                                                          width: 32,
                                                          height: 32,
                                                          fit: BoxFit
                                                              .cover,
                                                          errorBuilder: (_,
                                                                  __,
                                                                  ___) =>
                                                              SizedBox(
                                                            width: 32,
                                                            height: 32,
                                                            child:
                                                                Center(
                                                              child:
                                                                  Text(
                                                                agent
                                                                    .definition
                                                                    .attribute
                                                                    .blockColor
                                                                    .symbol,
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    color:
                                                                        aColor),
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                      : SizedBox(
                                                          width: 32,
                                                          height: 32,
                                                          child: Center(
                                                            child: Text(
                                                              agent
                                                                  .definition
                                                                  .attribute
                                                                  .blockColor
                                                                  .symbol,
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      16,
                                                                  color:
                                                                      aColor),
                                                            ),
                                                          ),
                                                        ),
                                                ),
                                                const SizedBox(
                                                    height: 2),
                                                Text(
                                                  agent.definition
                                                      .codename,
                                                  style:
                                                      const TextStyle(
                                                    color: AppTheme
                                                        .textPrimary,
                                                    fontSize: 9,
                                                  ),
                                                  overflow: TextOverflow
                                                      .ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                )
                              else
                                // ─── 隊伍預覽（只讀）───
                                Row(
                                  children:
                                      teamAgents.map((agent) {
                                    final avatarPath =
                                        ImageAssets.avatarImage(
                                            agent.definition.id);
                                    return Container(
                                      margin: const EdgeInsets.only(
                                          right: 8),
                                      padding:
                                          const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                          color: agent
                                              .definition
                                              .attribute
                                              .blockColor
                                              .color
                                              .withAlpha(120),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize:
                                            MainAxisSize.min,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(
                                                    7),
                                            child: avatarPath != null
                                                ? Image.asset(
                                                    avatarPath,
                                                    width: 28,
                                                    height: 28,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_,
                                                            __, ___) =>
                                                        SizedBox(
                                                      width: 28,
                                                      height: 28,
                                                      child: Center(
                                                        child: Text(
                                                          agent
                                                              .definition
                                                              .attribute
                                                              .blockColor
                                                              .symbol,
                                                          style: const TextStyle(
                                                              fontSize:
                                                                  14),
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                : SizedBox(
                                                    width: 28,
                                                    height: 28,
                                                    child: Center(
                                                      child: Text(
                                                        agent
                                                            .definition
                                                            .attribute
                                                            .blockColor
                                                            .symbol,
                                                        style: const TextStyle(
                                                            fontSize:
                                                                14),
                                                      ),
                                                    ),
                                                  ),
                                          ),
                                          const SizedBox(width: 6),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                            children: [
                                              Text(
                                                agent.definition
                                                    .codename,
                                                style:
                                                    const TextStyle(
                                                  color: AppTheme
                                                      .textPrimary,
                                                  fontSize: 11,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                'Lv.${agent.level}',
                                                style: TextStyle(
                                                  color: AppTheme
                                                      .textSecondary
                                                      .withAlpha(150),
                                                  fontSize: 9,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),

                              const SizedBox(height: 18),

                              // ─── 出戰按鈕 ───
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      hasEnoughStamina && hasTeam
                                          ? () {
                                              Navigator.pop(ctx);
                                              _launchBattle(context,
                                                  stage, playerProv);
                                            }
                                          : null,
                                  icon: const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 20),
                                  label: Text(
                                    hasEnoughStamina
                                        ? '出戰！'
                                        : '體力不足 (需要 ${stage.staminaCost})',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        AppTheme.accentSecondary,
                                    disabledBackgroundColor:
                                        Colors.grey.shade800,
                                    padding:
                                        const EdgeInsets.symmetric(
                                            vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                              AppTheme.radiusMedium),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
      },
    );
  }

  void _launchBattle(
    BuildContext context,
    StageDefinition stage,
    PlayerProvider playerProvider,
  ) {
    playerProvider.consumeStamina(stage.staminaCost);
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

// ═══════════════════════════════════════
// 章節橫幅
// ═══════════════════════════════════════

class _ChapterBanner extends StatelessWidget {
  final ChapterInfo chapter;
  final int chapterNumber;
  final int clearedCount;
  final int totalCount;
  final int stamina;
  final int maxStamina;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final bool isNextLocked;

  const _ChapterBanner({
    required this.chapter,
    required this.chapterNumber,
    required this.clearedCount,
    required this.totalCount,
    required this.stamina,
    required this.maxStamina,
    this.onPrev,
    this.onNext,
    this.isNextLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgPath = ImageAssets.battleBackground(chapterNumber);

    return Container(
      height: 180,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 背景圖
          if (bgPath != null)
            Image.asset(
              bgPath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppTheme.bgSecondary,
              ),
            )
          else
            Container(color: AppTheme.bgSecondary),

          // 漸層覆蓋
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha(120),
                  Colors.black.withAlpha(60),
                  AppTheme.bgPrimary.withAlpha(240),
                  AppTheme.bgPrimary,
                ],
                stops: const [0.0, 0.4, 0.85, 1.0],
              ),
            ),
          ),

          // 內容
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 頂部：返回 + 體力
                  Row(
                    children: [
                      const Text(
                        '任務選擇',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      // 體力顯示
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(100),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GameIcon(
                              assetPath: ImageAssets.energy,
                              fallbackEmoji: '⚡',
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$stamina/$maxStamina',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // 章節資訊 + 切換箭頭
                  Row(
                    children: [
                      // 上一章
                      _NavArrow(
                        icon: Icons.chevron_left,
                        onTap: onPrev,
                      ),
                      const SizedBox(width: 8),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '第${chapter.number}章',
                              style: TextStyle(
                                color: Colors.white.withAlpha(180),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              chapter.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              chapter.description,
                              style: TextStyle(
                                color: Colors.white.withAlpha(150),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 下一章
                      _NavArrow(
                        icon: isNextLocked
                            ? Icons.lock_rounded
                            : Icons.chevron_right,
                        onTap: onNext,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // 進度條
                  _ChapterProgress(
                    cleared: clearedCount,
                    total: totalCount,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _NavArrow({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null
              ? Colors.white.withAlpha(25)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: onTap != null
              ? Colors.white.withAlpha(200)
              : Colors.white.withAlpha(40),
          size: 24,
        ),
      ),
    );
  }
}

class _ChapterProgress extends StatelessWidget {
  final int cleared;
  final int total;

  const _ChapterProgress({required this.cleared, required this.total});

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? cleared / total : 0.0;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withAlpha(30),
              valueColor: AlwaysStoppedAnimation<Color>(
                cleared == total
                    ? AppTheme.stageCleared
                    : AppTheme.stageCurrent,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$cleared/$total',
          style: TextStyle(
            color: Colors.white.withAlpha(180),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════
// 蜿蜒節點路徑地圖
// ═══════════════════════════════════════

class _StagePathMap extends StatelessWidget {
  final ScrollController scrollController;
  final List<StageDefinition> stages;
  final Map<String, StageProgress> stageProgress;
  final int stamina;
  final Animation<double> pulseAnimation;
  final void Function(StageDefinition) onStageTap;

  const _StagePathMap({
    required this.scrollController,
    required this.stages,
    required this.stageProgress,
    required this.stamina,
    required this.pulseAnimation,
    required this.onStageTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // 節點佈局參數
    const nodeSize = 56.0;
    const rowHeight = 100.0;
    final leftX = screenWidth * 0.2;
    final rightX = screenWidth * 0.8 - nodeSize;
    final centerX = (screenWidth - nodeSize) / 2;

    // 計算每個節點的位置（S型蜿蜒）
    final nodePositions = <Offset>[];
    for (int i = 0; i < stages.length; i++) {
      final row = i;
      final y = row * rowHeight + 20;
      double x;

      // S型排列：左-中-右-中-左-中-右...
      final pattern = i % 4;
      switch (pattern) {
        case 0:
          x = leftX;
          break;
        case 1:
          x = centerX;
          break;
        case 2:
          x = rightX;
          break;
        case 3:
          x = centerX;
          break;
        default:
          x = centerX;
      }
      nodePositions.add(Offset(x, y));
    }

    final totalHeight = stages.length * rowHeight + 60;

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 40),
      child: SizedBox(
        width: screenWidth,
        height: totalHeight,
        child: Stack(
          children: [
            // ─── 路徑線 ───
            CustomPaint(
              size: Size(screenWidth, totalHeight),
              painter: _PathPainter(
                nodePositions: nodePositions,
                nodeSize: nodeSize,
                stageProgress: stageProgress,
                stages: stages,
              ),
            ),

            // ─── 節點 ───
            ...List.generate(stages.length, (index) {
              final stage = stages[index];
              final pos = nodePositions[index];
              final progress = stageProgress[stage.id];
              final isCleared = progress?.cleared == true;
              final stars = progress?.stars ?? 0;
              final isUnlocked = index == 0 ||
                  (stageProgress[stages[index - 1].id]?.cleared == true);
              final isCurrent = isUnlocked && !isCleared;
              final isBoss = stage.stageNumber == stages.length;

              return Positioned(
                left: pos.dx,
                top: pos.dy,
                child: _StageNode(
                  stage: stage,
                  isCleared: isCleared,
                  isUnlocked: isUnlocked,
                  isCurrent: isCurrent,
                  isBoss: isBoss,
                  stars: stars,
                  stamina: stamina,
                  nodeSize: nodeSize,
                  pulseAnimation: isCurrent ? pulseAnimation : null,
                  onTap: isUnlocked
                      ? () => onStageTap(stage)
                      : null,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// 路徑繪製器
// ═══════════════════════════════════════

class _PathPainter extends CustomPainter {
  final List<Offset> nodePositions;
  final double nodeSize;
  final Map<String, StageProgress> stageProgress;
  final List<StageDefinition> stages;

  _PathPainter({
    required this.nodePositions,
    required this.nodeSize,
    required this.stageProgress,
    required this.stages,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < nodePositions.length - 1; i++) {
      final from = nodePositions[i] + Offset(nodeSize / 2, nodeSize / 2);
      final to = nodePositions[i + 1] + Offset(nodeSize / 2, nodeSize / 2);

      final isActive =
          stageProgress[stages[i].id]?.cleared == true;

      final paint = Paint()
        ..color = isActive
            ? AppTheme.pathActive.withAlpha(180)
            : AppTheme.pathInactive.withAlpha(100)
        ..strokeWidth = isActive ? 3.0 : 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      if (!isActive) {
        // 虛線效果
        _drawDashedLine(canvas, from, to, paint);
      } else {
        // 實線 + 曲線
        final path = Path()
          ..moveTo(from.dx, from.dy);

        final midY = (from.dy + to.dy) / 2;
        path.cubicTo(
          from.dx, midY,
          to.dx, midY,
          to.dx, to.dy,
        );

        canvas.drawPath(path, paint);

        // 發光效果
        final glowPaint = Paint()
          ..color = AppTheme.pathActive.withAlpha(40)
          ..strokeWidth = 8.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawPath(path, glowPaint);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;

    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final unitDx = dx / distance;
    final unitDy = dy / distance;

    double currentDistance = 0;
    while (currentDistance < distance) {
      final startX = from.dx + unitDx * currentDistance;
      final startY = from.dy + unitDy * currentDistance;
      currentDistance += dashWidth;
      if (currentDistance > distance) currentDistance = distance;
      final endX = from.dx + unitDx * currentDistance;
      final endY = from.dy + unitDy * currentDistance;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
      currentDistance += dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) {
    return oldDelegate.stageProgress != stageProgress;
  }
}

// ═══════════════════════════════════════
// 關卡節點
// ═══════════════════════════════════════

class _StageNode extends StatelessWidget {
  final StageDefinition stage;
  final bool isCleared;
  final bool isUnlocked;
  final bool isCurrent;
  final bool isBoss;
  final int stars;
  final int stamina;
  final double nodeSize;
  final Animation<double>? pulseAnimation;
  final VoidCallback? onTap;

  const _StageNode({
    required this.stage,
    required this.isCleared,
    required this.isUnlocked,
    required this.isCurrent,
    required this.isBoss,
    required this.stars,
    required this.stamina,
    required this.nodeSize,
    this.pulseAnimation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.lightImpact();
          onTap!();
        }
      },
      child: SizedBox(
        width: nodeSize + 100, // 為標籤留空間
        height: nodeSize + 30,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 節點圓圈
            Positioned(
              left: 0,
              top: 0,
              child: pulseAnimation != null
                  ? AnimatedBuilder(
                      animation: pulseAnimation!,
                      builder: (_, child) => Transform.scale(
                        scale: pulseAnimation!.value,
                        child: child,
                      ),
                      child: _buildNodeCircle(),
                    )
                  : _buildNodeCircle(),
            ),

            // 關卡名稱（節點右側）
            Positioned(
              left: nodeSize + 8,
              top: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.name,
                    style: TextStyle(
                      color: isUnlocked
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary.withAlpha(80),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 敵人圖標
                      ...stage.enemies.take(3).map((e) => Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: GameImage(
                              assetPath: ImageAssets.enemyImage(e.id),
                              fallbackEmoji: e.emoji,
                              width: 16,
                              height: 16,
                            ),
                          )),
                      const SizedBox(width: 6),
                      // 體力
                      GameIcon(
                        assetPath: ImageAssets.energy,
                        fallbackEmoji: '⚡',
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${stage.staminaCost}',
                        style: TextStyle(
                          color: stamina >= stage.staminaCost
                              ? AppTheme.textSecondary
                              : Colors.red,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 星星（已通關）
            if (isCleared)
              Positioned(
                left: (nodeSize - 42) / 2,
                top: nodeSize - 2,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    return GameIcon(
                      assetPath: i < stars
                          ? ImageAssets.starFull
                          : ImageAssets.starEmpty,
                      fallbackEmoji: i < stars ? '⭐' : '☆',
                      size: 14,
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeCircle() {
    Color bgColor;
    Color borderColor;
    Widget content;

    if (isCleared) {
      bgColor = AppTheme.stageCleared.withAlpha(40);
      borderColor = AppTheme.stageCleared;
      content = const Icon(Icons.check, color: Colors.white, size: 24);
    } else if (isCurrent) {
      bgColor = AppTheme.stageCurrent.withAlpha(40);
      borderColor = AppTheme.stageCurrent;
      content = Text(
        '${stage.stageNumber}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      );
    } else if (isUnlocked) {
      bgColor = AppTheme.bgCard;
      borderColor = AppTheme.stageCurrent.withAlpha(100);
      content = Text(
        '${stage.stageNumber}',
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      );
    } else {
      bgColor = AppTheme.stageLocked.withAlpha(30);
      borderColor = AppTheme.stageLocked.withAlpha(60);
      content = GameIcon(
        assetPath: ImageAssets.lock,
        fallbackEmoji: '🔒',
        size: 20,
      );
    }

    return Container(
      width: nodeSize,
      height: nodeSize,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor,
          width: isCurrent ? 3 : 2,
        ),
        boxShadow: [
          if (isCleared)
            BoxShadow(
              color: AppTheme.stageCleared.withAlpha(50),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          if (isCurrent)
            BoxShadow(
              color: AppTheme.stageCurrent.withAlpha(60),
              blurRadius: 14,
              spreadRadius: 3,
            ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          content,
          // Boss 標記
          if (isBoss)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: const Text(
                  '👑',
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════
// 關卡摘要彈窗 — 資訊標籤
// ═══════════════════════════════════════

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(30)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondary.withAlpha(150),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
