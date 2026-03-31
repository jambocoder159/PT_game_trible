import 'dart:convert';

/// 教學主階段
enum TutorialPhase {
  phase0, // 開場動畫
  phase1, // 首頁教學
  phase2, // 劇情過場
  phase3, // 闖關教學
  phase4, // 回首頁收尾
  completed,
}

/// 可序列化的教學狀態
class TutorialState {
  TutorialPhase currentPhase;
  int currentStep;
  int currentSubStep;

  // Phase 1 小任務
  int pastriesSold;

  // Phase 3
  int currentBattleStage; // 0=1-1, 1=1-2, 2=1-3
  bool luluRescued;

  // Phase 4 完成旗標
  bool teamSetupDone;
  bool upgradeDone;
  bool autoEliminateDone;
  bool dailyQuestDone;
  bool staminaDone;

  TutorialState({
    this.currentPhase = TutorialPhase.phase0,
    this.currentStep = 0,
    this.currentSubStep = 0,
    this.pastriesSold = 0,
    this.currentBattleStage = 0,
    this.luluRescued = false,
    this.teamSetupDone = false,
    this.upgradeDone = false,
    this.autoEliminateDone = false,
    this.dailyQuestDone = false,
    this.staminaDone = false,
  });

  factory TutorialState.initial() => TutorialState();

  Map<String, dynamic> toJson() => {
        'currentPhase': currentPhase.index,
        'currentStep': currentStep,
        'currentSubStep': currentSubStep,
        'pastriesSold': pastriesSold,
        'currentBattleStage': currentBattleStage,
        'luluRescued': luluRescued,
        'teamSetupDone': teamSetupDone,
        'upgradeDone': upgradeDone,
        'autoEliminateDone': autoEliminateDone,
        'dailyQuestDone': dailyQuestDone,
        'staminaDone': staminaDone,
      };

  factory TutorialState.fromJson(Map<String, dynamic> json) {
    final phaseIdx = json['currentPhase'] as int? ?? 0;
    return TutorialState(
      currentPhase: phaseIdx < TutorialPhase.values.length
          ? TutorialPhase.values[phaseIdx]
          : TutorialPhase.phase0,
      currentStep: json['currentStep'] as int? ?? 0,
      currentSubStep: json['currentSubStep'] as int? ?? 0,
      pastriesSold: json['pastriesSold'] as int? ?? 0,
      currentBattleStage: json['currentBattleStage'] as int? ?? 0,
      luluRescued: json['luluRescued'] as bool? ?? false,
      teamSetupDone: json['teamSetupDone'] as bool? ?? false,
      upgradeDone: json['upgradeDone'] as bool? ?? false,
      autoEliminateDone: json['autoEliminateDone'] as bool? ?? false,
      dailyQuestDone: json['dailyQuestDone'] as bool? ?? false,
      staminaDone: json['staminaDone'] as bool? ?? false,
    );
  }

  String serialize() => jsonEncode(toJson());

  factory TutorialState.deserialize(String data) {
    try {
      return TutorialState.fromJson(
          jsonDecode(data) as Map<String, dynamic>);
    } catch (_) {
      return TutorialState.initial();
    }
  }
}
