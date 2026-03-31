/// 教學對話資料
class TutorialDialogue {
  final String id;
  final String speaker;
  final String content;
  final bool canSkip;
  final double? autoAdvanceDelay;

  const TutorialDialogue({
    required this.id,
    required this.speaker,
    required this.content,
    this.canSkip = false,
    this.autoAdvanceDelay,
  });
}

/// 說話者常數
class Speakers {
  static const narrator = '旁白';
  static const letter = '信件';
  static const grandpa = '爺爺';
  static const kitten = '小貓';
  static const lulu = '露露';
  static const unknown = '???';
}

/// 所有教學對話台詞
class TutorialDialogues {
  TutorialDialogues._();

  // ─── Phase 0：開場動畫 ───
  static const t001 = TutorialDialogue(
    id: 'T001', speaker: Speakers.narrator, canSkip: true,
    content: '在一個被群山環繞的小鎮裡，有一條曾經熱鬧非凡的甜點街。',
  );
  static const t002 = TutorialDialogue(
    id: 'T002', speaker: Speakers.narrator, canSkip: true,
    content: '直到有一天，甜點街的守護者——點心爺爺離開了小鎮。',
  );
  static const t003 = TutorialDialogue(
    id: 'T003', speaker: Speakers.narrator, canSkip: true,
    content: '食材開始變質……壞掉的食物精靈佔據了每家店的地下室。',
  );
  static const t004 = TutorialDialogue(
    id: 'T004', speaker: Speakers.narrator, canSkip: true,
    content: '某天，一隻年輕的小貓收到了一封信——',
  );
  static const t005 = TutorialDialogue(
    id: 'T005', speaker: Speakers.letter, canSkip: true,
    content: '親愛的孩子，甜點街就交給你了。\n地下室的鑰匙在信封裡。\n——點心爺爺',
  );

  static const phase0 = [t001, t002, t003, t004, t005];

  // ─── Phase 1：首頁教學 ───
  static const t006 = TutorialDialogue(
    id: 'T006', speaker: Speakers.grandpa,
    content: '推開這扇門吧，孩子。這是爺爺留給你的麵包店。',
  );
  static const t007 = TutorialDialogue(
    id: 'T007', speaker: Speakers.grandpa,
    content: '看到這些方塊了嗎？它們代表大自然的五種烘焙元素。',
  );
  static const t008 = TutorialDialogue(
    id: 'T008', speaker: Speakers.grandpa,
    content: '☀️陽光麥穗、🍃香草葉、💧清泉水滴、⭐星砂糖、🌙月光莓果。',
    autoAdvanceDelay: 3.0,
  );
  static const t009a = TutorialDialogue(
    id: 'T009a', speaker: Speakers.grandpa,
    content: '看到棋盤上的食材了嗎？點一下就能採集它喔！',
  );
  static const t009b = TutorialDialogue(
    id: 'T009b', speaker: Speakers.grandpa,
    content: '就是這樣！點擊就能採集食材。',
    autoAdvanceDelay: 1.5,
  );
  static const t009c = TutorialDialogue(
    id: 'T009c', speaker: Speakers.grandpa,
    content: '不過光是採集還不夠。試試把食材往上拖拖看——',
  );
  static const t009d = TutorialDialogue(
    id: 'T009d', speaker: Speakers.grandpa,
    content: '很好！往上拖，食材就會移到最頂部。',
    autoAdvanceDelay: 1.5,
  );
  static const t009e = TutorialDialogue(
    id: 'T009e', speaker: Speakers.grandpa,
    content: '往下拖的話，就會移到最底部。這可是排列食材的關鍵技巧！',
  );
  static const t009f = TutorialDialogue(
    id: 'T009f', speaker: Speakers.grandpa,
    content: '現在來試試重點——讓三個相同的食材排在一起！',
  );
  static const t010a = TutorialDialogue(
    id: 'T010a', speaker: Speakers.grandpa,
    content: '太棒了！三個同色食材排在一起就會釋放大量能量！',
    autoAdvanceDelay: 2.0,
  );
  static const t010b = TutorialDialogue(
    id: 'T010b', speaker: Speakers.grandpa,
    content: '記住：點擊採集、滑動移動、製造三連消——這就是經營的基本功！',
  );
  static const t011 = TutorialDialogue(
    id: 'T011', speaker: Speakers.grandpa,
    content: '看，能量條快滿了！能量滿了就能做出食材囉。',
  );
  static const t012 = TutorialDialogue(
    id: 'T012', speaker: Speakers.grandpa,
    content: '有了食材，就能做出好吃的點心了！試試看吧。',
  );
  static const t013 = TutorialDialogue(
    id: 'T013', speaker: Speakers.grandpa,
    content: '把點心擺到店面，就會有客人來買啦！',
  );
  static const t014 = TutorialDialogue(
    id: 'T014', speaker: Speakers.grandpa,
    content: '太棒了！你賺到了第一筆糖果幣！',
    autoAdvanceDelay: 2.0,
  );
  static const t015 = TutorialDialogue(
    id: 'T015', speaker: Speakers.grandpa,
    content: '來，試試看自己做出 3 份點心出售吧！我相信你可以的。',
  );
  static const t016 = TutorialDialogue(
    id: 'T016', speaker: Speakers.grandpa,
    content: '很好！你已經掌握了基本的經營之道。',
  );

  // ─── Phase 2：劇情過場 ───
  static const t017 = TutorialDialogue(
    id: 'T017', speaker: Speakers.kitten, canSkip: true,
    content: '嗯？地下室好像有聲音……',
  );
  static const t018 = TutorialDialogue(
    id: 'T018', speaker: Speakers.grandpa, canSkip: true,
    content: '啊，差點忘了。信封裡還有地下室的鑰匙。',
  );
  static const t019 = TutorialDialogue(
    id: 'T019', speaker: Speakers.grandpa, canSkip: true,
    content: '地下室被壞掉的食物精靈佔據了。你得去清理，才能取得更好的食材。',
  );
  static const t020 = TutorialDialogue(
    id: 'T020', speaker: Speakers.grandpa, canSkip: true,
    content: '別擔心，食材的力量會保護你的。',
  );

  static const phase2 = [t017, t018, t019, t020];

  // ─── Phase 3：闖關教學 ───
  static const t021 = TutorialDialogue(
    id: 'T021', speaker: Speakers.grandpa,
    content: '第一間地下室就在我們麵包店下面。小心那些壞掉的麵包精靈！',
  );
  static const t022 = TutorialDialogue(
    id: 'T022', speaker: Speakers.grandpa,
    content: '在地下室裡，消除食材就能對搗蛋鬼造成傷害！來，試試看！',
  );
  static const t023 = TutorialDialogue(
    id: 'T023', speaker: Speakers.grandpa,
    content: '看！食材能量可以淨化牠們！三連消的傷害特別高喔！',
    autoAdvanceDelay: 2.0,
  );
  static const t024 = TutorialDialogue(
    id: 'T024', speaker: Speakers.grandpa,
    content: '幹得好！看看你獲得了什麼。',
  );
  static const t025 = TutorialDialogue(
    id: 'T025', speaker: Speakers.grandpa,
    content: '每次冒險都會獲得糖果幣。',
    autoAdvanceDelay: 2.0,
  );
  static const t026 = TutorialDialogue(
    id: 'T026', speaker: Speakers.grandpa,
    content: '經驗值可以讓你的夥伴變得更強。',
    autoAdvanceDelay: 2.0,
  );
  static const t027 = TutorialDialogue(
    id: 'T027', speaker: Speakers.grandpa,
    content: '表現越好，星星越多！',
    autoAdvanceDelay: 2.0,
  );
  static const t028 = TutorialDialogue(
    id: 'T028', speaker: Speakers.grandpa,
    content: '再往裡面走走，把更多搗蛋鬼趕出去吧。',
  );
  static const t029 = TutorialDialogue(
    id: 'T029', speaker: Speakers.grandpa,
    content: '注意左邊小麥的能量條。消除☀️陽光麥穗方塊，會幫她累積能量喔！',
  );
  static const t030 = TutorialDialogue(
    id: 'T030', speaker: Speakers.grandpa,
    content: '很好！繼續消除，讓能量條填滿！',
    autoAdvanceDelay: 2.0,
  );
  static const t031 = TutorialDialogue(
    id: 'T031', speaker: Speakers.grandpa,
    content: '小心！搗蛋鬼也會反擊的。注意牠們頭上的倒數計時。',
  );
  static const t032 = TutorialDialogue(
    id: 'T032', speaker: Speakers.grandpa,
    content: '倒數到 0 的時候，牠們就會攻擊你的夥伴。',
    autoAdvanceDelay: 2.5,
  );
  static const t033 = TutorialDialogue(
    id: 'T033', speaker: Speakers.grandpa,
    content: '能量滿了！快點小麥的頭像，讓她施展料理技能！',
  );
  static const t034 = TutorialDialogue(
    id: 'T034', speaker: Speakers.grandpa,
    content: '漂亮！這就是料理技能的力量！',
    autoAdvanceDelay: 2.0,
  );
  static const t035 = TutorialDialogue(
    id: 'T035', speaker: Speakers.grandpa,
    content: '我記得地下室深處好像有什麼人的聲音……去看看吧。',
  );
  static const t036 = TutorialDialogue(
    id: 'T036', speaker: Speakers.unknown,
    content: '嗚嗚……有人嗎？我被困在這裡好久了……',
  );
  static const t037 = TutorialDialogue(
    id: 'T037', speaker: Speakers.kitten,
    content: '你沒事吧！我來幫你！',
    autoAdvanceDelay: 1.5,
  );
  static const t038 = TutorialDialogue(
    id: 'T038', speaker: Speakers.lulu,
    content: '謝謝你救了我！我叫露露，是隔壁果汁吧的店員。',
  );
  static const t039 = TutorialDialogue(
    id: 'T039', speaker: Speakers.lulu,
    content: '那些壞掉的食物精靈突然出現，我就被困住了……',
    autoAdvanceDelay: 2.0,
  );
  static const t040 = TutorialDialogue(
    id: 'T040', speaker: Speakers.lulu,
    content: '讓我加入你吧！我可以幫忙的！',
  );

  // ─── Phase 4：回首頁收尾 ───
  static const t041 = TutorialDialogue(
    id: 'T041', speaker: Speakers.grandpa,
    content: '露露想加入你的隊伍呢！來，把她安排進去吧。',
  );
  static const t042 = TutorialDialogue(
    id: 'T042', speaker: Speakers.grandpa,
    content: '很好！露露是💧水滴屬性的支援者。',
  );
  static const t043 = TutorialDialogue(
    id: 'T043', speaker: Speakers.grandpa,
    content: '消除💧清泉水滴方塊會幫她累積能量，她的技能可以治療夥伴喔！',
    autoAdvanceDelay: 3.0,
  );
  static const t044 = TutorialDialogue(
    id: 'T044', speaker: Speakers.grandpa,
    content: '冒險獲得的經驗可以讓夥伴變強。來，用特濃咖啡幫小麥補充一下吧！',
  );
  static const t045 = TutorialDialogue(
    id: 'T045', speaker: Speakers.grandpa,
    content: '小麥變強了！夥伴等級越高，冒險就越輕鬆。',
    autoAdvanceDelay: 2.0,
  );
  static const t046 = TutorialDialogue(
    id: 'T046', speaker: Speakers.grandpa,
    content: '對了，我幫你準備了一個好東西。',
  );
  static const t047 = TutorialDialogue(
    id: 'T047', speaker: Speakers.grandpa,
    content: '這是自動揉麵機！就算你不在，貓咪們也會自動收集食材喔。',
  );
  static const t048 = TutorialDialogue(
    id: 'T048', speaker: Speakers.grandpa,
    content: '自動模式開啟了！不過手動消除效率更高，記得常常回來看看。',
    autoAdvanceDelay: 2.5,
  );
  static const t049 = TutorialDialogue(
    id: 'T049', speaker: Speakers.grandpa,
    content: '每天完成一些小任務，就能拿到額外的獎勵喔！',
  );
  static const t050 = TutorialDialogue(
    id: 'T050', speaker: Speakers.grandpa,
    content: '記得每天回來完成任務，會有好東西的！',
    autoAdvanceDelay: 2.0,
  );
  static const t051 = TutorialDialogue(
    id: 'T051', speaker: Speakers.grandpa,
    content: '探索地下室需要消耗元氣。看到畫面上的🔥了嗎？',
  );
  static const t052 = TutorialDialogue(
    id: 'T052', speaker: Speakers.grandpa,
    content: '元氣用完了就好好休息，過一會兒就恢復了。',
    autoAdvanceDelay: 2.5,
  );
  static const t053 = TutorialDialogue(
    id: 'T053', speaker: Speakers.grandpa,
    content: '孩子，基本的事情你都學會了。',
  );
  static const t054 = TutorialDialogue(
    id: 'T054', speaker: Speakers.grandpa,
    content: '接下來就靠你了，把甜點街重新變得熱鬧吧！',
    autoAdvanceDelay: 2.0,
  );
  static const t055 = TutorialDialogue(
    id: 'T055', speaker: Speakers.grandpa,
    content: '有什麼不懂的，隨時翻翻我留下的筆記。加油！',
  );
}
