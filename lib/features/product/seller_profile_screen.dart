import 'package:flutter/material.dart';
import 'package:spare_kart/core/router/app_routes.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/utils/responsive.dart';
import 'package:spare_kart/core/widgets/part_card.dart';
import 'package:spare_kart/data/models/models.dart';

class SellerProfileScreen extends StatelessWidget {
  const SellerProfileScreen({super.key, required this.part});

  final Part part;

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Seller Profile')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(r.horizontalPadding()),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primaryLight,
              child: Text(part.sellerName[0], style: const TextStyle(fontSize: 36, color: AppColors.primary)),
            ),
            const SizedBox(height: 12),
            Text(part.sellerName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                Text(' ${part.sellerRating} Rating', style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _StatCard(label: 'Listings', value: '24'),
                _StatCard(label: 'Positive', value: '98%'),
                _StatCard(label: 'Orders', value: '156'),
              ],
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('From This Seller', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            const SizedBox(height: 12),
            PartCard(
              part: part,
              compact: true,
              onTap: () => Navigator.pushNamed(context, AppRoutes.productDetail, arguments: part),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
