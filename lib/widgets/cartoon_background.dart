import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/theme.dart';

/// A looping, animated cartoon sky: gradient backdrop, a gently pulsing sun,
/// and clouds drifting across the screen. Wrap any screen body with this.
class CartoonBackground extends StatefulWidget {
  final Widget child;
  const CartoonBackground({super.key, required this.child});

  @override
  State<CartoonBackground> createState() => _CartoonBackgroundState();
}

class _CartoonBackgroundState extends State<CartoonBackground>
    with TickerProviderStateMixin {
  late final AnimationController _drift =
      AnimationController(vsync: this, duration: const Duration(seconds: 24))
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.skyTop, AppColors.skyBottom],
        ),
      ),
      child: Stack(
        children: [
          // Pulsing sun, top-right.
          Positioned(
            top: 60,
            right: 30,
            child: AnimatedBuilder(
              animation: _sun,
              builder: (context, child) {
                final s = 1 + _sun.value * 0.08;
                return Transform.scale(
                  scale: s,
                  child: Container(
                    width: 90,
                    height: 90,
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
                );
              },
            ),
          ),
          // Drifting clouds at a few heights/speeds.
          _cloud(top: 120, scale: 1.0, phase: 0.0),
          _cloud(top: 220, scale: 0.7, phase: 0.4),
          _cloud(top: 340, scale: 1.2, phase: 0.75),
          // Rolling green hills at the bottom.
          const Align(
            alignment: Alignment.bottomCenter,
            child: _Hills(),
          ),
          widget.child,
        ],
      ),
    );
  }

  Widget _cloud(
      {required double top, required double scale, required double phase}) {
    return AnimatedBuilder(
      animation: _drift,
      builder: (context, _) {
        final w = MediaQuery.of(context).size.width;
        final t = (_drift.value + phase) % 1.0;
        final x = -160 + t * (w + 320);
        return Positioned(
          top: top + math.sin(t * math.pi * 2) * 6,
          left: x,
          child: Transform.scale(scale: scale, child: const _Cloud()),
        );
      },
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

class _Hills extends StatelessWidget {
  const _Hills();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 140,
      child: CustomPaint(painter: _HillsPainter()),
    );
  }
}

class _HillsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.grassGreen;
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
