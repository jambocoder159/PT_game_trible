import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:match3_puzzle/config/ingredient_data.dart';
import 'package:match3_puzzle/core/models/block.dart';
import 'package:match3_puzzle/core/models/player_data.dart';
import 'package:match3_puzzle/features/idle/providers/bottle_provider.dart';
import 'package:match3_puzzle/features/idle/providers/production_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('startProduction consumes bottle energy and creates a timed slot',
      () async {
    final bottleProvider = BottleProvider();
    await bottleProvider.init();
    bottleProvider.addEnergy(BlockColor.coral, 30);

    final production = ProductionProvider();
    await production.init();

    final started = await production.startProduction(
      catId: 'blaze',
      dessertId: 'butter_roll',
      sourceColor: BlockColor.coral,
      catLevel: 1,
      bottleProvider: bottleProvider,
    );

    expect(started, true);
    expect(bottleProvider.getBottle(BlockColor.coral).currentEnergy, 0);
    expect(production.activeSlots, hasLength(1));
    expect(production.displayCase.totalCount, 0);

    production.dispose();
  });

  test('dessert balance maps mint and teal bottles to their own recipes',
      () async {
    final json = jsonDecode(
      File('assets/balance/desserts.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    DessertDefinitions.loadFromJson(json);

    final bottleProvider = BottleProvider();
    await bottleProvider.init();
    bottleProvider.addEnergy(BlockColor.mint, 30);
    bottleProvider.addEnergy(BlockColor.teal, 30);

    expect(
      DessertDefinitions.getById('mint_tea')?.sourceColor,
      BlockColor.mint,
    );
    expect(
      DessertDefinitions.getById('fresh_juice')?.sourceColor,
      BlockColor.teal,
    );
    expect(bottleProvider.canProduce(BlockColor.mint, 'mint_tea'), true);
    expect(bottleProvider.canProduce(BlockColor.teal, 'fresh_juice'), true);
  });

  test('init recovers completed offline production into the display case',
      () async {
    final past = DateTime.now().subtract(const Duration(minutes: 5));
    SharedPreferences.setMockInitialValues({
      'idle_production_state': jsonEncode({
        'activeSlots': [
          {
            'id': 'slot-1',
            'catId': 'blaze',
            'dessertId': 'butter_roll',
            'sourceColorIndex': BlockColor.coral.index,
            'startTime': past.toIso8601String(),
            'durationMs': 1000,
            'isComplete': false,
          }
        ],
        'displayCase': {
          'desserts': <String, int>{},
          'maxCapacity': 10,
        },
      }),
    });

    final production = ProductionProvider();
    await production.init();

    expect(production.activeSlots, isEmpty);
    expect(production.displayCase.countOf('butter_roll'), 1);

    production.dispose();
  });

  test('sellAll pays gold and clears the display case', () async {
    SharedPreferences.setMockInitialValues({
      'idle_production_state': jsonEncode({
        'activeSlots': [],
        'displayCase': {
          'desserts': {'butter_roll': 2},
          'maxCapacity': 10,
        },
      }),
    });

    final playerData = PlayerData.newPlayer();
    final startingGold = playerData.gold;
    final production = ProductionProvider();
    await production.init();

    final result = await production.sellAll(playerData);

    expect(result.totalGold, greaterThanOrEqualTo(80));
    expect(playerData.gold, startingGold + result.totalGold);
    expect(production.displayCase.totalCount, 0);

    production.dispose();
  });
}
