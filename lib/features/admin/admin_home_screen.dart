import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:spare_kart/bloc/app_mode/app_mode_bloc.dart';
import 'package:spare_kart/bloc/listings/listings_bloc.dart';
import 'package:spare_kart/core/router/app_routes.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/utils/responsive.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Mode'),
        actions: [
          TextButton.icon(
            onPressed: () => context.read<AppModeBloc>().add(AppModeSet(AppMode.buyer)),
            icon: const Icon(Icons.storefront_outlined, size: 18),
            label: const Text('Buyer Mode'),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          AdminDashboardScreen(),
          _AdminListingsTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'My Items'),
        ],
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
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                const Text('No items added yet'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<AppModeBloc>().add(AppModeSet(AppMode.buyer)),
                  child: const Text('Switch to Buyer & Add Items'),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.all(r.horizontalPadding()),
          itemCount: listings.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final part = listings[i];
            final currency = NumberFormat.currency(symbol: '\$');
            return Card(
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(part.imageUrl, width: 56, height: 56, fit: BoxFit.cover),
                ),
                title: Text(part.fullTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${part.conditionLabel} • ${part.location}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(currency.format(part.price),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const Text('Active', style: TextStyle(fontSize: 11, color: AppColors.success)),
                  ],
                ),
                onTap: () => Navigator.pushNamed(context, AppRoutes.productDetail, arguments: part),
              ),
            );
          },
        );
      },
    );
  }
}
