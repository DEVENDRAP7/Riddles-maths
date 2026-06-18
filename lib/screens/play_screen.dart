import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../data/level.dart';
import '../state/providers.dart';
import '../widgets/bouncy_button.dart';
import '../widgets/cartoon_background.dart';

class PlayScreen extends ConsumerStatefulWidget {
  final int levelNumber;
  const PlayScreen({super.key, required this.levelNumber});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen> {
  final _controller = TextEditingController();
  final _confetti = ConfettiController(duration: const Duration(seconds: 2));

  bool _showHint = false;
  bool _showSolution = false;
  bool _solved = false;
  bool _wrong = false;

  @override
  void dispose() {
    _controller.dispose();
    _confetti.dispose();
    super.dispose();
  }

  void _check(Level level) {
    if (level.isCorrect(_controller.text)) {
      setState(() {
        _solved = true;
        _wrong = false;
      });
      _confetti.play();
      ref.read(solvedCountProvider.notifier).solve(level.level);
      FocusScope.of(context).unfocus();
    } else {
      setState(() => _wrong = true);
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final levelsAsync = ref.watch(levelsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CartoonBackground(
        child: SafeArea(
          child: levelsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (levels) {
              final level = levels.firstWhere(
                (l) => l.level == widget.levelNumber,
                orElse: () => levels.first,
              );
              final total = levels.length;
              final hasNext = level.level < total;

              return Stack(
                alignment: Alignment.topCenter,
                children: [
                  Column(
                    children: [
                      _topBar(context, level.level, total),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                          child: Column(
                            children: [
                              _questionCard(level),
                              const SizedBox(height: 20),
                              if (!_solved) _answerField(level),
                              if (_wrong && !_solved) _wrongBanner(),
                              if (_showHint && !_solved) _infoCard(
                                  '💡 Hint', level.hint, AppColors.sunYellow),
                              if (_showSolution && !_solved) _infoCard(
                                  '✅ Solution', level.solution,
                                  AppColors.grassGreen),
                              if (_solved) _solvedCard(level, hasNext),
                              const SizedBox(height: 16),
                              if (!_solved) _helpButtons(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  ConfettiWidget(
                    confettiController: _confetti,
                    blastDirectionality: BlastDirectionality.explosive,
                    numberOfParticles: 24,
                    maxBlastForce: 22,
                    gravity: 0.3,
                    colors: const [
                      AppColors.coral,
                      AppColors.sunYellow,
                      AppColors.grassGreen,
                      AppColors.accent,
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, int lvl, int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 28),
            color: AppColors.ink,
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/home'),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent, width: 2),
            ),
            child: Text('Level $lvl / $total',
                style: AppTheme.title(18, color: AppColors.ink)),
          ),
          const Spacer(),
          const SizedBox(width: 28),
        ],
      ),
    );
  }

  Widget _questionCard(Level level) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.accent, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentDark.withValues(alpha: 0.25),
            offset: const Offset(0, 8),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Text('Crack the pattern',
              style: AppTheme.title(16, color: AppColors.coral)),
          const SizedBox(height: 16),
          Text(
            level.question,
            textAlign: TextAlign.center,
            style: AppTheme.title(30, color: AppColors.ink),
          ),
        ],
      ),
    ).animate().scale(duration: 350.ms, curve: Curves.easeOutBack);
  }

  Widget _answerField(Level level) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.accent, width: 2.5),
            ),
            child: TextField(
              controller: _controller,
              textAlign: TextAlign.center,
              style: AppTheme.title(24, color: AppColors.ink),
              decoration: const InputDecoration(
                hintText: 'Your answer',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
              onSubmitted: (_) => _check(level),
              onChanged: (_) {
                if (_wrong) setState(() => _wrong = false);
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        BouncyButton(
          label: 'GO',
          color: AppColors.grassGreen,
          baseColor: const Color(0xFF2E8B4E),
          height: 60,
          fontSize: 20,
          onTap: () => _check(level),
        ),
      ],
    );
  }

  Widget _wrongBanner() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text('Not quite — try again! 🤔',
              style: AppTheme.title(18, color: AppColors.coral))
          .animate()
          .shakeX(hz: 4, amount: 4),
    );
  }

  Widget _infoCard(String title, String body, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.title(16, color: AppColors.ink)),
          const SizedBox(height: 6),
          Text(body, style: AppTheme.title(16, color: AppColors.ink)),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _helpButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!_showHint)
          BouncyButton(
            label: 'HINT',
            icon: Icons.lightbulb_rounded,
            color: AppColors.sunYellow,
            baseColor: const Color(0xFFD9A800),
            height: 54,
            fontSize: 18,
            onTap: () => setState(() => _showHint = true),
          ),
        if (_showHint && !_showSolution) ...[
          const SizedBox(width: 14),
          BouncyButton(
            label: 'SOLUTION',
            icon: Icons.visibility_rounded,
            color: AppColors.accent,
            baseColor: AppColors.accentDark,
            height: 54,
            fontSize: 18,
            onTap: () => setState(() => _showSolution = true),
          ),
        ],
      ],
    );
  }

  Widget _solvedCard(Level level, bool hasNext) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.grassGreen.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.grassGreen, width: 2.5),
      ),
      child: Column(
        children: [
          Text('🎉 Correct!', style: AppTheme.title(30, color: AppColors.grassGreen))
              .animate()
              .scale(curve: Curves.elasticOut, duration: 600.ms),
          const SizedBox(height: 8),
          Text('Answer: ${level.answer}',
              style: AppTheme.title(20, color: AppColors.ink)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BouncyButton(
                label: 'LEVELS',
                color: AppColors.accent,
                baseColor: AppColors.accentDark,
                height: 56,
                fontSize: 18,
                onTap: () => context.go('/levels'),
              ),
              if (hasNext) ...[
                const SizedBox(width: 14),
                BouncyButton(
                  label: 'NEXT',
                  icon: Icons.arrow_forward_rounded,
                  color: AppColors.coral,
                  height: 56,
                  fontSize: 18,
                  onTap: () => context.pushReplacement(
                      '/play/${level.level + 1}'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
