import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spare_kart/core/router/app_routes.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/theme/app_decorations.dart';
import 'package:spare_kart/core/theme/app_typography.dart';
import 'package:spare_kart/core/utils/responsive.dart';
import 'package:spare_kart/core/widgets/listing_image.dart';
import 'package:spare_kart/core/widgets/part_card.dart';
import 'package:spare_kart/data/models/models.dart';
import 'package:spare_kart/data/models/seller_profile.dart';
import 'package:spare_kart/data/repositories/listings_repository.dart';
import 'package:spare_kart/data/repositories/seller_profile_repository.dart';

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({super.key, required this.part});

  final Part part;

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  final _profileRepository = SellerProfileRepository();
  final _listingsRepository = ListingsRepository();

  late Future<_SellerProfileData> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<_SellerProfileData> _loadProfile() async {
    final sellerId = widget.part.sellerId;
    await _profileRepository.refreshSellerStats(sellerId);
    final results = await Future.wait([
      _profileRepository.fetchStats(sellerId),
      _profileRepository.fetchReviews(sellerId),
      _listingsRepository.fetchSellerListings(sellerId, activeOnly: true),
    ]);
    return _SellerProfileData(
      stats: results[0] as SellerProfileStats,
      reviews: results[1] as List<SellerReview>,
      listings: results[2] as List<Part>,
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Seller Profile')),
      body: FutureBuilder<_SellerProfileData>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(r.horizontalPadding()),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.textTertiary),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load seller profile',
                      style: AppTypography.textTheme.titleSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => setState(() => _profileFuture = _loadProfile()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!;
          final stats = data.stats;
          final sellerName = stats.sellerName ?? widget.part.sellerName;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _profileFuture = _loadProfile());
              await _profileFuture;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(r.horizontalPadding()),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Center(
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        sellerName.isNotEmpty ? sellerName[0] : '?',
                        style: const TextStyle(fontSize: 36, color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      sellerName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (stats.hasRatings) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          Text(
                            ' ${stats.avgRating.toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            ' (${stats.ratingCount} ${stats.ratingCount == 1 ? 'rating' : 'ratings'})',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _StatCard(label: 'Listings', value: '${stats.listingsCount}'),
                      _StatCard(
                        label: 'Positive',
                        value: stats.hasRatings ? '${stats.positivePct}%' : '—',
                      ),
                      _StatCard(label: 'Orders', value: '${stats.ordersCount}'),
                    ],
                  ),
                  if (data.reviews.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Text(
                      'Reviews (${data.reviews.length})',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    ...data.reviews.map(
                      (review) => _ReviewCard(
                        review: review,
                        onItemTap: review.listingId == null
                            ? null
                            : () => _openListingFromReview(data.listings, review.listingId!),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Text(
                    'From This Seller (${data.listings.length})',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  if (data.listings.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No active listings',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ...data.listings.map(
                      (listing) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PartCard(
                          part: listing,
                          compact: true,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.productDetail,
                            arguments: listing,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openListingFromReview(List<Part> listings, String listingId) {
    for (final listing in listings) {
      if (listing.id == listingId) {
        Navigator.pushNamed(context, AppRoutes.productDetail, arguments: listing);
        return;
      }
    }
  }
}

class _SellerProfileData {
  const _SellerProfileData({
    required this.stats,
    required this.reviews,
    required this.listings,
  });

  final SellerProfileStats stats;
  final List<SellerReview> reviews;
  final List<Part> listings;
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
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, this.onItemTap});

  final SellerReview review;
  final VoidCallback? onItemTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: AppDecorations.card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    review.buyerName.isNotEmpty ? review.buyerName[0] : '?',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.buyerName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (review.createdAt != null)
                        Text(
                          DateFormat('d MMM yyyy').format(review.createdAt!.toLocal()),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppColors.warning,
                      size: 18,
                    );
                  }),
                ),
              ],
            ),
            if (review.reviewText?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Text(
                review.reviewText!,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
              ),
            ],
            if (review.listingTitle != null) ...[
              const SizedBox(height: 12),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onItemTap,
                  borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: AppColors.chipBg,
                      borderRadius: BorderRadius.circular(AppDecorations.radiusSm),
                      border: Border.all(color: AppColors.divider),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        if (review.listingImageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: ListingImage(
                              url: review.listingImageUrl!,
                              width: 44,
                              height: 44,
                            ),
                          )
                        else
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.divider,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.inventory_2_outlined, color: AppColors.textTertiary),
                          ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Item purchased',
                                style: AppTypography.textTheme.labelSmall?.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                              ),
                              Text(
                                review.listingTitle!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (onItemTap != null)
                          const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
