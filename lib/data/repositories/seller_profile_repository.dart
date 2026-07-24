import 'package:spare_kart/data/models/seller_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SellerProfileRepository {
  SellerProfileRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<void> refreshSellerStats(String sellerId) async {
    try {
      await _client.rpc(
        'refresh_seller_rating_stats',
        params: {'p_seller_id': sellerId},
      );
    } catch (_) {
      // Optional until migration is applied.
    }
  }

  Future<SellerProfileStats> fetchStats(String sellerId) async {
    final result = await _client.rpc(
      'fetch_seller_profile_stats',
      params: {'p_seller_id': sellerId},
    );
    if (result is! Map<String, dynamic>) {
      return const SellerProfileStats(
        ratingCount: 0,
        avgRating: 0,
        positivePct: 0,
        listingsCount: 0,
        ordersCount: 0,
      );
    }
    return SellerProfileStats.fromJson(result);
  }

  Future<List<SellerReview>> fetchReviews(String sellerId) async {
    final result = await _client.rpc(
      'fetch_seller_reviews',
      params: {'p_seller_id': sellerId},
    );
    if (result is! List) return const [];
    return result
        .whereType<Map<String, dynamic>>()
        .map(SellerReview.fromJson)
        .toList();
  }
}
