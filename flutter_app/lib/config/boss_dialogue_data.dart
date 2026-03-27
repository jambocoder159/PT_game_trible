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
    bossId: 'moldy_bread_king',
    bossName: '黴菌麵包王',
    chapter: 1,
    introLines: [
      '哈啾！誰來打擾我的發酵王國！',
      '這些黴菌花了我好久才種出來的！\n你們不准碰！',
    ],
  ),
  2: BossDialogue(
    bossId: 'melting_icecream',
    bossName: '融化冰淇淋怪',
    chapter: 2,
    introLines: [
      '嗚嗚～好熱好熱～我在融化了～',
      '如果我要消失的話……\n就讓所有東西都跟我一起融化吧！',
    ],
  ),
  3: BossDialogue(
    bossId: 'burnt_chocolate',
    bossName: '烤焦巧克力魔',
    chapter: 3,
    introLines: [
      '苦！苦才是真正的味道！',
      '你們這些只愛甜食的傢伙不會懂的！\n讓我把一切都烤成焦炭！',
    ],
  ),
  4: BossDialogue(
    bossId: 'sour_cream',
    bossName: '酸掉鮮奶油怪',
    chapter: 4,
    introLines: [
      '我……曾經是最漂亮的生日蛋糕……',
      '既然沒有人記得我的味道……\n那就讓所有蛋糕都酸掉吧！',
    ],
  ),
  5: BossDialogue(
    bossId: 'hard_mochi_king',
    bossName: '變硬麻糬大王',
    chapter: 5,
    introLines: [
      '……硬邦邦……好久沒人來泡茶了……',
      '如果沒有人願意重新蒸我的話……\n那你們也一起變硬吧！',
    ],
  ),
  6: BossDialogue(
    bossId: 'dark_cuisine_king',
    bossName: '黑暗料理王',
    chapter: 6,
    introLines: [
      '終於有貓來了嗎……',
      '我是被遺棄的食材、被遺忘的味道……',
      '甜點街的一切痛苦，都在我身上！\n讓我結束這個假裝幸福的地方！',
    ],
  ),
};
