import 'package:flutter/material.dart';
import 'package:spare_kart/core/theme/app_colors.dart';

abstract final class AppDecorations {
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 28;

  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: AppColors.textPrimary.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: AppColors.textPrimary.withValues(alpha: 0.02),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get shadowMd => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: AppColors.textPrimary.withValues(alpha: 0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowLg => [
        BoxShadow(
          color: AppColors.primaryDark.withValues(alpha: 0.18),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: AppColors.textPrimary.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowNav => [
        BoxShadow(
          color: AppColors.textPrimary.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, -4),
        ),
      ];

  static BoxDecoration card({Color? color, double radius = radiusMd}) => BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: shadowSm,
      );

  static BoxDecoration elevatedCard({double radius = radiusLg}) => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadowMd,
      );

  static BoxDecoration searchBar() => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: shadowSm,
      );

  static BoxDecoration iconButtonBg({Color? color}) => BoxDecoration(
        color: color ?? AppColors.primaryLight,
        borderRadius: BorderRadius.circular(radiusSm),
      );

  static BoxDecoration gradientHero() => BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(radiusXl),
        boxShadow: shadowLg,
      );

  static BoxDecoration premiumButton() => BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      );

  static BoxDecoration glassSurface() => BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radiusLg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      );
}
