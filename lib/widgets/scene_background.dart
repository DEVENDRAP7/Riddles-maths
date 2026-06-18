import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/theme.dart';

/// A persistent, two-frame cartoon scene that pans horizontally as the player
/// switches tabs. Frame 0 (left) = Home (sunny morning). Frame 1 (right) =
/// Levels (warmer afternoon). [pan] runs 0..1 and slides the camera between
/// them, so the human in the navbar feels like he walks into a new place.
class SceneBackground extends StatefulWidget {
  /// 0.0 = Home frame fully shown, 1.0 = Levels frame fully shown.
  final double pan;
  const SceneBackground({super.key, required this.pan});

  @override
  State<SceneBackground> createState() => _SceneBackgroundState();
}

class _SceneBackgroundState extends State<SceneBackground>
    with TickerProviderStateMixin {
  late final AnimationController _drift =
      AnimationController(vsync: this, duration: const Duration(seconds: 28))
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
                child: SizedBox(
                  width: w * 2,
                  height: c.maxHeight,
                  child: Row(
                    children: [
                      _Frame(
                        width: w,
                        skyTop: const Color(0xFF7EC8FF),
                        skyBottom: const Color(0xFFCDEFFF),
                        hill: AppColors.grassGreen,
                        drift: _drift.value,
                        sun: _sun.value,
                        sunLeft: false,
                      ),
                      _Frame(
                        width: w,
                        skyTop: const Color(0xFFFFC36B),
                        skyBottom: const Color(0xFFFFE9C2),
                        hill: const Color(0xFF3FA85C),
                        drift: (_drift.value + 0.5) % 1.0,
                        sun: _sun.value,
                        sunLeft: true,
                      ),
                    ],
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

class _Frame extends StatelessWidget {
  final double width;
  final Color skyTop;
  final Color skyBottom;
  final Color hill;
  final double drift;
  final double sun;
  final bool sunLeft;

  const _Frame({
    required this.width,
    required this.skyTop,
    required this.skyBottom,
    required this.hill,
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
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [skyTop, skyBottom],
                ),
              ),
            ),
          ),
          Positioned(
            top: 64,
            left: sunLeft ? 28 : null,
            right: sunLeft ? null : 28,
            child: Transform.scale(
              scale: 1 + sun * 0.08,
              child: Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.sunYellow,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.sunYellow.withValues(alpha: 0.6),
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
          _cloud(width, top: 120, scale: 1.0, phase: 0.0),
          _cloud(width, top: 220, scale: 0.7, phase: 0.45),
          _cloud(width, top: 330, scale: 1.2, phase: 0.8),
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: double.infinity,
              height: 150,
              child: CustomPaint(painter: _HillsPainter(hill)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cloud(double w, {required double top, required double scale, required double phase}) {
    final t = (drift + phase) % 1.0;
    final x = -160 + t * (w + 320);
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
          _puff(0, 20, 60),
          _puff(40, 0, 70),
          _puff(85, 18, 64),
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

class _HillsPainter extends CustomPainter {
  final Color color;
  _HillsPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.1,
          size.width * 0.5, size.height * 0.45)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.85,
          size.width, size.height * 0.35)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HillsPainter old) => old.color != color;
}
