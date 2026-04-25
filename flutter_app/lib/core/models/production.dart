import 'block.dart';

/// A single cat production job.
class ProductionSlot {
  final String id;
  final String catId;
  final String dessertId;
  final BlockColor sourceColor;
  final DateTime startTime;
  final int durationMs;
  final bool isComplete;

  const ProductionSlot({
    required this.id,
    required this.catId,
    required this.dessertId,
    required this.sourceColor,
    required this.startTime,
    required this.durationMs,
    this.isComplete = false,
  });

  int elapsedMs(DateTime now) {
    return now.difference(startTime).inMilliseconds.clamp(0, durationMs);
  }

  int remainingMs(DateTime now) => durationMs - elapsedMs(now);

  double progress(DateTime now) {
    if (durationMs <= 0) return 1.0;
    return (elapsedMs(now) / durationMs).clamp(0.0, 1.0);
  }

  bool isReady(DateTime now) => isComplete || remainingMs(now) <= 0;

  ProductionSlot copyWith({
    String? id,
    String? catId,
    String? dessertId,
    BlockColor? sourceColor,
    DateTime? startTime,
    int? durationMs,
    bool? isComplete,
  }) {
    return ProductionSlot(
      id: id ?? this.id,
      catId: catId ?? this.catId,
      dessertId: dessertId ?? this.dessertId,
      sourceColor: sourceColor ?? this.sourceColor,
      startTime: startTime ?? this.startTime,
      durationMs: durationMs ?? this.durationMs,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  factory ProductionSlot.fromJson(Map<String, dynamic> json) {
    final colorIndex = (json['sourceColorIndex'] as num?)?.toInt() ?? 0;
    return ProductionSlot(
      id: json['id'] as String? ?? '',
      catId: json['catId'] as String? ?? '',
      dessertId: json['dessertId'] as String? ?? '',
      sourceColor:
          BlockColor.values[colorIndex.clamp(0, BlockColor.values.length - 1)],
      startTime: DateTime.tryParse(json['startTime'] as String? ?? '') ??
          DateTime.now(),
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      isComplete: json['isComplete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'catId': catId,
        'dessertId': dessertId,
        'sourceColorIndex': sourceColor.index,
        'startTime': startTime.toIso8601String(),
        'durationMs': durationMs,
        'isComplete': isComplete,
      };
}

/// Finished desserts waiting to be sold.
class DisplayCase {
  final Map<String, int> desserts;
  final int maxCapacity;

  const DisplayCase({
    this.desserts = const {},
    this.maxCapacity = 10,
  });

  int get totalCount => desserts.values.fold(0, (sum, count) => sum + count);

  int get remainingCapacity => (maxCapacity - totalCount).clamp(0, maxCapacity);

  bool get isFull => totalCount >= maxCapacity;

  int countOf(String dessertId) => desserts[dessertId] ?? 0;

  DisplayCase addDessert(String dessertId, [int count = 1]) {
    if (count <= 0 || remainingCapacity <= 0) return this;
    final actual = count.clamp(0, remainingCapacity);
    final next = Map<String, int>.from(desserts);
    next[dessertId] = (next[dessertId] ?? 0) + actual;
    return DisplayCase(desserts: next, maxCapacity: maxCapacity);
  }

  DisplayCase removeDessert(String dessertId, [int count = 1]) {
    if (count <= 0 || !desserts.containsKey(dessertId)) return this;
    final next = Map<String, int>.from(desserts);
    final remaining = (next[dessertId] ?? 0) - count;
    if (remaining > 0) {
      next[dessertId] = remaining;
    } else {
      next.remove(dessertId);
    }
    return DisplayCase(desserts: next, maxCapacity: maxCapacity);
  }

  DisplayCase clear() => DisplayCase(maxCapacity: maxCapacity);

  factory DisplayCase.fromJson(Map<String, dynamic> json) {
    final rawDesserts = json['desserts'] as Map<String, dynamic>? ?? {};
    return DisplayCase(
      desserts: rawDesserts.map((key, value) => MapEntry(
            key,
            (value as num).toInt(),
          )),
      maxCapacity: (json['maxCapacity'] as num?)?.toInt() ?? 10,
    );
  }

  Map<String, dynamic> toJson() => {
        'desserts': desserts,
        'maxCapacity': maxCapacity,
      };
}
