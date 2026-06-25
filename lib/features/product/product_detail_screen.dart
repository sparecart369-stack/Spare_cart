import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:spare_kart/bloc/cart/cart_bloc.dart';
import 'package:spare_kart/core/router/app_routes.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/theme/app_decorations.dart';
import 'package:spare_kart/core/theme/app_typography.dart';
import 'package:spare_kart/core/utils/responsive.dart';
import 'package:spare_kart/core/widgets/common_widgets.dart';
import 'package:spare_kart/data/models/models.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.part});

  final Part part;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final int _imageIndex = 0;
  final _images = List.generate(3, (i) => i);

  @override
  Widget build(BuildContext context) {
    final part = widget.part;
    final r = Responsive(context);
    final currency = NumberFormat.currency(symbol: '\$');
    final inCart = context.watch<CartBloc>().state.contains(part.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.surfaceDark,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.9),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    '${part.imageUrl}&index=$_imageIndex',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.3)],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _images.map((i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _imageIndex == i ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: _imageIndex == i ? Colors.white : Colors.white54,
                            ),
                          )).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: EdgeInsets.fromLTRB(r.horizontalPadding(), 24, r.horizontalPadding(), 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ConditionChip(label: part.conditionLabel),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 16, color: AppColors.accent),
                              const SizedBox(width: 4),
                              Text(
                                part.sellerRating.toStringAsFixed(1),
                                style: AppTypography.textTheme.labelMedium?.copyWith(color: AppColors.warning),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(part.fullTitle, style: AppTypography.textTheme.displaySmall),
                    const SizedBox(height: 12),
                    Text(currency.format(part.price), style: AppTypography.priceLarge),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, AppRoutes.sellerProfile, arguments: part),
                      child: Container(
                        decoration: AppDecorations.card(radius: AppDecorations.radiusLg),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  part.sellerName[0],
                                  style: AppTypography.textTheme.titleMedium?.copyWith(color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(part.sellerName, style: AppTypography.textTheme.titleSmall),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_rounded, size: 14, color: AppColors.textTertiary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(part.location, style: AppTypography.textTheme.bodySmall),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Compatibility', style: AppTypography.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    ...part.compatibility.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.successSoft,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_rounded, size: 14, color: AppColors.success),
                              ),
                              const SizedBox(width: 10),
                              Text(c, style: AppTypography.textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary)),
                            ],
                          ),
                        )),
                    const SizedBox(height: 24),
                    Text('Description', style: AppTypography.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Text(part.description, style: AppTypography.textTheme.bodyMedium?.copyWith(height: 1.6)),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
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
            padding: EdgeInsets.fromLTRB(r.horizontalPadding(), 16, r.horizontalPadding(), 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.chatDetail),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text('Chat'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DecoratedBox(
                    decoration: inCart
                        ? BoxDecoration(
                            color: AppColors.successSoft,
                            borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                          )
                        : AppDecorations.premiumButton(),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (!inCart) context.read<CartBloc>().add(CartItemAdded(part));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(inCart ? 'Already in cart' : 'Added to cart ✓')),
                          );
                        },
                        borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                inCart ? Icons.check_circle_rounded : Icons.shopping_bag_rounded,
                                color: inCart ? AppColors.success : Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                inCart ? 'In Cart' : 'Add to Cart',
                                style: AppTypography.textTheme.labelLarge?.copyWith(
                                  color: inCart ? AppColors.success : Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
