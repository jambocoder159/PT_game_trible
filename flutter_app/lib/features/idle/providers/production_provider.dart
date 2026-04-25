import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../config/ingredient_data.dart';
import '../../../core/models/block.dart';
import '../../../core/models/dessert.dart';
import '../../../core/models/player_data.dart';
import '../../../core/models/production.dart';
import '../../../core/services/local_storage.dart';
import 'bottle_provider.dart';

class ProductionSaleResult {
  final Map<String, int> dessertsSold;
  final int totalGold;
  final int critBonusGold;
  final int critCount;

  const ProductionSaleResult({
    required this.dessertsSold,
    required this.totalGold,
    required this.critBonusGold,
    required this.critCount,
  });

  bool get isEmpty => totalGold <= 0;
}

/// Timed dessert production for the idle loop.
class ProductionProvider extends ChangeNotifier {
  static const _storageKey = 'idle_production_state';
  static const _uuid = Uuid();
  static const double catSpeedPerLevel = 0.02;
  static const double baseCritChance = 0.15;
  static const double productionDurationMultiplier = 0.75;

  final Random _random;
  final List<ProductionSlot> _activeSlots = [];
  DisplayCase _displayCase = const DisplayCase();
  Timer? _timer;
  bool _isInitialized = false;
  DateTime _now = DateTime.now();

  ProductionProvider({Random? random}) : _random = random ?? Random();

  bool get isInitialized => _isInitialized;
  DateTime get now => _now;
  List<ProductionSlot> get activeSlots => List.unmodifiable(_activeSlots);
  DisplayCase get displayCase => _displayCase;

  Future<void> init() async {
    await LocalStorageService.instance.init();
    _load();
    _completeReadySlots(DateTime.now());
    _isInitialized = true;
    _startTimer();
    notifyListeners();
    await _save();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool isCatBusy(String catId) {
    return _activeSlots.any((slot) => slot.catId == catId);
  }

  List<String> idleCats(List<String> teamIds) {
    return teamIds.where((id) => !isCatBusy(id)).toList();
  }

  String? firstIdleCat(List<String> teamIds) {
    final cats = idleCats(teamIds);
    return cats.isEmpty ? null : cats.first;
  }

  int durationMsFor(DessertRecipe recipe, int catLevel) {
    final efficiency = 1.0 + (catLevel - 1).clamp(0, 999) * catSpeedPerLevel;
    return ((recipe.craftDurationSec * 1000 * productionDurationMultiplier) /
            efficiency)
        .round()
        .clamp(1000, 86400000);
  }

  bool canStartProduction({
    required String catId,
    required String dessertId,
    required BlockColor sourceColor,
    required BottleProvider bottleProvider,
  }) {
    if (catId.isEmpty || isCatBusy(catId) || _displayCase.isFull) {
      return false;
    }
    final recipe = DessertDefinitions.getById(dessertId);
    if (recipe == null) return false;
    if (recipe.sourceColor != null && recipe.sourceColor != sourceColor) {
      return false;
    }
    if (!bottleProvider.canProduce(sourceColor, dessertId)) return false;
    return true;
  }

  Future<bool> startProduction({
    required String catId,
    required String dessertId,
    required BlockColor sourceColor,
    required int catLevel,
    required BottleProvider bottleProvider,
  }) async {
    _completeReadySlots(DateTime.now());
    if (!canStartProduction(
      catId: catId,
      dessertId: dessertId,
      sourceColor: sourceColor,
      bottleProvider: bottleProvider,
    )) {
      return false;
    }

    final recipe = DessertDefinitions.getById(dessertId)!;
    final energyCost = recipe.directEnergyCost ?? 0;
    if (!bottleProvider.consumeEnergy(sourceColor, energyCost)) return false;

    _activeSlots.add(ProductionSlot(
      id: _uuid.v4(),
      catId: catId,
      dessertId: dessertId,
      sourceColor: sourceColor,
      startTime: DateTime.now(),
      durationMs: durationMsFor(recipe, catLevel),
    ));

    notifyListeners();
    await _save();
    return true;
  }

  Future<void> tick() async {
    final didChange = _completeReadySlots(DateTime.now());
    if (didChange) {
      notifyListeners();
      await _save();
    } else {
      _now = DateTime.now();
      notifyListeners();
    }
  }

  Future<ProductionSaleResult> sellOne(
      String dessertId, PlayerData playerData) async {
    final count = _displayCase.countOf(dessertId);
    if (count <= 0) return _emptySale();

    final result = _sellEntries({dessertId: 1}, playerData);
    _displayCase = _displayCase.removeDessert(dessertId);
    _completeReadySlots(DateTime.now());
    notifyListeners();
    await _save();
    return result;
  }

  Future<ProductionSaleResult> sellAll(PlayerData playerData) async {
    if (_displayCase.totalCount <= 0) return _emptySale();
    final entries = Map<String, int>.from(_displayCase.desserts);
    final result = _sellEntries(entries, playerData);
    _displayCase = _displayCase.clear();
    _completeReadySlots(DateTime.now());
    notifyListeners();
    await _save();
    return result;
  }

  ProductionSaleResult _sellEntries(
      Map<String, int> entries, PlayerData playerData) {
    final dessertsSold = <String, int>{};
    var totalGold = 0;
    var critBonusGold = 0;
    var critCount = 0;

    for (final entry in entries.entries) {
      final recipe = DessertDefinitions.getById(entry.key);
      if (recipe == null || entry.value <= 0) continue;

      var gold = recipe.sellPrice * entry.value;
      var entryBonusGold = 0;
      for (var i = 0; i < entry.value; i++) {
        if (_random.nextDouble() < baseCritChance) {
          critCount++;
          entryBonusGold += (recipe.sellPrice * 0.5).round();
        }
      }
      critBonusGold += entryBonusGold;
      gold += entryBonusGold;
      dessertsSold[entry.key] = entry.value;
      totalGold += gold;
    }

    playerData.gold += totalGold;
    return ProductionSaleResult(
      dessertsSold: dessertsSold,
      totalGold: totalGold,
      critBonusGold: critBonusGold,
      critCount: critCount,
    );
  }

  ProductionSaleResult _emptySale() {
    return const ProductionSaleResult(
      dessertsSold: {},
      totalGold: 0,
      critBonusGold: 0,
      critCount: 0,
    );
  }

  bool _completeReadySlots(DateTime now) {
    _now = now;
    var didChange = false;

    for (var i = _activeSlots.length - 1; i >= 0; i--) {
      final slot = _activeSlots[i];
      if (!slot.isReady(now)) continue;
      if (_displayCase.isFull) {
        if (!slot.isComplete) {
          _activeSlots[i] = slot.copyWith(isComplete: true);
          didChange = true;
        }
        continue;
      }
      _displayCase = _displayCase.addDessert(slot.dessertId);
      _activeSlots.removeAt(i);
      didChange = true;
    }

    return didChange;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      tick();
    });
  }

  void _load() {
    final raw = LocalStorageService.instance.getJson(_storageKey);
    if (raw is! Map<String, dynamic>) return;

    final slots = raw['activeSlots'] as List<dynamic>? ?? [];
    _activeSlots
      ..clear()
      ..addAll(slots
          .whereType<Map<String, dynamic>>()
          .map(ProductionSlot.fromJson)
          .where((slot) => slot.catId.isNotEmpty && slot.dessertId.isNotEmpty));

    final displayRaw = raw['displayCase'];
    if (displayRaw is Map<String, dynamic>) {
      _displayCase = DisplayCase.fromJson(displayRaw);
    }
  }

  Future<void> _save() async {
    await LocalStorageService.instance.setJson(_storageKey, {
      'activeSlots': _activeSlots.map((slot) => slot.toJson()).toList(),
      'displayCase': _displayCase.toJson(),
      'lastActiveTime': DateTime.now().toIso8601String(),
    });
  }
}
