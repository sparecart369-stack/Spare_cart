import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spare_kart/bloc/listings/listings_bloc.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/theme/app_decorations.dart';
import 'package:spare_kart/core/theme/app_typography.dart';
import 'package:spare_kart/core/utils/app_currency.dart';
import 'package:spare_kart/core/utils/responsive.dart';
import 'package:spare_kart/core/widgets/common_widgets.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return BlocBuilder<ListingsBloc, ListingsState>(
      builder: (context, state) {
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(r.horizontalPadding(), 20, r.horizontalPadding(), 0),
                child: _HeroSummaryCard(
                  totalSales: state.adminTotalSales,
                  activeListings: state.adminActiveListings,
                  pendingOrders: state.adminPendingOrders,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(r.horizontalPadding(), 8, r.horizontalPadding(), 0),
                child: const SectionHeader(
                  title: 'Performance',
                  subtitle: 'Key metrics at a glance',
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding()),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final cols = r.gridColumns(mobile: 2, tablet: 4);
                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: cols == 2 ? 1.15 : 1.25,
                    ),
                    delegate: SliverChildListDelegate.fixed([
                      _StatCard(
                        icon: Icons.payments_rounded,
                        label: 'Total Sales',
                        value: AppCurrency.format(state.adminTotalSales),
                        color: AppColors.success,
                        softColor: AppColors.successSoft,
                      ),
                      _StatCard(
                        icon: Icons.inventory_2_rounded,
                        label: 'Active Listings',
                        value: '${state.adminActiveListings}',
                        color: AppColors.primary,
                        softColor: AppColors.primaryLight,
                      ),
                      _StatCard(
                        icon: Icons.pending_actions_rounded,
                        label: 'Pending Orders',
                        value: '${state.adminPendingOrders}',
                        color: AppColors.warning,
                        softColor: AppColors.warningSoft,
                      ),
                      _StatCard(
                        icon: Icons.trending_up_rounded,
                        label: 'This Month',
                        value: AppCurrency.format(state.adminTotalSales * 0.35),
                        color: AppColors.primaryDark,
                        softColor: AppColors.backgroundAlt,
                      ),
                    ]),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(r.horizontalPadding(), 24, r.horizontalPadding(), 0),
                child: const SectionHeader(
                  title: 'Recent Activity',
                  subtitle: 'Latest updates from your store',
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding()),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _ActivityTile(
                    icon: Icons.shopping_bag_rounded,
                    iconColor: AppColors.success,
                    iconBg: AppColors.successSoft,
                    title: 'New order received',
                    subtitle: 'Order #ORD-1003 — Alternator',
                    time: '2h ago',
                  ),
                  _ActivityTile(
                    icon: Icons.visibility_rounded,
                    iconColor: AppColors.primary,
                    iconBg: AppColors.primaryLight,
                    title: 'Listing viewed 12 times',
                    subtitle: 'LED Headlight Pair',
                    time: '5h ago',
                  ),
                  _ActivityTile(
                    icon: Icons.add_circle_rounded,
                    iconColor: AppColors.accent,
                    iconBg: AppColors.accentSoft,
                    title: 'New listing published',
                    subtitle: state.adminParts.isNotEmpty
                        ? state.adminParts.first.name
                        : 'No listings yet',
                    time: 'Today',
                  ),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(r.horizontalPadding(), 24, r.horizontalPadding(), 0),
                child: const SectionHeader(
                  title: 'Weekly Sales',
                  subtitle: 'Revenue trend this week',
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  r.horizontalPadding(),
                  0,
                  r.horizontalPadding(),
                  r.bottomNavPadding(),
                ),
                child: _SalesChartCard(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeroSummaryCard extends StatelessWidget {
  const _HeroSummaryCard({
    required this.totalSales,
    required this.activeListings,
    required this.pendingOrders,
  });

  final double totalSales;
  final int activeListings;
  final int pendingOrders;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDecorations.radiusXl),
        boxShadow: AppDecorations.shadowLg,
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
                ),
                child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Store Overview',
                      style: AppTypography.textTheme.titleMedium?.copyWith(color: Colors.white),
                    ),
                    Text(
                      'Your business snapshot',
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            AppCurrency.format(totalSales),
            style: AppTypography.priceLarge.copyWith(
              color: Colors.white,
              fontSize: 32,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total revenue',
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Listings',
                  value: '$activeListings',
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _HeroMetric(
                  label: 'Pending',
                  value: '$pendingOrders',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.softColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color softColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.card(radius: AppDecorations.radiusLg),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: softColor,
              borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppDecorations.card(radius: AppDecorations.radiusMd),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: AppTypography.textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesChartCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const heights = [40.0, 65.0, 45.0, 80.0, 55.0, 90.0, 70.0];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const maxHeight = 108.0;

    return Container(
      decoration: AppDecorations.elevatedCard(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last 7 days',
                style: AppTypography.textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_upward_rounded, size: 12, color: AppColors.success),
                    const SizedBox(width: 2),
                    Text(
                      '+12%',
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final isPeak = heights[i] == heights.reduce((a, b) => a > b ? a : b);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: (heights[i] / 90) * maxHeight,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: isPeak
                                  ? [AppColors.primaryMid, AppColors.primaryDark]
                                  : [
                                      AppColors.primary.withValues(alpha: 0.55),
                                      AppColors.primary.withValues(alpha: 0.85),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          days[i],
                          style: AppTypography.textTheme.labelSmall?.copyWith(
                            color: isPeak ? AppColors.primary : AppColors.textTertiary,
                            fontWeight: isPeak ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
