import 'package:flutter/material.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/theme/app_decorations.dart';
import 'package:spare_kart/core/theme/app_typography.dart';

/// Visual tile used for category and subcategory pickers.
class CatalogImageTile extends StatelessWidget {
  const CatalogImageTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.imageAsset,
    this.fallbackIcon = Icons.category_rounded,
    this.colorIndex = 0,
    this.compact = false,
  });

  final String label;
  final String? imageAsset;
  final IconData fallbackIcon;
  final int colorIndex;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  static const _accentColors = [
    Color(0xFF2563EB),
    Color(0xFF059669),
    Color(0xFFD97706),
    Color(0xFF9333EA),
    Color(0xFFDC2626),
    Color(0xFF0284C7),
    Color(0xFF7C3AED),
    Color(0xFF10B981),
  ];

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 26.0 : 30.0;
    final accent = _accentColors[colorIndex % _accentColors.length];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: selected ? 2 : 0,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : AppDecorations.shadowSm,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _TileImage(
                imageAsset: imageAsset,
                accent: accent,
                fallbackIcon: fallbackIcon,
                iconSize: iconSize,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.92),
                    ],
                    stops: const [0.35, 0.72, 1.0],
                  ),
                ),
              ),
              if (selected)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.18),
                  ),
                ),
              Positioned(
                left: compact ? 6 : 8,
                right: compact ? 6 : 8,
                bottom: compact ? 6 : 8,
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    fontSize: compact ? 9 : 10,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                    color: Colors.white,
                  ),
                ),
              ),
              if (selected)
                Positioned(
                  top: compact ? 5 : 6,
                  right: compact ? 5 : 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: compact ? 10 : 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TileImage extends StatelessWidget {
  const _TileImage({
    required this.imageAsset,
    required this.accent,
    required this.fallbackIcon,
    required this.iconSize,
  });

  final String? imageAsset;
  final Color accent;
  final IconData fallbackIcon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    if (imageAsset == null) {
      return _FallbackArtwork(
        accent: accent,
        fallbackIcon: fallbackIcon,
        iconSize: iconSize,
      );
    }

    return Image.asset(
      imageAsset!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) => _FallbackArtwork(
        accent: accent,
        fallbackIcon: fallbackIcon,
        iconSize: iconSize,
      ),
    );
  }
}

class _FallbackArtwork extends StatelessWidget {
  const _FallbackArtwork({
    required this.accent,
    required this.fallbackIcon,
    required this.iconSize,
  });

  final Color accent;
  final IconData fallbackIcon;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.42),
            const Color(0xFF141414),
            accent.withValues(alpha: 0.18),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: -8,
            top: -8,
            child: Icon(
              fallbackIcon,
              size: iconSize * 2.2,
              color: accent.withValues(alpha: 0.12),
            ),
          ),
          Align(
            alignment: const Alignment(0, -0.2),
            child: Icon(
              fallbackIcon,
              size: iconSize,
              color: accent.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}
