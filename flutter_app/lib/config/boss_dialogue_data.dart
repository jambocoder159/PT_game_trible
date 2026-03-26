/// Boss 對話數據
/// 每章 Boss 關（X-10）開戰前的立繪對話演出
class BossDialogue {
  final String bossId;
  final String bossName;
  final int chapter;
  final List<String> introLines;

  const BossDialogue({
    required this.bossId,
    required this.bossName,
    required this.chapter,
    required this.introLines,
  });
}

const Map<int, BossDialogue> bossDialogues = {
  1: BossDialogue(
    bossId: 'rat_boss',
    bossName: '鼠幫老大',
    chapter: 1,
    introLines: [
      '哼，又是一隻多管閒事的貓...',
      '這條後巷是我的地盤！\n給我滾出去！',
    ],
  ),
  2: BossDialogue(
    bossId: 'shop_owner',
    bossName: '可疑店長',
    chapter: 2,
    introLines: [
      '你知道太多了...',
      '我不會讓你活著離開這家店！',
    ],
  ),
  3: BossDialogue(
    bossId: 'seagull_boss',
    bossName: '海鷗王',
    chapter: 3,
    introLines: [
      '嘎嘎嘎！這片港口歸我統治！',
      '讓你見識海鷗王的力量！',
    ],
  ),
  4: BossDialogue(
    bossId: 'ceo',
    bossName: '幕後金主',
    chapter: 4,
    introLines: [
      '你以為到了這裡就結束了？',
      '我才是這一切的幕後推手...\n你不過是棋盤上的一顆棋子。',
    ],
  ),
  5: BossDialogue(
    bossId: 'shadow_commander',
    bossName: '暗影指揮官',
    chapter: 5,
    introLines: [
      '暗影組織的力量，超乎你的想像...',
      '準備迎接你的末日吧！',
    ],
  ),
  6: BossDialogue(
    bossId: 'final_boss',
    bossName: '暗影組織首領',
    chapter: 6,
    introLines: [
      '終於來了嗎，小貓咪？',
      '讓我親自結束這場鬧劇...',
      '這世界的秩序，由我來重新書寫！',
    ],
  ),
};
