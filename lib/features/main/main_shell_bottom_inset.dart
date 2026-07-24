import 'package:flutter/material.dart';
import 'package:spare_kart/features/main/main_shell_nav_metrics.dart';

/// Exposes the live measured height of [MainShell]'s bottom navigation bar.
class MainShellBottomInset extends InheritedWidget {
  const MainShellBottomInset({
    super.key,
    required this.navBarHeight,
    required super.child,
  });

  final double navBarHeight;

  double stickyFooterInset({double extra = 16}) => navBarHeight + extra;

  static MainShellBottomInset? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainShellBottomInset>();
  }

  static double navHeightOf(BuildContext context) {
    return maybeOf(context)?.navBarHeight ??
        MainShellNavMetrics.totalHeight(context);
  }

  static double footerInsetOf(BuildContext context, {double extra = 16}) {
    return maybeOf(context)?.stickyFooterInset(extra: extra) ??
        MainShellNavMetrics.stickyFooterInset(context, extra: extra);
  }

  @override
  bool updateShouldNotify(MainShellBottomInset oldWidget) {
    return navBarHeight != oldWidget.navBarHeight;
  }
}

/// Reports its laid-out height after each frame.
class ReportLayoutHeight extends StatefulWidget {
  const ReportLayoutHeight({
    super.key,
    required this.onHeight,
    required this.child,
  });

  final ValueChanged<double> onHeight;
  final Widget child;

  @override
  State<ReportLayoutHeight> createState() => _ReportLayoutHeightState();
}

class _ReportLayoutHeightState extends State<ReportLayoutHeight> {
  double? _lastHeight;

  void _reportSize() {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;

    final height = box.size.height;
    if (_lastHeight == height) return;
    _lastHeight = height;
    widget.onHeight(height);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportSize());
  }

  @override
  void didUpdateWidget(covariant ReportLayoutHeight oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportSize());
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportSize());
    return widget.child;
  }
}
