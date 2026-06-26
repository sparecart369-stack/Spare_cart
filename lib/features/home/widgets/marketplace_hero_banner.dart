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
        final height = (width / 2.05).clamp(168.0, 220.0);

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
                  right: -width * 0.04,
                  top: -height * 0.1,
                  bottom: -height * 0.14,
                  width: width * 0.54,
                  child: Image.asset(
                    AppAssets.heroBrakeRotor,
                    fit: BoxFit.contain,
                    alignment: Alignment.centerRight,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(width * 0.06, height * 0.14, width * 0.4, height * 0.14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Global Marketplace for \nNew & Used Auto Parts',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: (width * 0.028).clamp(17.0, 22.0),
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              letterSpacing: -0.4,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: height * 0.06),
                          Text(
                            'Find genuine new and quality used spare parts at the best prices.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: (width * 0.022).clamp(12.0, 14.0),
                              fontWeight: FontWeight.w500,
                              height: 1.0,
                              color: Colors.white.withValues(alpha: 0.78),
                            ),
                          ),
                        ],
                      ),
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
                              horizontal: width * 0.04,
                              vertical: height * 0.07,
                            ),
                            child: Text(
                              'Explore Parts',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: (width * 0.034).clamp(13.0, 15.0),
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
        final height = width / 2.05;

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
