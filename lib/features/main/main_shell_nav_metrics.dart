import 'package:flutter/material.dart';

/// Shared layout metrics for [MainShell]'s bottom navigation bar.
abstract final class MainShellNavMetrics {
  static const outerPadding = EdgeInsets.fromLTRB(8, 8, 8, 4);

  /// Material 3 default; leaves room for icon + always-visible labels.
  static const barHeight = 80.0;

  static double contentHeight(BuildContext context) {
    const base = 8.0 + barHeight + 4.0;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    if (textScale <= 1.0) return base;
    return base + ((textScale - 1.0) * 16).clamp(0, 24);
  }

  /// Total height from the screen bottom occupied by [MainShell]'s nav bar.
  static double totalHeight(BuildContext context) {
    return MediaQuery.viewPaddingOf(context).bottom + contentHeight(context);
  }

  /// Bottom inset for sticky footers sitting above [MainShell]'s bottom nav.
  static double stickyFooterInset(BuildContext context, {double extra = 16}) {
    return totalHeight(context) + extra;
  }
}
