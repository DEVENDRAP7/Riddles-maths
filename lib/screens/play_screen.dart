import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../ads/banner_ad_widget.dart';
import '../ads/rewarded_ad_service.dart';
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
  // Rewarded-ad gating: one tap on HINT plays 3 rewarded ads back to back to
  // unlock the hint; the SOLUTION button only works once the hint is unlocked,
  // and then plays 1 more rewarded ad to reveal the worked solution.
  static const int _hintAdsRequired = 3;

  final _controller = TextEditingController();
  final _confetti = ConfettiController(duration: const Duration(seconds: 2));
  final _rewarded = RewardedAdService();

  bool _hintUnlocked = false; // 3 ads watched
  bool _solutionUnlocked = false; // hint used + 1 ad watched
  bool _showHintOverlay = false; // hint overlay currently visible
  bool _showSolutionOverlay = false; // solution overlay currently visible
  bool _solved = false;
  bool _wrong = false;
  int _hintAdsWatched = 0;
  bool _watchingAd = false;

  @override
  void initState() {
    super.initState();
    _rewarded.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _confetti.dispose();
    _rewarded.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// HINT button. If already unlocked, just re-open the overlay. Otherwise
  /// plays the 3 rewarded ads one after another, then unlocks + shows it.
  /// Resumes from where it left off if the user bailed partway through.
  Future<void> _watchAdsForHint() async {
    if (_hintUnlocked) {
      setState(() => _showHintOverlay = true);
      return;
    }
    if (_watchingAd) return;
    setState(() => _watchingAd = true);
    while (_hintAdsWatched < _hintAdsRequired) {
      final earned = await _rewarded.show();
      if (!mounted) return;
      if (!earned) {
        setState(() => _watchingAd = false);
        _snack('Watch all $_hintAdsRequired ads to unlock the hint.');
        return;
      }
      setState(() => _hintAdsWatched++);
    }
    setState(() {
      _watchingAd = false;
      _hintUnlocked = true;
      _showHintOverlay = true;
    });
  }

  /// SOLUTION button. Locked until the hint is used. If already unlocked,
  /// re-open the overlay; otherwise watch one more rewarded ad to unlock it.
  Future<void> _watchForSolution() async {
    if (!_hintUnlocked) {
      _snack('Use the hint first.');
      return;
    }
    if (_solutionUnlocked) {
      setState(() => _showSolutionOverlay = true);
      return;
    }
    if (_watchingAd) return;
    setState(() => _watchingAd = true);
    final earned = await _rewarded.show();
    if (!mounted) return;
    setState(() {
      _watchingAd = false;
      if (earned) {
        _solutionUnlocked = true;
        _showSolutionOverlay = true;
      }
    });
    if (!earned) _snack('Watch the ad to reveal the solution.');
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
      body: Column(
        children: [
          Expanded(
            child: CartoonBackground(
              child: SafeArea(
                bottom: false,
                child: levelsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
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
                        // Fixed (non-scrolling) play layout.
                        Column(
                          children: [
                            _topBar(context, level.level, total),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  8,
                                  24,
                                  24,
                                ),
                                child: Column(
                                  children: [
                                    _questionCard(level),
                                    const SizedBox(height: 20),
                                    if (!_solved) _answerField(level),
                                    if (_wrong && !_solved) _wrongBanner(),
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
                        // Hint / solution as centered overlays above everything.
                        // Closing returns to the puzzle so the answer can be typed.
                        if (_showHintOverlay && !_solved)
                          _overlay(
                            content: _hintScroll(level.hint),
                            onClose: () =>
                                setState(() => _showHintOverlay = false),
                          ),
                        if (_showSolutionOverlay && !_solved)
                          _overlay(
                            content: _infoCard(
                              '✅ Solution',
                              level.solution,
                              AppColors.grassGreen,
                            ),
                            onClose: () =>
                                setState(() => _showSolutionOverlay = false),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const AdBar(),
        ],
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
            child: Text(
              'Level $lvl / $total',
              style: AppTheme.title(18, color: AppColors.ink),
            ),
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
          Text(
            'Crack the pattern',
            style: AppTheme.title(16, color: AppColors.coral),
          ),
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

  // --- Input handling (custom keypad only — never the system keyboard) ---
  void _append(String ch) {
    if (_controller.text.length >= 9) return;
    if (ch == '.' && _controller.text.contains('.')) return;
    setState(() {
      _controller.text += ch;
      _wrong = false;
    });
  }

  void _backspace() {
    if (_controller.text.isEmpty) return;
    setState(() {
      _controller.text = _controller.text.substring(
        0,
        _controller.text.length - 1,
      );
      _wrong = false;
    });
  }

  Widget _answerField(Level level) {
    final text = _controller.text;
    return Column(
      children: [
        // Answer display (read-only — no system keyboard).
        Container(
          width: double.infinity,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.accent, width: 2.5),
          ),
          child: Text(
            text.isEmpty ? 'Tap the numbers' : text,
            style: AppTheme.title(
              text.isEmpty ? 18 : 26,
              color: text.isEmpty ? AppColors.locked : AppColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Number pad.
        _padRow(['1', '2', '3']),
        const SizedBox(height: 10),
        _padRow(['4', '5', '6']),
        const SizedBox(height: 10),
        _padRow(['7', '8', '9']),
        const SizedBox(height: 10),
        _padRow(['.', '0', '<']),
        const SizedBox(height: 16),
        BouncyButton(
          label: 'CHECK',
          icon: Icons.check_rounded,
          color: AppColors.grassGreen,
          baseColor: const Color(0xFF2E8B4E),
          height: 60,
          fontSize: 22,
          onTap: () => _check(level),
        ),
      ],
    );
  }

  Widget _padRow(List<String> keys) {
    return Row(
      children: [
        for (var i = 0; i < keys.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _key(keys[i])),
        ],
      ],
    );
  }

  Widget _key(String label) {
    final isBack = label == '<';
    return GestureDetector(
      onTap: () => isBack ? _backspace() : _append(label),
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isBack ? AppColors.coral : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentDark.withValues(alpha: 0.18),
              offset: const Offset(0, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: isBack
            ? const Icon(Icons.backspace_rounded, color: Colors.white, size: 24)
            : Text(label, style: AppTheme.title(26, color: AppColors.ink)),
      ),
    );
  }

  Widget _wrongBanner() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Text(
        'Not quite — try again! 🤔',
        style: AppTheme.title(18, color: AppColors.coral),
      ).animate().shakeX(hz: 4, amount: 4),
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
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 14,
      runSpacing: 12,
      children: [
        BouncyButton(
          // Unlocked → just re-open. Locked → one tap plays 3 ads back to back.
          label: _hintUnlocked
              ? 'VIEW HINT'
              : (_watchingAd && _hintAdsWatched < _hintAdsRequired
                    ? 'AD $_hintAdsWatched/$_hintAdsRequired…'
                    : 'HINT  ·  WATCH $_hintAdsRequired ADS'),
          icon: _hintUnlocked
              ? Icons.lightbulb_rounded
              : Icons.play_circle_fill_rounded,
          color: AppColors.sunYellow,
          baseColor: const Color(0xFFD9A800),
          height: 54,
          fontSize: 18,
          onTap: _watchingAd ? null : _watchAdsForHint,
        ),
        BouncyButton(
          // Locked until hint used; then one ad reveals it, after that re-open.
          label: _solutionUnlocked ? 'VIEW SOLUTION' : 'SOLUTION',
          icon: !_hintUnlocked
              ? Icons.lock_rounded
              : (_solutionUnlocked
                    ? Icons.visibility_rounded
                    : Icons.play_circle_fill_rounded),
          color: AppColors.accent,
          baseColor: AppColors.accentDark,
          height: 54,
          fontSize: 18,
          onTap: _watchingAd ? null : _watchForSolution,
        ),
      ],
    );
  }

  /// A centered modal overlay above the whole play screen: dim barrier (tap to
  /// close) + the [content] card + a CLOSE button so the puzzle is reachable
  /// again to type the answer.
  Widget _overlay({required Widget content, required VoidCallback onClose}) {
    return Positioned.fill(
      child: Stack(
        children: [
          GestureDetector(
            onTap: onClose,
            child: Container(color: Colors.black.withValues(alpha: 0.55)),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  content,
                  const SizedBox(height: 18),
                  BouncyButton(
                    label: 'GOT IT',
                    icon: Icons.check_rounded,
                    color: AppColors.coral,
                    height: 50,
                    fontSize: 18,
                    onTap: onClose,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 180.ms);
  }

  /// The hint shown as an animated parchment scroll: two wooden rolls with a
  /// parchment panel between them that unfurls into view. The text is the
  /// puzzle's underlying logic (e.g. "Each number doubles.").
  Widget _hintScroll(String logic) {
    const parchment = Color(0xFFF6E8C8);
    const parchmentEdge = Color(0xFFE7D2A4);
    const roll = Color(0xFFB07D3F);
    const rollDark = Color(0xFF6B4423);

    Widget rollBar() => Container(
      width: double.infinity,
      height: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [roll, rollDark],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(0, 2),
            blurRadius: 3,
          ),
        ],
      ),
    );

    return Container(
          margin: const EdgeInsets.only(top: 16),
          width: double.infinity,
          child: Column(
            children: [
              rollBar(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [parchment, parchmentEdge],
                  ),
                  border: const Border.symmetric(
                    vertical: BorderSide(color: rollDark, width: 2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '💡  The Logic',
                      style: AppTheme.title(16, color: rollDark),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      logic,
                      textAlign: TextAlign.center,
                      style: AppTheme.title(20, color: AppColors.ink),
                    ),
                  ],
                ),
              ),
              rollBar(),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 250.ms)
        .scaleXY(
          begin: 0.85,
          end: 1,
          duration: 350.ms,
          curve: Curves.easeOutBack,
          alignment: Alignment.topCenter,
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
          Text(
            '🎉 Correct!',
            style: AppTheme.title(30, color: AppColors.grassGreen),
          ).animate().scale(curve: Curves.elasticOut, duration: 600.ms),
          const SizedBox(height: 8),
          Text(
            'Answer: ${level.answer}',
            style: AppTheme.title(20, color: AppColors.ink),
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 12,
            children: [
              BouncyButton(
                label: 'LEVELS',
                color: AppColors.accent,
                baseColor: AppColors.accentDark,
                height: 56,
                fontSize: 18,
                onTap: () => context.go('/levels'),
              ),
              if (hasNext)
                BouncyButton(
                  label: 'NEXT',
                  icon: Icons.arrow_forward_rounded,
                  color: AppColors.coral,
                  height: 56,
                  fontSize: 18,
                  onTap: () =>
                      context.pushReplacement('/play/${level.level + 1}'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
