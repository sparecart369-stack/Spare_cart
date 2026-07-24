import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spare_kart/bloc/app_mode/app_mode_bloc.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/theme/app_decorations.dart';
import 'package:spare_kart/features/account/account_screen.dart';
import 'package:spare_kart/features/admin/admin_home_screen.dart';
import 'package:spare_kart/features/home/home_screen.dart';
import 'package:spare_kart/bloc/messages/messages_bloc.dart';
import 'package:spare_kart/features/messages/messages_screen.dart';
import 'package:spare_kart/features/search/search_screen.dart';
import 'package:spare_kart/features/main/main_shell_bottom_inset.dart';
import 'package:spare_kart/features/main/main_shell_nav_metrics.dart';
import 'package:spare_kart/features/sell/sell_screen.dart';

class MainShellTabController extends InheritedWidget {
  const MainShellTabController({
    super.key,
    required this.selectTab,
    required super.child,
  });

  final ValueChanged<int> selectTab;

  static MainShellTabController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MainShellTabController>();
  }

  @override
  bool updateShouldNotify(MainShellTabController oldWidget) => false;
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  double? _measuredNavHeight;

  void _onNavHeightMeasured(double height) {
    if (_measuredNavHeight == height) return;
    setState(() => _measuredNavHeight = height);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppModeBloc, AppModeState>(
      builder: (context, modeState) {
        if (modeState.isAdmin) {
          return const AdminHomeScreen();
        }

        final screens = [
          const HomeScreen(),
          const SearchScreen(),
          const SellScreen(),
          const MessagesScreen(),
          const AccountScreen(),
        ];

        final unreadCount = context.watch<MessagesBloc>().state.threads.fold(
          0,
          (sum, thread) => sum + thread.unreadCount,
        );

        final navBarHeight =
            _measuredNavHeight ?? MainShellNavMetrics.totalHeight(context);

        return MainShellTabController(
          selectTab: (i) => setState(() => _index = i),
          child: MainShellBottomInset(
            navBarHeight: navBarHeight,
            child: Scaffold(
              backgroundColor: AppColors.background,
              body: IndexedStack(index: _index, children: screens),
              extendBody: true,
              bottomNavigationBar: ReportLayoutHeight(
                onHeight: _onNavHeightMeasured,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    boxShadow: AppDecorations.shadowNav,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: MainShellNavMetrics.outerPadding,
                      child: NavigationBar(
                        selectedIndex: _index,
                        onDestinationSelected: (i) =>
                            setState(() => _index = i),
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        indicatorColor: Colors.transparent,
                        height: MainShellNavMetrics.barHeight,
                        labelBehavior:
                            NavigationDestinationLabelBehavior.alwaysShow,
                        destinations: [
                          _navDest(
                            Icons.home_rounded,
                            Icons.home_outlined,
                            'Home',
                            0,
                          ),
                          _navDest(
                            Icons.search_rounded,
                            Icons.search_rounded,
                            'Search',
                            1,
                          ),
                          const NavigationDestination(
                            icon: _SellNavIcon(),
                            selectedIcon: _SellNavIcon(),
                            label: 'Sell',
                          ),
                          _messagesNavDest(unreadCount),
                          _navDest(
                            Icons.person_rounded,
                            Icons.person_outline_rounded,
                            'Account',
                            4,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  NavigationDestination _navDest(
    IconData selected,
    IconData unselected,
    String label,
    int index,
  ) {
    return NavigationDestination(
      icon: Icon(unselected),
      selectedIcon: Icon(selected),
      label: label,
    );
  }

  NavigationDestination _messagesNavDest(int unreadCount) {
    return NavigationDestination(
      icon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text('$unreadCount'),
        child: const Icon(Icons.chat_bubble_outline_rounded),
      ),
      selectedIcon: Badge(
        isLabelVisible: unreadCount > 0,
        label: Text('$unreadCount'),
        child: const Icon(Icons.chat_bubble_rounded),
      ),
      label: 'Messages',
    );
  }
}

class _SellNavIcon extends StatelessWidget {
  const _SellNavIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
    );
  }
}
