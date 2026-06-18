import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/theme.dart';

/// A transparent bottom navigation that lives *inside* the scene: a little
/// human runs along a road between two wooden roadside signboards (Home /
/// Levels). Tapping a tab makes him run to that board and lift it onto his
/// hands (carry pose). The active board is the one he is holding.
class WalkingNavBar extends StatefulWidget {
  final int index; // 0 = Home, 1 = Levels
  final ValueChanged<int> onTap;
  const WalkingNavBar({super.key, required this.index, required this.onTap});

  @override
  State<WalkingNavBar> createState() => _WalkingNavBarState();
}

class _WalkingNavBarState extends State<WalkingNavBar>
    with TickerProviderStateMixin {
  static const double _height = 132;

  late final AnimationController _run =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
        ..repeat();
  late final AnimationController _trans =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1050));

  int _from = 0;
  int _to = 0;

  @override
  void initState() {
    super.initState();
    _from = _to = widget.index;
  }

  @override
  void didUpdateWidget(covariant WalkingNavBar old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) {
      _from = old.index;
      _to = widget.index;
      _trans.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _run.dispose();
    _trans.dispose();
    super.dispose();
  }

  double _boardCx(double w, int i) => i == 0 ? w * 0.22 : w * 0.78;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return SizedBox(
      height: _height + bottomPad,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          return AnimatedBuilder(
            animation: Listenable.merge([_run, _trans]),
            builder: (context, _) {
              final transitioning = _trans.isAnimating;
              final t = _trans.value;
              final p = transitioning ? Curves.easeInOut.transform(t) : 1.0;
              final dir = (_to >= _from) ? 1.0 : -1.0;
              final roadY = _height * 0.80;

              final humanX = transitioning
                  ? _lerp(_boardCx(w, _from), _boardCx(w, _to), p)
                  : _boardCx(w, widget.index);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Road + human (painted).
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RoadRunnerPainter(
                        run: _run.value,
                        transitioning: transitioning,
                        humanX: humanX,
                        roadY: roadY,
                        dir: dir,
                      ),
                    ),
                  ),
                  // Two signboards.
                  _board(w, 0, 'HOME', '0 km', Icons.home_rounded, roadY,
                      transitioning, p, humanX),
                  _board(w, 1, 'LEVELS', '100 km', Icons.flag_rounded, roadY,
                      transitioning, p, humanX),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _board(double w, int i, String title, String sub, IconData icon,
      double roadY, bool transitioning, double p, double humanX) {
    final cx = _boardCx(w, i);
    final active = widget.index == i;

    // How "lifted" (carried) the board is: high when the human is at it.
    double lift;
    if (!transitioning) {
      lift = active ? 10 + math.sin(_run.value * math.pi * 2) * 3 : 0;
    } else {
      final nearTo = i == _to ? (p > 0.65 ? (p - 0.65) / 0.35 : 0.0) : 0.0;
      final leaveFrom = i == _from ? (1 - p).clamp(0.0, 1.0) : 0.0;
      lift = (i == _to)
          ? nearTo * 12
          : (i == _from ? leaveFrom * 8 : 0);
    }

    const postH = 34.0;
    const plankH = 40.0;
    const plankW = 104.0;
    final baseY = roadY; // post bottom sits on the road
    final top = baseY - postH - plankH - lift;

    return Positioned(
      left: cx - plankW / 2,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onTap(i),
        child: Column(
          children: [
            _plank(title, sub, icon, plankW, plankH, active),
            // Post.
            Container(
              width: 8,
              height: postH,
              decoration: BoxDecoration(
                color: const Color(0xFF7A5230),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _plank(String title, String sub, IconData icon, double wdt, double hgt,
      bool active) {
    return Container(
      width: wdt,
      height: hgt,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: active
              ? const [Color(0xFFB9763C), Color(0xFF935A28)]
              : const [Color(0xFFC9966A), Color(0xFFA9794E)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF6B4423), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(0, 3),
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 5),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTheme.title(14, color: Colors.white)),
              Text(sub,
                  style: AppTheme.title(9,
                      color: Colors.white.withValues(alpha: 0.85))),
            ],
          ),
        ],
      ),
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}

class _RoadRunnerPainter extends CustomPainter {
  final double run;
  final bool transitioning;
  final double humanX;
  final double roadY;
  final double dir;

  _RoadRunnerPainter({
    required this.run,
    required this.transitioning,
    required this.humanX,
    required this.roadY,
    required this.dir,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    _drawRoad(canvas, w);
    _drawHuman(canvas, Offset(humanX, roadY));
  }

  void _drawRoad(Canvas canvas, double w) {
    final road = Paint()
      ..color = const Color(0xFF8A5A2B)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(6, roadY), Offset(w - 6, roadY), road);

    final dash = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const gap = 34.0;
    final shift = run * gap;
    for (double x = 6 - shift; x < w - 6; x += gap) {
      canvas.drawLine(Offset(x, roadY), Offset(x + 14, roadY), dash);
    }
  }

  void _drawHuman(Canvas canvas, Offset feet) {
    final phase = run * math.pi * 2;
    // Running: bigger, faster swing. Carrying (idle): gentle.
    final swing = math.sin(phase) * (transitioning ? 0.9 : 0.25);
    final bob = math.sin(phase * 2).abs() * (transitioning ? 4 : 2);
    final lean = transitioning ? 0.25 * dir : 0.0; // forward lean while running
    final facing = transitioning ? dir : 1.0;

    canvas.save();
    canvas.translate(feet.dx, feet.dy - bob);
    canvas.rotate(lean);
    canvas.scale(facing, 1);

    final legPaint = Paint()
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..color = AppColors.accentDark;
    final bodyPaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    const hip = Offset(0, -26);
    const shoulder = Offset(0, -46);

    _leg(canvas, hip, swing, legPaint);
    _leg(canvas, hip, -swing, legPaint);
    canvas.drawLine(hip, shoulder, bodyPaint);

    final armPaint = Paint()
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..color = AppColors.accentDark;

    if (transitioning) {
      // Arms pump while running.
      _arm(canvas, shoulder, -swing * 1.2, armPaint);
      _arm(canvas, shoulder, swing * 1.2, armPaint);
    } else {
      // Carry pose: both arms raised up, holding the board overhead.
      _armRaised(canvas, shoulder, -0.5, armPaint);
      _armRaised(canvas, shoulder, 0.5, armPaint);
    }

    // Head.
    const head = Offset(0, -54);
    canvas.drawCircle(head, 9, Paint()..color = AppColors.sunYellow);
    canvas.drawCircle(
        head,
        9,
        Paint()
          ..color = AppColors.accentDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    canvas.drawCircle(const Offset(4, -55), 1.6, Paint()..color = AppColors.ink);

    canvas.restore();
  }

  void _leg(Canvas canvas, Offset hip, double angle, Paint p) {
    final knee = hip + _polar(angle, 13);
    final foot = knee + _polar(angle * 0.6, 13);
    canvas.drawLine(hip, knee, p);
    canvas.drawLine(knee, foot, p);
  }

  void _arm(Canvas canvas, Offset shoulder, double angle, Paint p) {
    final hand = shoulder + _polar(angle, 16);
    canvas.drawLine(shoulder, hand, p);
  }

  // Arm reaching up (for carrying the board).
  void _armRaised(Canvas canvas, Offset shoulder, double spread, Paint p) {
    final elbow = shoulder + Offset(spread * 8, -10);
    final hand = elbow + Offset(spread * 4, -12);
    canvas.drawLine(shoulder, elbow, p);
    canvas.drawLine(elbow, hand, p);
  }

  Offset _polar(double angle, double len) =>
      Offset(math.sin(angle) * len, math.cos(angle) * len);

  @override
  bool shouldRepaint(covariant _RoadRunnerPainter old) => true;
}
