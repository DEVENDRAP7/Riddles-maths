import 'package:hive_flutter/hive_flutter.dart';

/// Local-only progress storage (Hive). No cloud, no accounts.
///
/// Stores how many levels the player has solved. The "current level"
/// the player is on = solvedCount + 1 (capped at totalLevels).
class ProgressRepository {
  static const _boxName = 'progress';
  static const _solvedKey = 'solvedCount';

  late Box _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  /// Number of levels solved so far (0..total).
  int get solvedCount => (_box.get(_solvedKey, defaultValue: 0) as int);

  /// The level the player is currently on (1-based).
  int currentLevel(int totalLevels) =>
      (solvedCount + 1).clamp(1, totalLevels);

  bool isSolved(int level) => level <= solvedCount;

  bool isUnlocked(int level) => level <= solvedCount + 1;

  /// Mark [level] as solved. Only advances when solving the current level.
  Future<void> markSolved(int level) async {
    if (level == solvedCount + 1) {
      await _box.put(_solvedKey, solvedCount + 1);
    }
  }

  Future<void> reset() async => _box.put(_solvedKey, 0);
}
