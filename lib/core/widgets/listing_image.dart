import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:spare_kart/core/theme/app_colors.dart';

/// Displays a listing photo from a network URL or a local file path.
class ListingImage extends StatelessWidget {
  const ListingImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.errorIconSize = 32,
    this.errorIconColor,
    this.errorBackground,
    this.showLoading = true,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final double errorIconSize;
  final Color? errorIconColor;
  final Decoration? errorBackground;
  final bool showLoading;

  static bool isNetworkUrl(String url) =>
      url.startsWith('http://') || url.startsWith('https://');

  Widget _errorWidget() {
    return Container(
      width: width,
      height: height,
      decoration: errorBackground ??
          const BoxDecoration(color: AppColors.primaryLight),
      child: Center(
        child: Icon(
          Icons.image_not_supported_rounded,
          color: errorIconColor ?? AppColors.primary.withValues(alpha: 0.4),
          size: errorIconSize,
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (isNetworkUrl(url)) {
      return Image.network(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _errorWidget(),
        loadingBuilder: showLoading
            ? (context, child, progress) {
                if (progress == null) return child;
                return Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                );
              }
            : null,
      );
    }

    if (!kIsWeb) {
      return Image.file(
        File(url),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => _errorWidget(),
      );
    }

    return _errorWidget();
  }

  @override
  Widget build(BuildContext context) {
    final image = _buildImage();
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}
