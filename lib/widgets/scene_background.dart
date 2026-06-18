import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A persistent, two-frame cartoon landscape that pans horizontally as the
/// player switches tabs. Frame 0 (left) = Home (fresh blue morning).
/// Frame 1 (right) = Levels (warm golden afternoon). Everything is hand-painted
/// (layered parallax mountains, hills, pine trees) — no external assets.
class SceneBackground extends StatefulWidget {
  /// 0.0 = Home frame shown, 1.0 = Levels frame shown.
  final double pan;
  const SceneBackground({super.key, required this.pan});

  @override
  State<SceneBackground> createState() => _SceneBackgroundState();
}

class _SceneBackgroundState extends State<SceneBackground>
    with TickerProviderStateMixin {
  late final AnimationController _drift =
      AnimationController(vsync: this, duration: const Duration(seconds: 30))
        ..repeat();
  late final AnimationController _sun =
      AnimationController(vsync: this, duration: const Duration(seconds: 4))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _drift.dispose();
    _sun.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        return ClipRect(
          child: AnimatedBuilder(
            animation: Listenable.merge([_drift, _sun]),
            builder: (context, _) {
              return Transform.translate(
                offset: Offset(-widget.pan * w, 0),
                child: OverflowBox(
                  minWidth: 0,
                  maxWidth: w * 2,
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: w * 2,
                    height: c.maxHeight,
                    child: Row(
                      children: [
                        _Frame(
                          width: w,
                          palette: _Palette.morning,
                          drift: _drift.value,
                          sun: _sun.value,
                          sunLeft: false,
                        ),
                        _Frame(
                          width: w,
                          palette: _Palette.afternoon,
                          drift: (_drift.value + 0.5) % 1.0,
                          sun: _sun.value,
                          sunLeft: true,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _Palette {
  final Color skyTop, skyBottom, sun, sunGlow;
  final Color farMtn, farSnow, midHill, nearHill, tree, treeDark;
  const _Palette({
    required this.skyTop,
    required this.skyBottom,
    required this.sun,
    required this.sunGlow,
    required this.farMtn,
    required this.farSnow,
    required this.midHill,
    required this.nearHill,
    required this.tree,
    required this.treeDark,
  });

  static const morning = _Palette(
    skyTop: Color(0xFF6FB7FF),
    skyBottom: Color(0xFFCDEFFF),
    sun: Color(0xFFFFE066),
    sunGlow: Color(0xFFFFF3B0),
    farMtn: Color(0xFF9BB7D4),
    farSnow: Color(0xFFEAF4FF),
    midHill: Color(0xFF6FBF7A),
    nearHill: Color(0xFF4CA35E),
    tree: Color(0xFF2E8B57),
    treeDark: Color(0xFF1F6B40),
  );

  static const afternoon = _Palette(
    skyTop: Color(0xFFFFB25A),
    skyBottom: Color(0xFFFFE7B8),
    sun: Color(0xFFFF8C42),
    sunGlow: Color(0xFFFFD08A),
    farMtn: Color(0xFFC9A38C),
    farSnow: Color(0xFFFFF1E2),
    midHill: Color(0xFF8FB867),
    nearHill: Color(0xFF6E9E47),
    tree: Color(0xFF4F8F3C),
    treeDark: Color(0xFF3A6E2A),
  );
}

class _Frame extends StatelessWidget {
  final double width;
  final _Palette palette;
  final double drift;
  final double sun;
  final bool sunLeft;

  const _Frame({
    required this.width,
    required this.palette,
    required this.drift,
    required this.sun,
    required this.sunLeft,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Stack(
        children: [
          // Sky.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [palette.skyTop, palette.skyBottom],
                ),
              ),
            ),
          ),
          // Sun with soft glow.
          Positioned(
            top: 70,
            left: sunLeft ? 30 : null,
            right: sunLeft ? null : 30,
            child: Transform.scale(
              scale: 1 + sun * 0.08,
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.sun,
                  boxShadow: [
                    BoxShadow(
                      color: palette.sunGlow.withValues(alpha: 0.7),
                      blurRadius: 46,
                      spreadRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Layered landscape (mountains, hills, trees).
          Positioned.fill(
            child: CustomPaint(painter: _LandscapePainter(palette)),
          ),
          // Drifting clouds.
          _cloud(width, top: 110, scale: 1.0, phase: 0.0),
          _cloud(width, top: 180, scale: 0.65, phase: 0.4),
          _cloud(width, top: 300, scale: 1.25, phase: 0.78),
        ],
      ),
    );
  }

  Widget _cloud(double w,
      {required double top, required double scale, required double phase}) {
    final t = (drift + phase) % 1.0;
    final x = -170 + t * (w + 340);
    return Positioned(
      top: top + math.sin(t * math.pi * 2) * 6,
      left: x,
      child: Transform.scale(scale: scale, child: const _Cloud()),
    );
  }
}

class _Cloud extends StatelessWidget {
  const _Cloud();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      height: 60,
      child: Stack(
        children: [
          _puff(0, 20, 58),
          _puff(38, 0, 70),
          _puff(84, 18, 62),
        ],
      ),
    );
  }

  Widget _puff(double left, double top, double size) => Positioned(
        left: left,
        top: top,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            shape: BoxShape.circle,
          ),
        ),
      );
}

class _LandscapePainter extends CustomPainter {
  final _Palette p;
  _LandscapePainter(this.p);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizon = h * 0.55;

    _farMountains(canvas, w, h, horizon);
    _hill(canvas, w, h, h * 0.70, p.midHill); // mid layer
    _hill(canvas, w, h, h * 0.82, p.nearHill); // near layer
    _trees(canvas, w, h);
  }

  void _farMountains(Canvas canvas, double w, double h, double base) {
    final mtn = Paint()..color = p.farMtn;
    final snow = Paint()..color = p.farSnow;
    final peaks = [0.1, 0.34, 0.62, 0.88];
    for (final px in peaks) {
      final cx = px * w;
      final peakY = base - h * (0.16 + (px * 13 % 1) * 0.06);
      final half = w * 0.16;
      final path = Path()
        ..moveTo(cx - half, base)
        ..lineTo(cx, peakY)
        ..lineTo(cx + half, base)
        ..close();
      canvas.drawPath(path, mtn);
      // snow cap
      final capY = peakY + (base - peakY) * 0.28;
      final capHalf = half * 0.28;
      final cap = Path()
        ..moveTo(cx - capHalf, capY)
        ..lineTo(cx, peakY)
        ..lineTo(cx + capHalf, capY)
        ..quadraticBezierTo(cx, capY + 6, cx - capHalf, capY)
        ..close();
      canvas.drawPath(cap, snow);
    }
  }

  void _hill(Canvas canvas, double w, double h, double top, Color color) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, h)
      ..lineTo(0, top)
      ..quadraticBezierTo(w * 0.2, top - h * 0.08, w * 0.42, top)
      ..quadraticBezierTo(w * 0.65, top + h * 0.07, w * 0.82, top - h * 0.03)
      ..quadraticBezierTo(w * 0.93, top - h * 0.06, w, top)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(path, paint);
  }

  void _trees(Canvas canvas, double w, double h) {
    final baseY = h * 0.86;
    final spots = [0.12, 0.24, 0.5, 0.68, 0.86, 0.94];
    for (var i = 0; i < spots.length; i++) {
      final x = spots[i] * w;
      final scale = 0.8 + (i % 3) * 0.22;
      _pine(canvas, Offset(x, baseY + (i.isEven ? 6 : 0)), scale);
    }
  }

  void _pine(Canvas canvas, Offset base, double scale) {
    final trunk = Paint()..color = const Color(0xFF6B4423);
    final leaf = Paint()..color = p.tree;
    final leafDark = Paint()..color = p.treeDark;
    final hgt = 34.0 * scale;
    final wdt = 20.0 * scale;

    // trunk
    canvas.drawRect(
      Rect.fromCenter(
          center: base.translate(0, -hgt * 0.12),
          width: 4 * scale,
          height: hgt * 0.3),
      trunk,
    );
    // three stacked triangles
    for (var i = 0; i < 3; i++) {
      final t = i / 3;
      final tierTop = base.dy - hgt + hgt * t * 0.9;
      final tierHalf = wdt * (0.55 + t * 0.5) / 2;
      final tierBottom = tierTop + hgt * 0.42;
      final path = Path()
        ..moveTo(base.dx, tierTop)
        ..lineTo(base.dx - tierHalf, tierBottom)
        ..lineTo(base.dx + tierHalf, tierBottom)
        ..close();
      canvas.drawPath(path, i == 2 ? leaf : leafDark);
    }
  }

  @override
  bool shouldRepaint(covariant _LandscapePainter old) => old.p != p;
}
