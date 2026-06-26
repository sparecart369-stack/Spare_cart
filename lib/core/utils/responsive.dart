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
    const navBarHeight = 76.0; // SafeArea + 8 + NavigationBar(64) + 4
    return MediaQuery.paddingOf(context).bottom + navBarHeight + extra;
  }

  /// Bottom padding for a sticky footer above [MainShell]'s bottom nav.
  /// Uses [MediaQuery.viewPadding] because [MainShell] uses `extendBody: true`,
  /// which clears bottom [MediaQuery.padding] on tab screens.
  double stickyFooterBottomPadding({double extra = 4}) {
    const navBarHeight = 76.0; // 8 + NavigationBar(64) + 4
    return MediaQuery.viewPaddingOf(context).bottom + navBarHeight + extra;
  }
}
