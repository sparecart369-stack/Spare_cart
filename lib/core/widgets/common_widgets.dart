import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:spare_kart/bloc/listings/listings_bloc.dart';
import 'package:spare_kart/core/constants/app_assets.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/theme/app_decorations.dart';
import 'package:spare_kart/core/theme/app_typography.dart';
import 'package:spare_kart/data/models/models.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 80, this.showText = true, this.light = true});

  final double size;
  final bool showText;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          clipBehavior: Clip.antiAlias,
          padding: EdgeInsets.all(size * 0.12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              AppAssets.appLogo,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (showText) ...[
          SizedBox(height: size * 0.18),
          Text(
            'SpareKart',
            style: TextStyle(
              fontFamily: AppTypography.textTheme.displayLarge?.fontFamily,
              fontSize: size * 0.34,
              fontWeight: FontWeight.w800,
              color: light ? Colors.white : AppColors.textPrimary,
              letterSpacing: -0.8,
            ),
          ),
          SizedBox(height: size * 0.04),
          Text(
            'Auto Parts Marketplace',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.textTheme.bodyMedium?.fontFamily,
              fontSize: size * 0.13,
              fontWeight: FontWeight.w500,
              color: light ? Colors.white.withValues(alpha: 0.75) : AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height = 56,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: AppDecorations.premiumButton(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[Icon(icon, size: 20, color: Colors.white), const SizedBox(width: 10)],
                        Text(label, style: AppTypography.textTheme.labelLarge?.copyWith(color: Colors.white)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.light = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: light ? Colors.white : AppColors.primary,
          side: BorderSide(
            color: light ? Colors.white.withValues(alpha: 0.4) : AppColors.border,
            width: 1.5,
          ),
          backgroundColor: light ? Colors.white.withValues(alpha: 0.08) : AppColors.surface,
        ),
        child: Text(
          label,
          style: AppTypography.textTheme.labelLarge?.copyWith(
            color: light ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class ConditionChip extends StatelessWidget {
  const ConditionChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryLight,
            AppColors.primaryLight.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        style: AppTypography.textTheme.labelSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class OutOfStockChip extends StatelessWidget {
  const OutOfStockChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Text(
        'Out of Stock',
        style: AppTypography.textTheme.labelSmall?.copyWith(
          color: AppColors.error,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

enum SellerRatingBadgeStyle { card, detail }

class SellerRatingBadge extends StatelessWidget {
  const SellerRatingBadge({
    super.key,
    required this.part,
    this.style = SellerRatingBadgeStyle.card,
    this.showCount = false,
  });

  final Part part;
  final SellerRatingBadgeStyle style;
  final bool showCount;

  @override
  Widget build(BuildContext context) {
    if (!part.hasSellerRatings) return const SizedBox.shrink();

    final ratingText = part.sellerRating.toStringAsFixed(1);
    final countLabel = showCount
        ? ' (${part.sellerRatingCount} ${part.sellerRatingCount == 1 ? 'rating' : 'ratings'})'
        : '';

    final decoration = switch (style) {
      SellerRatingBadgeStyle.card => BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(10),
          boxShadow: AppDecorations.shadowSm,
        ),
      SellerRatingBadgeStyle.detail => BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(10),
        ),
    };

    final textStyle = switch (style) {
      SellerRatingBadgeStyle.card => AppTypography.textTheme.labelSmall?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      SellerRatingBadgeStyle.detail => AppTypography.textTheme.labelMedium?.copyWith(
          color: AppColors.warning,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: decoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: style == SellerRatingBadgeStyle.card ? 14 : 16,
            color: AppColors.accent,
          ),
          const SizedBox(width: 3),
          Text('$ratingText$countLabel', style: textStyle),
        ],
      ),
    );
  }
}

class LocationChip extends StatelessWidget {
  const LocationChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: AppTypography.textTheme.labelSmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class ActiveFilterChips extends StatelessWidget {
  const ActiveFilterChips({
    super.key,
    required this.chips,
    required this.onClear,
  });

  final List<ActiveFilterChip> chips;
  final void Function(FilterChipField field, {String? value}) onClear;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final chip = chips[i];
          return _RemovableFilterChip(
            label: chip.label,
            onClear: () => onClear(chip.field, value: chip.value),
          );
        },
      ),
    );
  }
}

class _RemovableFilterChip extends StatelessWidget {
  const _RemovableFilterChip({
    required this.label,
    required this.onClear,
  });

  final String label;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: BoxDecoration(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onClear,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.onActionTap,
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onActionTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 4 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.textTheme.titleLarge),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppTypography.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onActionTap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(action!, style: AppTypography.textTheme.labelMedium?.copyWith(color: AppColors.primary)),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primary),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                boxShadow: AppDecorations.shadowSm,
              ),
              child: Icon(icon, size: 48, color: AppColors.primary.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 24),
            Text(title, style: AppTypography.textTheme.titleLarge, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(subtitle!, textAlign: TextAlign.center, style: AppTypography.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}

class PremiumIconButton extends StatelessWidget {
  const PremiumIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.badge,
    this.color,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? badge;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
            child: Container(
              width: 44,
              height: 44,
              decoration: AppDecorations.iconButtonBg(color: color ?? AppColors.surface),
              child: Icon(icon, size: 22, color: AppColors.textPrimary),
            ),
          ),
        ),
        if (badge != null)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.surface, width: 2),
              ),
              child: Text(
                badge!,
                style: AppTypography.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class PremiumSearchBar extends StatelessWidget {
  const PremiumSearchBar({
    super.key,
    this.hint = 'Search by name, chassis, part no...',
    this.onTap,
  });

  final String hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hint,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.search_rounded, color: AppColors.textSecondary.withValues(alpha: 0.85), size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pull-to-refresh control for listing feeds. Uses a sliver so the loader
/// is not clipped behind headers (unlike wrapping [CustomScrollView] in
/// [RefreshIndicator]).
class ListingsRefreshControl extends StatelessWidget {
  const ListingsRefreshControl({super.key, required this.bloc});

  final ListingsBloc bloc;

  @override
  Widget build(BuildContext context) {
    return CupertinoSliverRefreshControl(
      onRefresh: () => refreshListings(bloc),
    );
  }
}

/// Thin progress bar shown at the top of listing feeds while data loads.
class ListingsTopLoader extends StatelessWidget {
  const ListingsTopLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const LinearProgressIndicator(
      minHeight: 3,
      backgroundColor: AppColors.border,
      color: AppColors.primary,
    );
  }
}

class BlurredPrice extends StatelessWidget {
  const BlurredPrice({super.key, this.style, this.placeholder = '₹12,999'});

  final TextStyle? style;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    final textStyle = style ?? AppTypography.price;
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Text(
        placeholder,
        style: textStyle.copyWith(
          color: textStyle.color?.withValues(alpha: 0.55) ?? AppColors.textPrimary.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}
