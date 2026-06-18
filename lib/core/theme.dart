import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Cartoon / animated-movie palette (think bright, warm, playful — Ice Age skies,
/// Tom & Jerry primary pops). Maths app accent = blue.
class AppColors {
  static const accent = Color(0xFF1D6FF2); // playful blue
  static const accentDark = Color(0xFF0B3FA8);
  static const sunYellow = Color(0xFFFFD23F);
  static const grassGreen = Color(0xFF4CC36B);
  static const coral = Color(0xFFFF6B5E);
  static const cream = Color(0xFFFFF7E6);
  static const ink = Color(0xFF243B53);

  // Sky gradient (top -> bottom) used on the animated background.
  static const skyTop = Color(0xFF7EC8FF);
  static const skyBottom = Color(0xFFCDEFFF);

  // Tile states on the levels grid.
  static const solved = grassGreen;
  static const current = sunYellow;
  static const locked = Color(0xFFB9C6D3);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        primary: AppColors.accent,
      ),
      scaffoldBackgroundColor: AppColors.skyBottom,
    );

    return base.copyWith(
      textTheme: GoogleFonts.fredokaTextTheme(base.textTheme).apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: AppColors.ink,
      ),
    );
  }

  /// Chunky cartoon text style helper.
  static TextStyle title(double size, {Color color = AppColors.ink}) =>
      GoogleFonts.fredoka(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.05,
      );
}
