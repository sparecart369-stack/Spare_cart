import 'package:flutter/material.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/theme/app_decorations.dart';
import 'package:spare_kart/core/theme/app_typography.dart';
import 'package:spare_kart/core/widgets/common_widgets.dart';
import 'package:spare_kart/core/widgets/listing_image.dart';
import 'package:spare_kart/data/models/models.dart';

class PartCard extends StatelessWidget {
  const PartCard({super.key, required this.part, this.onTap, this.compact = false});

  final Part part;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
          child: Ink(
            decoration: AppDecorations.card(),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _PartImage(url: part.imageUrl, size: 80, radius: AppDecorations.radiusSm),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        part.fullTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      ConditionChip(label: part.conditionLabel),
                      const SizedBox(height: 8),
                      const BlurredPrice(),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 13, color: AppColors.textTertiary.withValues(alpha: 0.8)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              part.displayLocation,
                              style: AppTypography.textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDecorations.radiusLg),
        child: Ink(
          decoration: AppDecorations.elevatedCard(radius: AppDecorations.radiusLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDecorations.radiusLg)),
                    child: _PartImage(url: part.imageUrl, size: double.infinity, height: 148),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: ConditionChip(label: part.conditionLabel),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: AppDecorations.shadowSm,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: AppColors.accent),
                          const SizedBox(width: 3),
                          Text(
                            part.sellerRating.toStringAsFixed(1),
                            style: AppTypography.textTheme.labelSmall?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      part.fullTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.textTheme.titleSmall?.copyWith(height: 1.35),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const BlurredPrice(),
                        const Spacer(),
                        Icon(Icons.location_on_rounded, size: 13, color: AppColors.textTertiary),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            part.displayLocation.split(',').first,
                            style: AppTypography.textTheme.labelSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartImage extends StatelessWidget {
  const _PartImage({required this.url, required this.size, this.height, this.radius = 0});

  final String url;
  final double size;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ListingImage(
      url: url,
      width: size == double.infinity ? double.infinity : size,
      height: height ?? size,
      borderRadius: radius > 0 ? BorderRadius.circular(radius) : null,
    );
  }
}
