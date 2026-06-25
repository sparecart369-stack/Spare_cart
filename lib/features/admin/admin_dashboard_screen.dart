import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:spare_kart/bloc/listings/listings_bloc.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/utils/responsive.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final currency = NumberFormat.currency(symbol: '\$');

    return BlocBuilder<ListingsBloc, ListingsState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(r.horizontalPadding()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cols = r.gridColumns(mobile: 2, tablet: 4);
                  return GridView.count(
                    crossAxisCount: cols,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      _StatCard(
                        icon: Icons.attach_money,
                        label: 'Total Sales',
                        value: currency.format(state.adminTotalSales),
                        color: AppColors.success,
                      ),
                      _StatCard(
                        icon: Icons.inventory_2,
                        label: 'Active Listings',
                        value: '${state.adminActiveListings}',
                        color: AppColors.primary,
                      ),
                      _StatCard(
                        icon: Icons.pending_actions,
                        label: 'Pending Orders',
                        value: '${state.adminPendingOrders}',
                        color: AppColors.warning,
                      ),
                      _StatCard(
                        icon: Icons.trending_up,
                        label: 'This Month',
                        value: currency.format(state.adminTotalSales * 0.35),
                        color: AppColors.primaryDark,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _ActivityTile(
                icon: Icons.shopping_bag,
                title: 'New order received',
                subtitle: 'Order #ORD-1003 - Alternator',
                time: '2 hours ago',
              ),
              _ActivityTile(
                icon: Icons.visibility,
                title: 'Listing viewed 12 times',
                subtitle: 'LED Headlight Pair',
                time: '5 hours ago',
              ),
              _ActivityTile(
                icon: Icons.add_circle_outline,
                title: 'New listing published',
                subtitle: state.adminParts.isNotEmpty
                    ? state.adminParts.first.name
                    : 'No listings yet',
                time: 'Today',
              ),
              const SizedBox(height: 24),
              const Text('Sales Chart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                    child: SizedBox(
                    height: 160,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(7, (i) {
                        final heights = [40.0, 65, 45, 80, 55, 90, 70];
                        final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: heights[i] * 1.2,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(days[i],
                                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle),
        trailing: Text(time, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ),
    );
  }
}
