import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tutorial_state.dart';
import '../providers/tutorial_provider.dart';
import 'phase0_opening_screen.dart';
import 'phase1_home_screen.dart';
import 'phase2_cutscene_screen.dart';
import 'phase3_battle_screen.dart';
import 'phase4_return_screen.dart';

/// 教學路由器 — 根據 TutorialProvider 的階段顯示對應畫面
class TutorialRouter extends StatelessWidget {
  const TutorialRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TutorialProvider>(
      builder: (context, tutorial, _) {
        if (!tutorial.isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        switch (tutorial.currentPhase) {
          case TutorialPhase.phase0:
            return const Phase0OpeningScreen();
          case TutorialPhase.phase1:
            return const Phase1HomeScreen();
          case TutorialPhase.phase2:
            return const Phase2CutsceneScreen();
          case TutorialPhase.phase3:
            return const Phase3BattleScreen();
          case TutorialPhase.phase4:
            return const Phase4ReturnScreen();
          case TutorialPhase.completed:
            // 不應到這裡，main.dart 會直接導向 HomeScreen
            return const Scaffold(
              body: Center(child: Text('教學已完成')),
            );
        }
      },
    );
  }
}
