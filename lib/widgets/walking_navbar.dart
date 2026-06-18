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

              final humanX = transitioning
                  ? _lerp(_boardCx(w, _from), _boardCx(w, _to), p)
                  : _boardCx(w, widget.index);
              final bob = math.sin(_run.value * math.pi * 2 * 2).abs() *
                  (transitioning ? 3 : 1.5);
              // Face direction never changes — he always faces the same way,
              // carrying the board on his head.
              const facing = 1.0;

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
                        facing: facing,
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
    const plankW = 104.0;
    const plankH = 34.0;
    const postH = 42.0;

    if (carried) {
      // Balanced flat on top of his head, centred over the body. The head top
      // sits at roughly roadY - bob - 90 (head centre -77, radius ~14).
      final headTopY = roadY - bob - 90;
      final wob = math.sin(_run.value * math.pi * 2) * 1.5;
      return Positioned(
        left: humanX - plankW / 2,
        top: headTopY - plankH + 2 + wob,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onTap(i),
          child: _woodPlank(title, icon, plankW, plankH, true, gripLeft: true),
        ),
      );
    }

    // Planted on a post on the road.
    final cx = _boardCx(w, i);
    return Positioned(
      left: cx - plankW / 2,
      top: roadY - postH - plankH,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onTap(i),
        child: Column(
          children: [
            _woodPlank(title, icon, plankW, plankH, false),
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
      bool active, {bool gripLeft = true}) {
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
            // Grip / handle on the near end (the hand side).
            Positioned(
              left: gripLeft ? 4 : null,
              right: gripLeft ? null : 4,
              top: hgt / 2 - 7,
              child: Container(
                width: 10,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFF5A3617),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            // Label.
            Padding(
              padding: EdgeInsets.only(
                  left: gripLeft ? 14 : 0, right: gripLeft ? 0 : 14),
              child: Center(
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
  final double facing;
  final double bob;

  _RoadRunnerPainter({
    required this.run,
    required this.transitioning,
    required this.humanX,
    required this.roadY,
    required this.facing,
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
    // He is ALWAYS walking — even while carrying the board. Legs swing a bit
    // wider while running between boards.
    final amp = transitioning ? 0.55 : 0.42;
    final swing = math.sin(phase) * amp;
    final lean = transitioning ? 0.16 * facing : 0.04 * facing;
    const s = 1.4; // overall scale — bigger, clearer figure

    canvas.save();
    canvas.translate(feet.dx, feet.dy - bob);
    canvas.rotate(lean);
    canvas.scale(facing * s, s);

    final limb = Paint()
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..color = AppColors.accentDark;
    final shoe = Paint()..color = AppColors.ink;

    const hip = Offset(0, -22);
    const shoulder = Offset(0, -44);
    const head = Offset(0, -55);

    // --- Legs (always walking) ---
    _leg(canvas, hip, swing, limb, shoe);
    _leg(canvas, hip, -swing, limb, shoe);

    // --- Body capsule ---
    final bodyRect = RRect.fromLTRBR(
        -5, shoulder.dy, 5, hip.dy + 2, const Radius.circular(5));
    canvas.drawRRect(bodyRect, Paint()..color = AppColors.accent);

    // --- Arms ---
    if (transitioning) {
      // Running — both arms pump.
      _arm(canvas, shoulder, -swing * 1.2 - 0.2, limb);
      _arm(canvas, shoulder, swing * 1.2 + 0.2, limb);
    } else {
      // Both arms raised overhead, steadying the board balanced on his head.
      _armUp(canvas, shoulder, -1, limb);
      _armUp(canvas, shoulder, 1, limb);
    }

    // --- Neck + head with a little face ---
    canvas.drawLine(shoulder, head + const Offset(0, 7), limb..strokeWidth = 5);
    canvas.drawCircle(head, 10, Paint()..color = AppColors.sunYellow);
    canvas.drawCircle(
        head,
        10,
        Paint()
          ..color = AppColors.accentDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    // eyes + smile (faces forward, +x)
    final face = Paint()..color = AppColors.ink;
    canvas.drawCircle(head + const Offset(3, -2), 1.5, face);
    canvas.drawCircle(head + const Offset(7, -2), 1.5, face);
    final smile = Path()
      ..moveTo(head.dx + 2, head.dy + 3)
      ..quadraticBezierTo(head.dx + 5, head.dy + 6, head.dx + 8, head.dy + 3);
    canvas.drawPath(
        smile,
        Paint()
          ..color = AppColors.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round);

    canvas.restore();
  }

  void _leg(Canvas canvas, Offset hip, double angle, Paint p, Paint shoe) {
    // Angle measured from straight-down; cos keeps the leg pointing DOWN.
    final knee = hip + _polar(angle, 12);
    final foot = knee + _polar(angle * 0.5, 12);
    canvas.drawLine(hip, knee, p);
    canvas.drawLine(knee, foot, p);
    // little shoe
    canvas.drawOval(
        Rect.fromCenter(
            center: foot + const Offset(2, 1), width: 10, height: 5),
        shoe);
  }

  void _arm(Canvas canvas, Offset shoulder, double angle, Paint p) {
    final hand = shoulder + _polar(angle, 16);
    canvas.drawLine(shoulder, hand, p);
  }

  // Arm raised overhead (side = -1 left, +1 right) to steady the head-board.
  void _armUp(Canvas canvas, Offset shoulder, int side, Paint p) {
    final elbow = shoulder + Offset(side * 7.0, -10);
    final hand = elbow + Offset(side * 3.0, -12); // hand up near the board
    canvas.drawLine(shoulder, elbow, p);
    canvas.drawLine(elbow, hand, p);
  }

  Offset _polar(double angle, double len) =>
      Offset(math.sin(angle) * len, math.cos(angle) * len);

  @override
  bool shouldRepaint(covariant _RoadRunnerPainter old) => true;
}
