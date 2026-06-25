import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF1B4DDB);
  static const Color primaryDark = Color(0xFF0F2B6E);
  static const Color primaryMid = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFFEEF2FF);
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentSoft = Color(0xFFFFF7ED);

  // Surfaces
  static const Color background = Color(0xFFF4F6FB);
  static const Color backgroundAlt = Color(0xFFE8EDF7);
  static const Color surface = Colors.white;
  static const Color surfaceElevated = Color(0xFFFAFBFE);
  static const Color surfaceDark = Color(0xFF0D1B3E);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnPrimary = Colors.white;

  // UI
  static const Color divider = Color(0xFFE2E8F0);
  static const Color border = Color(0xFFE8EDF5);
  static const Color chipBg = Color(0xFFF1F5F9);
  static const Color overlay = Color(0x660F172A);

  // Status
  static const Color success = Color(0xFF059669);
  static const Color successSoft = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFDC2626);
  static const Color errorSoft = Color(0xFFFEF2F2);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF1B4DDB), Color(0xFF0F2B6E)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF141414), Color(0xFF000000), Color(0xFF050505)],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0F2B6E), Color(0xFF0A1628)],
  );

  static const LinearGradient cardShine = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white, Color(0xFFF8FAFC)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
  );
}
