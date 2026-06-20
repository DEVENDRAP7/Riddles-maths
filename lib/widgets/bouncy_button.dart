import 'package:flutter/material.dart';

import '../core/theme.dart';

/// A chunky cartoon button with a 3D "drop shadow" base and a press-down
/// bounce. Used for the big Play button and other primary actions.
class BouncyButton extends StatefulWidget {
  final String label;
  final IconData? icon;

  /// Tap handler. When null the button is shown dimmed and ignores taps.
  final VoidCallback? onTap;
  final Color color;
  final Color baseColor;
  final double height;
  final double fontSize;

  const BouncyButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.color = AppColors.coral,
    this.baseColor = const Color(0xFFC9483D),
    this.height = 68,
    this.fontSize = 24,
  });

  @override
  State<BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<BouncyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.55,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          transform: Matrix4.translationValues(0, _down ? 6 : 0, 0),
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: widget.baseColor,
                offset: Offset(0, _down ? 2 : 8),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  color: Colors.white,
                  size: widget.fontSize + 4,
                ),
                const SizedBox(width: 10),
              ],
              Text(
                widget.label,
                style: AppTheme.title(widget.fontSize, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
