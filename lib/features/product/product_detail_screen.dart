import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spare_kart/bloc/cart/cart_bloc.dart';
import 'package:spare_kart/core/constants/app_commission.dart';
import 'package:spare_kart/core/utils/app_currency.dart';
import 'package:spare_kart/core/router/app_routes.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/theme/app_decorations.dart';
import 'package:spare_kart/core/theme/app_typography.dart';
import 'package:spare_kart/core/utils/responsive.dart';
import 'package:spare_kart/core/widgets/common_widgets.dart';
import 'package:spare_kart/data/models/models.dart';
import 'package:spare_kart/features/messages/chat_detail_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.part});

  final Part part;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _imageIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final part = widget.part;
    final images = part.displayImages;
    final r = Responsive(context);
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
                  PageView.builder(
                    controller: _pageController,
                    itemCount: images.length,
                    onPageChanged: (i) => setState(() => _imageIndex = i),
                    itemBuilder: (_, i) => Image.network(
                      images[i],
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            color: Colors.white.withValues(alpha: 0.5),
                            size: 48,
                          ),
                        ),
                      ),
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
                  if (images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length, (i) => GestureDetector(
                              onTap: () {
                                setState(() => _imageIndex = i);
                                _pageController.animateToPage(
                                  i,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                );
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: _imageIndex == i ? 24 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: _imageIndex == i ? Colors.white : Colors.white54,
                                ),
                              ),
                            )),
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
                    Text(AppCurrency.format(part.price), style: AppTypography.priceLarge),
                    const SizedBox(height: 20),
                    _DetailSection(
                      title: 'Part Info',
                      children: [
                        _DetailRow(label: 'Category', value: part.category),
                        _DetailRow(label: 'Make', value: part.make),
                        _DetailRow(label: 'Model', value: part.model),
                        _DetailRow(label: 'Year', value: '${part.year}'),
                        _DetailRow(label: 'Condition', value: part.conditionLabel),
                      ],
                    ),
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
                    if (part.isAdminListing) ...[
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Seller Earnings', style: AppTypography.textTheme.titleSmall),
                            const SizedBox(height: 10),
                            _DetailRow(
                              label: 'Listing price',
                              value: AppCurrency.format(part.price),
                            ),
                            _DetailRow(
                              label: 'Convenience fee (${AppCommission.percent.toStringAsFixed(0)}%)',
                              value: AppCurrency.format(AppCommission.fee(part.price)),
                            ),
                            const Divider(height: 20),
                            _DetailRow(
                              label: 'You receive',
                              value: AppCurrency.format(AppCommission.sellerEarnings(part.price)),
                              emphasized: true,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.schedule_rounded, size: 16, color: AppColors.primary.withValues(alpha: 0.8)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    AppCommission.payoutScheduleMessage,
                                    style: AppTypography.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.chatDetail,
                      arguments: ChatArgs(part: part),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                    label: const Text('Chat'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DecoratedBox(
                    decoration: AppDecorations.premiumButton(),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (inCart) {
                            Navigator.pushNamed(context, AppRoutes.checkout);
                            return;
                          }
                          context.read<CartBloc>().add(CartItemAdded(part));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Added to cart ✓')),
                          );
                        },
                        borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                inCart ? Icons.shopping_cart_checkout_rounded : Icons.shopping_bag_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                inCart ? 'Checkout' : 'Add to Cart',
                                style: AppTypography.textTheme.labelLarge?.copyWith(
                                  color: Colors.white,
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

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.textTheme.titleMedium),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: AppDecorations.card(radius: AppDecorations.radiusMd),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.emphasized = false});

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: emphasized
                ? AppTypography.textTheme.titleSmall?.copyWith(color: AppColors.primary)
                : AppTypography.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
