import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/level.dart';
import '../data/levels_repository.dart';
import '../data/progress_repository.dart';

/// Repositories (singletons). ProgressRepository is overridden in main()
/// with an already-initialised instance.
final levelsRepositoryProvider =
    Provider<LevelsRepository>((ref) => LevelsRepository());

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => throw UnimplementedError('Override in main() after init'),
);

/// All 100 levels from the JSON asset.
final levelsProvider = FutureProvider<List<Level>>((ref) async {
  return ref.read(levelsRepositoryProvider).loadLevels();
});

/// Number of solved levels. Bumped via [ProgressNotifier].
final solvedCountProvider =
    StateNotifierProvider<ProgressNotifier, int>((ref) {
  final repo = ref.read(progressRepositoryProvider);
  return ProgressNotifier(repo);
});

class ProgressNotifier extends StateNotifier<int> {
  final ProgressRepository _repo;
  ProgressNotifier(this._repo) : super(_repo.solvedCount);

  bool isSolved(int level) => level <= state;
  bool isUnlocked(int level) => level <= state + 1;
  int currentLevel(int total) => (state + 1).clamp(1, total);

  Future<void> solve(int level) async {
    await _repo.markSolved(level);
    state = _repo.solvedCount;
  }

  Future<void> reset() async {
    await _repo.reset();
    state = _repo.solvedCount;
  }
}
