import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../state/providers.dart';

/// Levels tab: a grid of all 100 levels.
/// - solved  → green, tappable (replay)
/// - current → yellow, tappable (the next one to beat)
/// - locked  → grey, not tappable
class LevelsScreen extends ConsumerWidget {
  const LevelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelsAsync = ref.watch(levelsProvider);
    final solved = ref.watch(solvedCountProvider);

    return SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Levels',
                  style: AppTheme.title(34, color: Colors.white)),
            ),
            Expanded(
              child: levelsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (levels) {
                  final total = levels.length;
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 150),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: total,
                    itemBuilder: (context, i) {
                      final lvl = i + 1;
                      final isSolved = lvl <= solved;
                      final isCurrent = lvl == solved + 1;
                      final isLocked = lvl > solved + 1;
                      return _LevelTile(
                        level: lvl,
                        solved: isSolved,
                        current: isCurrent,
                        locked: isLocked,
                        onTap: isLocked
                            ? null
                            : () => context.push('/play/$lvl'),
                      ).animate().fadeIn(
                          delay: (i * 12).ms, duration: 250.ms);
                    },
                  );
                },
              ),
            ),
          ],
        ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  final int level;
  final bool solved;
  final bool current;
  final bool locked;
  final VoidCallback? onTap;

  const _LevelTile({
    required this.level,
    required this.solved,
    required this.current,
    required this.locked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = solved
        ? AppColors.solved
        : current
            ? AppColors.current
            : AppColors.locked;
    final Color textColor =
        current ? AppColors.ink : Colors.white;

    Widget content;
    if (locked) {
      content = const Icon(Icons.lock_rounded, color: Colors.white, size: 22);
    } else if (solved) {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_rounded, color: Colors.white, size: 18),
          Text('$level', style: AppTheme.title(15, color: Colors.white)),
        ],
      );
    } else {
      // current
      content = Text('$level', style: AppTheme.title(22, color: textColor));
    }

    final tile = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            offset: const Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Center(child: content),
    );

    return GestureDetector(
      onTap: onTap,
      child: current
          ? tile
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1, end: 1.08, duration: 700.ms)
          : tile,
    );
  }
}
