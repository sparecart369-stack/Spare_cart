import 'package:flutter/material.dart';
import 'package:spare_kart/features/main/main_shell_bottom_inset.dart';

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
    return MainShellBottomInset.footerInsetOf(context, extra: extra);
  }

  /// Bottom inset for content that must sit above [MainShell]'s bottom nav.
  double mainShellNavOverlayHeight({double extra = 16}) {
    return MainShellBottomInset.footerInsetOf(context, extra: extra);
  }

  /// Bottom padding for a sticky footer above [MainShell]'s bottom nav.
  double stickyFooterBottomPadding({double extra = 16}) =>
      mainShellNavOverlayHeight(extra: extra);
}
