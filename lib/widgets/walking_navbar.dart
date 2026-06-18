import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/theme.dart';

/// A transparent bottom navigation that lives *inside* the scene: a little
/// human runs along a road between two wooden roadside signboards (Home /
/// Levels). The road sits on the very bottom of the screen. Tapping a tab
/// makes him run to that board; when he arrives he holds it up in one hand
/// (the active board). The other board stays planted on its post.
class WalkingNavBar extends StatefulWidget {
  final int index; // 0 = Home, 1 = Levels
  final ValueChanged<int> onTap;
  const WalkingNavBar({super.key, required this.index, required this.onTap});

  @override
  State<WalkingNavBar> createState() => _WalkingNavBarState();
}

class _WalkingNavBarState extends State<WalkingNavBar>
    with TickerProviderStateMixin {
  static const double _height = 150;

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

  double _boardCx(double w, int i) => i == 0 ? w * 0.24 : w * 0.76;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return SizedBox(
      height: _height + bottomPad,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          // Road touches the very bottom (covering the system-nav inset).
          final roadY = c.maxHeight - 4;
          return AnimatedBuilder(
            animation: Listenable.merge([_run, _trans]),
            builder: (context, _) {
              final transitioning = _trans.isAnimating;
              final t = _trans.value;
              final p = transitioning ? Curves.easeInOut.transform(t) : 1.0;
              final dir = (_to >= _from) ? 1.0 : -1.0;

              final humanX = transitioning
                  ? _lerp(_boardCx(w, _from), _boardCx(w, _to), p)
                  : _boardCx(w, widget.index);
              final bob = math.sin(_run.value * math.pi * 2 * 2).abs() *
                  (transitioning ? 4 : 2);

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _RoadRunnerPainter(
                        run: _run.value,
                        transitioning: transitioning,
                        humanX: humanX,
                        roadY: roadY,
                        dir: dir,
                        bob: bob,
                      ),
                    ),
                  ),
                  _board(w, 0, 'HOME', Icons.home_rounded, roadY, transitioning,
                      humanX, bob),
                  _board(w, 1, 'LEVELS', Icons.flag_rounded, roadY,
                      transitioning, humanX, bob),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _board(double w, int i, String title, IconData icon, double roadY,
      bool transitioning, double humanX, double bob) {
    final carried = (i == widget.index) && !transitioning;
    const plankW = 96.0;
    const plankH = 38.0;
    const postH = 40.0;

    double left;
    double top;
    if (carried) {
      // Held up in the human's right hand, beside his head.
      final handX = humanX + 20;
      final handY = roadY - bob - 64;
      left = handX - 8; // hand grips the left edge of the plank
      top = handY - plankH + 4 + math.sin(_run.value * math.pi * 2) * 2;
    } else {
      // Planted on a post on the road.
      final cx = _boardCx(w, i);
      left = cx - plankW / 2;
      top = roadY - postH - plankH;
    }

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onTap(i),
        child: Column(
          children: [
            _woodPlank(title, icon, plankW, plankH, carried),
            if (!carried)
              Container(
                width: 9,
                height: postH,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF6B4423), Color(0xFF8A5A2B), Color(0xFF6B4423)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// A chunky wooden plank: layered planks, grain lines, rounded ends.
  Widget _woodPlank(String title, IconData icon, double wdt, double hgt,
      bool active) {
    return Container(
      width: wdt,
      height: hgt,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF5A3617), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            offset: const Offset(0, 3),
            blurRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Base wood gradient.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: active
                        ? const [Color(0xFFC07B3C), Color(0xFF9A5E27)]
                        : const [Color(0xFFCB9A6B), Color(0xFFA87B4E)],
                  ),
                ),
              ),
            ),
            // Wood grain lines.
            Positioned.fill(
              child: CustomPaint(painter: _GrainPainter()),
            ),
            // Plank split line.
            Positioned(
              left: 0,
              right: 0,
              top: hgt / 2 - 1,
              child: Container(
                  height: 1.5, color: const Color(0x556B4423)),
            ),
            // Label.
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 15, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(title,
                      style: AppTheme.title(15, color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;
}

class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = 1;
    for (double y = 6; y < size.height; y += 9) {
      final path = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += 16) {
        path.relativeQuadraticBezierTo(8, 2, 16, 0);
      }
      canvas.drawPath(path, p..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RoadRunnerPainter extends CustomPainter {
  final double run;
  final bool transitioning;
  final double humanX;
  final double roadY;
  final double dir;
  final double bob;

  _RoadRunnerPainter({
    required this.run,
    required this.transitioning,
    required this.humanX,
    required this.roadY,
    required this.dir,
    required this.bob,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawRoad(canvas, size.width);
    _drawHuman(canvas, Offset(humanX, roadY));
  }

  void _drawRoad(Canvas canvas, double w) {
    final road = Paint()
      ..color = const Color(0xFF8A5A2B)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(0, roadY), Offset(w, roadY), road);

    final dash = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const gap = 34.0;
    final shift = run * gap;
    for (double x = -shift; x < w; x += gap) {
      canvas.drawLine(Offset(x, roadY), Offset(x + 14, roadY), dash);
    }
  }

  void _drawHuman(Canvas canvas, Offset feet) {
    final phase = run * math.pi * 2;
    final swing = math.sin(phase) * (transitioning ? 0.9 : 0.2);
    final lean = transitioning ? 0.22 * dir : 0.0;
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
    final armPaint = Paint()
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..color = AppColors.accentDark;

    const hip = Offset(0, -26);
    const shoulder = Offset(0, -46);

    _leg(canvas, hip, swing, legPaint);
    _leg(canvas, hip, -swing, legPaint);
    canvas.drawLine(hip, shoulder, bodyPaint);

    if (transitioning) {
      // Running — arms pump.
      _arm(canvas, shoulder, -swing * 1.2, armPaint);
      _arm(canvas, shoulder, swing * 1.2, armPaint);
    } else {
      // One arm down at side, one arm raised up holding the board.
      _arm(canvas, shoulder, 0.25, armPaint); // resting arm
      _armRaised(canvas, shoulder, armPaint); // holding arm (to the right)
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

  // Right arm reaching up to grip the carried board.
  void _armRaised(Canvas canvas, Offset shoulder, Paint p) {
    final elbow = shoulder + const Offset(10, -8);
    final hand = elbow + const Offset(10, -10);
    canvas.drawLine(shoulder, elbow, p);
    canvas.drawLine(elbow, hand, p);
  }

  Offset _polar(double angle, double len) =>
      Offset(math.sin(angle) * len, math.cos(angle) * len);

  @override
  bool shouldRepaint(covariant _RoadRunnerPainter old) => true;
}
