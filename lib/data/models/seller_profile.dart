class SellerProfileStats {
  const SellerProfileStats({
    required this.ratingCount,
    required this.avgRating,
    required this.positivePct,
    required this.listingsCount,
    required this.ordersCount,
    this.sellerName,
  });

  final int ratingCount;
  final double avgRating;
  final int positivePct;
  final int listingsCount;
  final int ordersCount;
  final String? sellerName;

  bool get hasRatings => ratingCount > 0;

  factory SellerProfileStats.fromJson(Map<String, dynamic> json) {
    return SellerProfileStats(
      ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0,
      positivePct: (json['positive_pct'] as num?)?.toInt() ?? 0,
      listingsCount: (json['listings_count'] as num?)?.toInt() ?? 0,
      ordersCount: (json['orders_count'] as num?)?.toInt() ?? 0,
      sellerName: json['seller_name'] as String?,
    );
  }
}

class SellerReview {
  const SellerReview({
    required this.id,
    required this.rating,
    required this.buyerName,
    this.reviewText,
    this.createdAt,
    this.listingId,
    this.listingName,
    this.listingMake,
    this.listingModel,
    this.listingYear,
    this.listingImageUrl,
  });

  final String id;
  final int rating;
  final String buyerName;
  final String? reviewText;
  final DateTime? createdAt;
  final String? listingId;
  final String? listingName;
  final String? listingMake;
  final String? listingModel;
  final int? listingYear;
  final String? listingImageUrl;

  String? get listingTitle {
    if (listingName == null) return null;
    final parts = [
      listingName,
      if (listingMake != null && listingMake!.isNotEmpty) listingMake,
      if (listingModel != null && listingModel!.isNotEmpty) listingModel,
      if (listingYear != null) listingYear.toString(),
    ];
    return parts.join(' ');
  }

  factory SellerReview.fromJson(Map<String, dynamic> json) {
    return SellerReview(
      id: json['id'] as String,
      rating: json['rating'] as int,
      buyerName: json['buyer_name'] as String? ?? 'Buyer',
      reviewText: json['review_text'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      listingId: json['listing_id'] as String?,
      listingName: json['listing_name'] as String?,
      listingMake: json['listing_make'] as String?,
      listingModel: json['listing_model'] as String?,
      listingYear: (json['listing_year'] as num?)?.toInt(),
      listingImageUrl: json['listing_image_url'] as String?,
    );
  }
}
