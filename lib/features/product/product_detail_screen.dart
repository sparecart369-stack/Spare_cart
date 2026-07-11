import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spare_kart/bloc/favourites/favourites_bloc.dart';
import 'package:spare_kart/core/router/app_routes.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/theme/app_decorations.dart';
import 'package:spare_kart/core/theme/app_typography.dart';
import 'package:spare_kart/core/utils/responsive.dart';
import 'package:spare_kart/core/widgets/common_widgets.dart';
import 'package:spare_kart/core/widgets/listing_image.dart';
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
    final isFavourite = context.watch<FavouritesBloc>().state.contains(part.id);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwnListing = currentUserId != null && currentUserId == part.sellerId;

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
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.black),
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
                    itemBuilder: (_, i) => ListingImage(
                      url: images[i],
                      fit: BoxFit.cover,
                      errorIconSize: 48,
                      errorIconColor: Colors.white.withValues(alpha: 0.5),
                      errorBackground: const BoxDecoration(gradient: AppColors.primaryGradient),
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
                    Text(
                      part.fullTitle,
                      style: AppTypography.textTheme.displaySmall,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    BlurredPrice(style: AppTypography.priceLarge),
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
                                  Text(
                                    part.sellerName,
                                    style: AppTypography.textTheme.titleSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_rounded, size: 14, color: AppColors.textTertiary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          part.displayLocation,
                                          style: AppTypography.textTheme.bodySmall,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
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
      bottomNavigationBar: _ProductDetailBottomBar(
        responsive: r,
        isOwnListing: isOwnListing,
        isFavourite: isFavourite,
        currentUserId: currentUserId,
        part: part,
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
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

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
          Expanded(
            child: Text(
              value,
              style: AppTypography.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductDetailBottomBar extends StatelessWidget {
  const _ProductDetailBottomBar({
    required this.responsive,
    required this.isOwnListing,
    required this.isFavourite,
    required this.currentUserId,
    required this.part,
  });

  final Responsive responsive;
  final bool isOwnListing;
  final bool isFavourite;
  final String? currentUserId;
  final Part part;

  @override
  Widget build(BuildContext context) {
    final width = responsive.width;
    final compact = width < 400;
    final tight = width < 340;

    final chatLabel = isOwnListing ? (tight ? 'Yours' : 'Your listing') : 'Chat';
    final favouriteLabel = isFavourite
        ? 'Saved'
        : tight
            ? 'Save'
            : compact
                ? 'Favourite'
                : 'Add to Favourites';

    final horizontalPadding = responsive.horizontalPadding();
    final gap = compact ? 8.0 : 12.0;
    final buttonPadding = EdgeInsets.symmetric(
      horizontal: compact ? 10 : 14,
      vertical: compact ? 14 : 16,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppDecorations.shadowNav,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 12),
          child: Row(
            children: [
              Expanded(
                flex: tight ? 2 : 3,
                child: _BottomBarButton(
                  outlined: true,
                  icon: Icons.chat_bubble_outline_rounded,
                  label: chatLabel,
                  showLabel: !tight || !isOwnListing,
                  padding: buttonPadding,
                  onTap: isOwnListing
                      ? null
                      : () => Navigator.pushNamed(
                            context,
                            AppRoutes.chatDetail,
                            arguments: ChatArgs(part: part),
                          ),
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                flex: tight ? 3 : 5,
                child: _BottomBarButton(
                  outlined: false,
                  icon: isFavourite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  label: favouriteLabel,
                  showLabel: true,
                  padding: buttonPadding,
                  onTap: () {
                    if (currentUserId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sign in to save favourites')),
                      );
                      return;
                    }
                    context.read<FavouritesBloc>().add(FavouriteToggled(part));
                    final saved = !isFavourite;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(saved ? 'Added to favourites ✓' : 'Removed from favourites'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBarButton extends StatelessWidget {
  const _BottomBarButton({
    required this.outlined,
    required this.icon,
    required this.label,
    required this.showLabel,
    required this.padding,
    this.onTap,
  });

  final bool outlined;
  final IconData icon;
  final String label;
  final bool showLabel;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTypography.textTheme.labelLarge?.copyWith(
      color: outlined ? AppColors.primary : Colors.white,
    );

    final child = Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: outlined
                ? (onTap == null ? AppColors.textTertiary : AppColors.primary)
                : Colors.white,
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: labelStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );

    if (outlined) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: child,
      );
    }

    return DecoratedBox(
      decoration: AppDecorations.premiumButton(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDecorations.radiusMd),
          child: child,
        ),
      ),
    );
  }
}
