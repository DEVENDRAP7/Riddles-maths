import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/theme.dart';

/// A bottom navigation bar with a procedurally-animated little human who walks
/// in place on a scrolling road. Tapping the other tab tilts the road toward
/// it; the human slides down the slope, tumbles (falls), then stands back up
/// and keeps walking — all within the fixed navbar height.
class WalkingNavBar extends StatefulWidget {
  final int index; // 0 = Home, 1 = Levels
  final ValueChanged<int> onTap;
  const WalkingNavBar({super.key, required this.index, required this.onTap});

  @override
  State<WalkingNavBar> createState() => _WalkingNavBarState();
}

class _WalkingNavBarState extends State<WalkingNavBar>
    with TickerProviderStateMixin {
  static const double _height = 96;

  // Continuous walk cycle + road scroll.
  late final AnimationController _walk =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 850))
        ..repeat();

  // One-shot transition played whenever the active tab changes.
  late final AnimationController _trans =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1150));

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
    _walk.dispose();
    _trans.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: _height + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.accent, width: 2.5)),
        boxShadow: [
          BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, -2)),
        ],
      ),
      child: AnimatedBuilder(
        animation: Listenable.merge([_walk, _trans]),
        builder: (context, _) {
          return Stack(
            children: [
              // The road + human, painted procedurally.
              Positioned.fill(
                child: CustomPaint(
                  painter: _RoadHumanPainter(
                    walk: _walk.value,
                    trans: _trans.isAnimating ? _trans.value : (_to == widget.index ? 0 : 0),
                    transitioning: _trans.isAnimating,
                    from: _from,
                    to: _to,
                    activeIndex: widget.index,
                  ),
                ),
              ),
              // Tab tap targets + labels.
              Row(
                children: [
                  _tab(0, Icons.home_rounded, 'Home'),
                  _tab(1, Icons.grid_view_rounded, 'Levels'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tab(int i, IconData icon, String label) {
    final active = widget.index == i;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onTap(i),
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(icon,
                  size: 22,
                  color: active ? AppColors.accent : AppColors.locked),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTheme.title(12,
                    color: active ? AppColors.accent : AppColors.locked),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoadHumanPainter extends CustomPainter {
  final double walk; // 0..1 loop
  final double trans; // 0..1 during a tab switch
  final bool transitioning;
  final int from;
  final int to;
  final int activeIndex;

  _RoadHumanPainter({
    required this.walk,
    required this.trans,
    required this.transitioning,
    required this.from,
    required this.to,
    required this.activeIndex,
  });

  double _tabCx(double w, int i) => i == 0 ? w * 0.28 : w * 0.72;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final roadY = h * 0.74;

    final dir = (to >= from) ? 1.0 : -1.0;
    // Eased horizontal progress between the two tab spots.
    final p = transitioning ? Curves.easeInOut.transform(trans) : 1.0;
    // Fall envelope: 0 at the ends, 1 in the middle of the transition.
    final fall = transitioning ? math.sin(trans * math.pi) : 0.0;

    final hx = transitioning
        ? _lerp(_tabCx(w, from), _tabCx(w, to), p)
        : _tabCx(w, activeIndex);

    final groundTilt = fall * 0.16 * dir; // road tips toward target
    final bodyTilt = fall * 1.25 * dir; // human tumbles
    final drop = fall * 9.0; // dips on the slope
    final walkAmt = transitioning ? (1 - fall) : 1.0; // stop limbs mid-fall
    final facing = transitioning ? dir : 1.0;

    _drawRoad(canvas, w, roadY, groundTilt);
    _drawHuman(canvas, Offset(hx, roadY + drop), bodyTilt, walkAmt, facing);
  }

  void _drawRoad(Canvas canvas, double w, double roadY, double tilt) {
    canvas.save();
    canvas.translate(w / 2, roadY);
    canvas.rotate(tilt);
    canvas.translate(-w / 2, -roadY);

    final road = Paint()
      ..color = const Color(0xFFB9863F)
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(8, roadY), Offset(w - 8, roadY), road);

    // Scrolling dashes for forward motion.
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const gap = 34.0;
    final shift = (walk * gap);
    for (double x = 8 - shift; x < w - 8; x += gap) {
      canvas.drawLine(Offset(x, roadY), Offset(x + 14, roadY), dash);
    }
    canvas.restore();
  }

  void _drawHuman(
      Canvas canvas, Offset feet, double tilt, double walkAmt, double facing) {
    final phase = walk * math.pi * 2;
    final swing = math.sin(phase) * 0.5 * walkAmt; // leg/arm swing
    final bob = (math.sin(phase * 2).abs()) * 2.5 * walkAmt;

    canvas.save();
    canvas.translate(feet.dx, feet.dy - bob);
    canvas.rotate(tilt);
    canvas.scale(facing, 1);

    final limb = Paint()
      ..color = AppColors.accentDark
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final body = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    const hip = Offset(0, -26);
    const shoulder = Offset(0, -46);

    // Legs (swing opposite).
    _leg(canvas, hip, swing, limb);
    _leg(canvas, hip, -swing, limb..color = AppColors.accent);
    limb.color = AppColors.accentDark;

    // Body.
    canvas.drawLine(hip, shoulder, body);

    // Arms (opposite to legs).
    _arm(canvas, shoulder, -swing, limb);
    _arm(canvas, shoulder, swing, limb);

    // Head.
    final headPaint = Paint()..color = AppColors.sunYellow;
    final headEdge = Paint()
      ..color = AppColors.accentDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    const head = Offset(0, -54);
    canvas.drawCircle(head, 9, headPaint);
    canvas.drawCircle(head, 9, headEdge);
    // little face dot (faces forward)
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

  // Angle measured from straight-down, swinging forward/back.
  Offset _polar(double angle, double len) =>
      Offset(math.sin(angle) * len, math.cos(angle) * len);

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(covariant _RoadHumanPainter old) => true;
}
