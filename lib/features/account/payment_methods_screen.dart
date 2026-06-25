import 'package:flutter/material.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/utils/responsive.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.add))],
      ),
      body: ListView(
        padding: EdgeInsets.all(r.horizontalPadding()),
        children: [
          _PaymentCard(
            type: 'VISA',
            last4: '4242',
            expiry: '12/27',
            isDefault: true,
            color: AppColors.primaryDark,
          ),
          _PaymentCard(
            type: 'Mastercard',
            last4: '8888',
            expiry: '06/26',
            isDefault: false,
            color: const Color(0xFF1A1F71),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.type,
    required this.last4,
    required this.expiry,
    required this.isDefault,
    required this.color,
  });

  final String type;
  final String last4;
  final String expiry;
  final bool isDefault;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(type, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                if (isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Default', style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('•••• •••• •••• $last4',
                style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 2)),
            const SizedBox(height: 16),
            Text('Expires $expiry', style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
