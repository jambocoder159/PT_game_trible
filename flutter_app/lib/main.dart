// PT Game Trible - 貓咪特工三消手遊
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'core/services/local_storage.dart';
import 'core/services/settings_service.dart';
import 'features/game/providers/game_provider.dart';
import 'features/game/providers/battle_provider.dart';
import 'features/agents/providers/player_provider.dart';
import 'features/idle/providers/idle_provider.dart';
import 'features/idle/providers/cat_provider.dart';
import 'features/idle/screens/home_screen.dart';
import 'features/tutorial/screens/tutorial_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 鎖定豎屏
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 全螢幕沉浸式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // 初始化本地存檔
  await LocalStorageService.instance.init();

  // 初始化設定服務
  await SettingsService.instance.init();

  runApp(const Match3App());
}

class Match3App extends StatelessWidget {
  const Match3App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameProvider()),
        ChangeNotifierProvider(create: (_) => BattleProvider()),
        ChangeNotifierProvider(create: (_) {
          final provider = PlayerProvider();
          provider.init();
          return provider;
        }),
        ChangeNotifierProvider(create: (_) => IdleProvider()),
        ChangeNotifierProvider(create: (_) {
          final provider = CatProvider();
          provider.init();
          return provider;
        }),
      ],
      child: MaterialApp(
        title: '貓咪特工',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Consumer<PlayerProvider>(
          builder: (context, player, _) {
            if (!player.isInitialized) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (!player.data.tutorialCompleted) {
              return const TutorialScreen();
            }
            return const HomeScreen();
          },
        ),
      ),
    );
  }
}
