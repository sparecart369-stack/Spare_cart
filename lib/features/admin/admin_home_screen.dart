import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spare_kart/bloc/app_mode/app_mode_bloc.dart';
import 'package:spare_kart/bloc/auth/auth_bloc.dart';
import 'package:spare_kart/bloc/listings/listings_bloc.dart';
import 'package:spare_kart/core/router/app_routes.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/theme/app_decorations.dart';
import 'package:spare_kart/core/theme/app_typography.dart';
import 'package:spare_kart/core/utils/app_currency.dart';
import 'package:spare_kart/core/utils/responsive.dart';
import 'package:spare_kart/core/widgets/common_widgets.dart';
import 'package:spare_kart/data/models/models.dart';
import 'package:spare_kart/features/admin/admin_dashboard_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final user = context.watch<AuthBloc>().state.user;
    final firstName = (user?.name ?? 'Admin').split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _AdminHeader(
            firstName: firstName,
            horizontalPadding: r.horizontalPadding(),
            onBuyerMode: () => context.read<AppModeBloc>().add(AppModeSet(AppMode.buyer)),
            onMessages: () => Navigator.pushNamed(context, AppRoutes.messages),
          ),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: const [
                AdminDashboardScreen(),
                _AdminListingsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: AppDecorations.shadowNav,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              backgroundColor: Colors.transparent,
              elevation: 0,
              height: 64,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2_rounded),
                  label: 'My Items',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({
    required this.firstName,
    required this.horizontalPadding,
    required this.onBuyerMode,
    required this.onMessages,
  });

  final String firstName;
  final double horizontalPadding;
  final VoidCallback onBuyerMode;
  final VoidCallback onMessages;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F2B6E), Color(0xFF1B4DDB), Color(0xFF2563EB)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ADMIN CONSOLE',
                          style: AppTypography.overline.copyWith(
                            color: Colors.white.withValues(alpha: 0.65),
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Hi, $firstName',
                          style: AppTypography.textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.verified_rounded,
                                size: 14,
                                color: AppColors.accent.withValues(alpha: 0.95),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Seller Admin',
                                style: AppTypography.textTheme.labelSmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onMessages,
                      borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
                      child: Ink(
                        decoration: AppDecorations.glassSurface(),
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onBuyerMode,
                      borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
                      child: Ink(
                        decoration: AppDecorations.glassSurface(),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.storefront_rounded,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Buyer',
                              style: AppTypography.textTheme.labelMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminListingsTab extends StatelessWidget {
  const _AdminListingsTab();

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return BlocBuilder<ListingsBloc, ListingsState>(
      builder: (context, state) {
        final listings = state.adminParts;

        if (listings.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding()),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const EmptyState(
                  icon: Icons.inventory_2_rounded,
                  title: 'No listings yet',
                  subtitle: 'Switch to buyer mode to browse and add spare parts to your store.',
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Go to Buyer Mode',
                  icon: Icons.storefront_rounded,
                  onPressed: () => context.read<AppModeBloc>().add(AppModeSet(AppMode.buyer)),
                ),
              ],
            ),
          );
        }

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(r.horizontalPadding(), 20, r.horizontalPadding(), 0),
                child: SectionHeader(
                  title: 'My Items',
                  subtitle: '${listings.length} active listing${listings.length == 1 ? '' : 's'}',
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                r.horizontalPadding(),
                0,
                r.horizontalPadding(),
                r.bottomNavPadding(),
              ),
              sliver: SliverList.separated(
                itemCount: listings.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _AdminListingCard(
                  part: listings[i],
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.productDetail,
                    arguments: listings[i],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AdminListingCard extends StatelessWidget {
  const _AdminListingCard({required this.part, required this.onTap});

  final Part part;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDecorations.radiusLg),
        child: Ink(
          decoration: AppDecorations.card(radius: AppDecorations.radiusLg),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
                child: Image.network(
                  part.imageUrl,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      part.fullTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ConditionChip(label: part.conditionLabel),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            part.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppCurrency.format(part.price), style: AppTypography.price.copyWith(fontSize: 16)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.successSoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Active',
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
