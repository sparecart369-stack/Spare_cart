import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:spare_kart/bloc/orders/orders_bloc.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/utils/responsive.dart';
import 'package:spare_kart/data/models/models.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final currency = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Paid'),
            Tab(text: 'Shipped'),
            Tab(text: 'Delivered'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: BlocBuilder<OrdersBloc, OrdersState>(
        builder: (context, state) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(state.orders, currency, dateFormat, r),
              _buildList(state.orders.where((o) => o.status == OrderStatus.paid).toList(), currency, dateFormat, r),
              _buildList(state.orders.where((o) => o.status == OrderStatus.shipped).toList(), currency, dateFormat, r),
              _buildList(state.orders.where((o) => o.status == OrderStatus.delivered).toList(), currency, dateFormat, r),
              _buildList(state.orders.where((o) => o.status == OrderStatus.cancelled).toList(), currency, dateFormat, r),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<Order> orders, NumberFormat currency, DateFormat dateFormat, Responsive r) {
    if (orders.isEmpty) {
      return const Center(child: Text('No orders found'));
    }
    return ListView.separated(
      padding: EdgeInsets.all(r.horizontalPadding()),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final order = orders[i];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(order.id, style: const TextStyle(fontWeight: FontWeight.w600)),
                    _StatusBadge(status: order.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(dateFormat.format(order.date), style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                Text('${order.items.length} item(s) • ${currency.format(order.total)}'),
                if (order.trackingNumber != 'N/A' && order.trackingNumber != 'Pending')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Tracking: ${order.trackingNumber}',
                        style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      OrderStatus.paid => (AppColors.warning, 'Paid'),
      OrderStatus.shipped => (AppColors.primary, 'Shipped'),
      OrderStatus.delivered => (AppColors.success, 'Delivered'),
      OrderStatus.cancelled => (AppColors.error, 'Cancelled'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
