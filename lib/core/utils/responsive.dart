import 'package:flutter/material.dart';

class Responsive {
  const Responsive(this.context);

  final BuildContext context;

  double get width => MediaQuery.sizeOf(context).width;
  double get height => MediaQuery.sizeOf(context).height;

  bool get isMobile => width < 600;
  bool get isTablet => width >= 600 && width < 1024;
  bool get isDesktop => width >= 1024;

  double horizontalPadding() {
    if (isDesktop) return 48;
    if (isTablet) return 32;
    return 16;
  }

  int gridColumns({int mobile = 2, int tablet = 3, int desktop = 4}) {
    if (isDesktop) return desktop;
    if (isTablet) return tablet;
    return mobile;
  }

  double cardWidth({double mobile = 160, double tablet = 200}) {
    if (isTablet || isDesktop) return tablet;
    return mobile;
  }

  /// Scroll/list bottom inset for tab screens inside [MainShell].
  double bottomNavPadding({double extra = 16}) {
    return MediaQuery.paddingOf(context).bottom + _mainShellNavContentHeight() + extra;
  }

  /// Bottom inset for content that must sit above [MainShell]'s bottom nav.
  /// Uses [MediaQuery.viewPadding] because [MainShell] uses `extendBody: true`,
  /// which clears bottom [MediaQuery.padding] on tab screens.
  double mainShellNavOverlayHeight({double extra = 12}) {
    return MediaQuery.viewPaddingOf(context).bottom + _mainShellNavContentHeight() + extra;
  }

  /// Bottom padding for a sticky footer above [MainShell]'s bottom nav.
  double stickyFooterBottomPadding({double extra = 12}) => mainShellNavOverlayHeight(extra: extra);

  /// Matches [MainShell]'s bottom nav: top padding + bar + bottom padding.
  double _mainShellNavContentHeight() {
    const base = 8.0 + 64.0 + 4.0; // padding + NavigationBar + padding
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    if (textScale <= 1.0) return base;
    return base + ((textScale - 1.0) * 16).clamp(0, 24);
  }
}
