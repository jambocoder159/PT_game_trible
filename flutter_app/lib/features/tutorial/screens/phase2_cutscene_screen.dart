import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tutorial_provider.dart';

/// Phase 2：劇情過場
/// 原本的地下室過場對話已合併到 Phase 3 戰前對話中
/// 這裡直接跳到 Phase 3
class Phase2CutsceneScreen extends StatefulWidget {
  const Phase2CutsceneScreen({super.key});

  @override
  State<Phase2CutsceneScreen> createState() => _Phase2CutsceneScreenState();
}

class _Phase2CutsceneScreenState extends State<Phase2CutsceneScreen> {
  @override
  void initState() {
    super.initState();
    // 直接推進到 Phase 3
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TutorialProvider>().advancePhase();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
