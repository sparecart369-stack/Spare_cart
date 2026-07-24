import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spare_kart/core/constants/app_assets.dart';
import 'package:spare_kart/core/theme/app_decorations.dart';

/// Hero banner — black background, brake rotor imagery, Explore Parts CTA.
class MarketplaceHeroBanner extends StatelessWidget {
  const MarketplaceHeroBanner({super.key, required this.onExplore});

  final VoidCallback onExplore;

  static const _background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF141414),
      Color(0xFF000000),
      Color(0xFF050505),
    ],
    stops: [0.0, 0.55, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Width-based aspect keeps the banner compact on narrow screens.
        final height = (width / 2.2).clamp(152.0, 184.0);
        final titleSize = (width * 0.046).clamp(15.5, 19.0);
        final subtitleSize = (width * 0.031).clamp(11.0, 12.5);
        final showSubtitle = height >= 160;
        final horizontalPad = width * 0.055;
        final topPad = height * 0.1;
        final bottomPad = height * 0.12;
        final ctaGap = height * 0.055;

        return SizedBox(
          height: height,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDecorations.radiusXl),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFF000000),
                    gradient: _background,
                  ),
                ),
                Positioned(
                  right: -width * 0.02,
                  top: -height * 0.08,
                  bottom: -height * 0.1,
                  width: width * 0.5,
                  child: Image.asset(
                    AppAssets.heroBrakeRotor,
                    fit: BoxFit.contain,
                    alignment: Alignment.centerRight,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPad,
                    topPad,
                    width * 0.42,
                    bottomPad,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Global Marketplace for\nNew & Used Auto Parts',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.4,
                          color: Colors.white,
                        ),
                      ),
                      if (showSubtitle) ...[
                        SizedBox(height: height * 0.035),
                        Text(
                          'Genuine new & used parts at the best prices.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: subtitleSize,
                            fontWeight: FontWeight.w500,
                            height: 1.25,
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                        ),
                      ],
                      SizedBox(height: ctaGap),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onExplore,
                          borderRadius: BorderRadius.circular(30),
                          child: Ink(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: width * 0.042,
                              vertical: (height * 0.048).clamp(8.0, 11.0),
                            ),
                            child: Text(
                              'Explore Parts',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: (width * 0.036).clamp(12.5, 14.5),
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0A0A0A),
                                letterSpacing: -0.1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Raster fallback using the exact provided banner PNG.
class MarketplaceHeroBannerImage extends StatelessWidget {
  const MarketplaceHeroBannerImage({super.key, required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = (width / 2.2).clamp(152.0, 184.0);

        return ClipRRect(
          borderRadius: BorderRadius.circular(AppDecorations.radiusXl),
          child: Container(
            color: Colors.black,
            height: height,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(onTap: onExplore),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
