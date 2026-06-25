import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:spare_kart/bloc/cart/cart_bloc.dart';
import 'package:spare_kart/bloc/orders/orders_bloc.dart';
import 'package:spare_kart/core/router/app_routes.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/utils/responsive.dart';
import 'package:spare_kart/core/widgets/common_widgets.dart';
import 'package:spare_kart/data/models/models.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _step = 0;
  String _shippingMethod = 'Standard (3-5 days)';
  String _paymentMethod = 'Visa ending in 4242';

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final cart = context.watch<CartBloc>().state;
    final currency = NumberFormat.currency(symbol: '\$');

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(r.horizontalPadding()),
            child: Row(
              children: List.generate(4, (i) {
                final active = i <= _step;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                    height: 4,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(r.horizontalPadding()),
              child: switch (_step) {
                0 => _buildAddress(),
                1 => _buildShipping(),
                2 => _buildPayment(),
                _ => _buildSummary(cart, currency),
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(r.horizontalPadding()),
            child: SafeArea(
              child: PrimaryButton(
                label: _step < 3 ? 'Continue' : 'Place Order',
                onPressed: () {
                  if (_step < 3) {
                    setState(() => _step++);
                  } else {
                    _placeOrder(cart);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddress() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Shipping Address', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        TextField(decoration: InputDecoration(labelText: 'Full Name', hintText: 'John Driver')),
        SizedBox(height: 12),
        TextField(decoration: InputDecoration(labelText: 'Street Address', hintText: '123 Main St')),
        SizedBox(height: 12),
        TextField(decoration: InputDecoration(labelText: 'City', hintText: 'Los Angeles')),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: TextField(decoration: InputDecoration(labelText: 'State', hintText: 'CA'))),
            SizedBox(width: 12),
            Expanded(child: TextField(decoration: InputDecoration(labelText: 'ZIP', hintText: '90001'))),
          ],
        ),
      ],
    );
  }

  Widget _buildShipping() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Shipping Method', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...['Standard (3-5 days) - \$12.99', 'Express (1-2 days) - \$24.99', 'Free Pickup - \$0.00'].map(
          (m) => RadioListTile<String>(
            title: Text(m),
            value: m.split(' - ').first,
            groupValue: _shippingMethod,
            onChanged: (v) => setState(() => _shippingMethod = v!),
          ),
        ),
      ],
    );
  }

  Widget _buildPayment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment Method', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Card(
          color: AppColors.primaryDark,
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('VISA', style: TextStyle(color: Colors.white70)),
                SizedBox(height: 24),
                Text('•••• •••• •••• 4242', style: TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 2)),
                SizedBox(height: 16),
                Text('JOHN DRIVER', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...['Visa ending in 4242', 'Mastercard ending in 8888', 'PayPal'].map(
          (m) => RadioListTile<String>(
            title: Text(m),
            value: m,
            groupValue: _paymentMethod,
            onChanged: (v) => setState(() => _paymentMethod = v!),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(CartState cart, NumberFormat currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...cart.items.map((item) => ListTile(
              leading: Image.network(item.part.imageUrl, width: 48, height: 48, fit: BoxFit.cover),
              title: Text(item.part.name),
              subtitle: Text('Qty: ${item.quantity}'),
              trailing: Text(currency.format(item.total)),
            )),
        const Divider(),
        _summaryRow('Subtotal', currency.format(cart.subtotal)),
        _summaryRow('Shipping', currency.format(cart.shipping)),
        _summaryRow('Total', currency.format(cart.total), bold: true),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : null)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : null)),
        ],
      ),
    );
  }

  void _placeOrder(CartState cart) {
    final order = Order(
      id: 'ORD-${DateTime.now().millisecondsSinceEpoch % 10000}',
      items: cart.items,
      status: OrderStatus.paid,
      date: DateTime.now(),
      total: cart.total,
      trackingNumber: 'Pending',
    );
    context.read<OrdersBloc>().add(OrderPlaced(order));
    context.read<CartBloc>().add(CartCleared());
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.main, (_) => false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order placed successfully!')),
    );
  }
}
