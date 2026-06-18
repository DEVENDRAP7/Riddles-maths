import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../state/providers.dart';
import '../widgets/bouncy_button.dart';
import '../widgets/cartoon_background.dart';

/// Home tab: shows the player's current level and a big Play button that
/// jumps straight into it.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelsAsync = ref.watch(levelsProvider);
    final solved = ref.watch(solvedCountProvider);

    return CartoonBackground(
      child: SafeArea(
        child: levelsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed to load levels\n$e')),
          data: (levels) {
            final total = levels.length;
            final current = (solved + 1).clamp(1, total);
            final allDone = solved >= total;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Text('Riddles', style: AppTheme.title(30, color: Colors.white))
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: -0.3),
                  Text('MATHS',
                          style: AppTheme.title(56, color: AppColors.sunYellow))
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.elasticOut),
                  const SizedBox(height: 12),
                  _ProgressBadge(solved: solved, total: total),
                  const SizedBox(height: 40),
                  BouncyButton(
                    label: allDone ? 'ALL DONE!' : 'PLAY  ·  LVL $current',
                    icon: allDone ? Icons.emoji_events : Icons.play_arrow_rounded,
                    color: AppColors.coral,
                    height: 76,
                    fontSize: 26,
                    onTap: () {
                      final target = allDone ? total : current;
                      context.push('/play/$target');
                    },
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(
                          begin: 1, end: 1.04, duration: 900.ms, curve: Curves.easeInOut),
                  const SizedBox(height: 18),
                  BouncyButton(
                    label: 'LEVELS',
                    icon: Icons.grid_view_rounded,
                    color: AppColors.accent,
                    baseColor: AppColors.accentDark,
                    height: 60,
                    fontSize: 20,
                    onTap: () => context.go('/levels'),
                  ),
                  const Spacer(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProgressBadge extends StatelessWidget {
  final int solved;
  final int total;
  const _ProgressBadge({required this.solved, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.accent, width: 2),
      ),
      child: Text('⭐ $solved / $total solved',
          style: AppTheme.title(18, color: AppColors.ink)),
    );
  }
}
