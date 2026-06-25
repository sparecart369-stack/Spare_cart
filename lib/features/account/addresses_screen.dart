import 'package:flutter/material.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/utils/responsive.dart';

class AddressesScreen extends StatelessWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Addresses'),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.add))],
      ),
      body: ListView(
        padding: EdgeInsets.all(r.horizontalPadding()),
        children: [
          _AddressCard(
            label: 'Home',
            address: '123 Main Street\nLos Angeles, CA 90001',
            isDefault: true,
          ),
          _AddressCard(
            label: 'Work',
            address: '456 Business Ave\nSan Francisco, CA 94102',
            isDefault: false,
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.label, required this.address, required this.isDefault});

  final String label;
  final String address;
  final bool isDefault;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (isDefault) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Default', style: TextStyle(color: AppColors.primary, fontSize: 11)),
                  ),
                ],
                const Spacer(),
                IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined, size: 20)),
              ],
            ),
            const SizedBox(height: 8),
            Text(address, style: const TextStyle(color: AppColors.textSecondary, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
