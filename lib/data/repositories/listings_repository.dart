import 'dart:io';

import 'package:spare_kart/data/models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateListingInput {
  const CreateListingInput({
    required this.name,
    required this.category,
    this.subcategory,
    required this.make,
    required this.model,
    required this.year,
    required this.condition,
    required this.description,
    required this.fulfillment,
    required this.location,
    this.pickupAddress,
    this.localPhotoPaths = const [],
    this.compatibility = const [],
    this.chassisNumber,
    this.partNumber,
  });

  final String name;
  final String category;
  final String? subcategory;
  final String make;
  final String model;
  final int year;
  final PartCondition condition;
  final String description;
  final ListingFulfillment fulfillment;
  final String location;
  final String? pickupAddress;
  final List<String> localPhotoPaths;
  final List<String> compatibility;
  final String? chassisNumber;
  final String? partNumber;
}

class ListingsRepository {
  ListingsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _listingSelect = '''
    id,
    seller_id,
    name,
    category,
    subcategory,
    make,
    model,
    year,
    condition,
    price,
    location,
    description,
    fulfillment,
    pickup_address,
    chassis_number,
    part_number,
    status,
    is_available,
    is_admin_listing,
    created_at,
    seller:profiles!seller_id (
      name,
      seller_avg_rating,
      seller_rating_count
    ),
    listing_images (url, sort_order),
    listing_compatibility (vehicle_label)
  ''';

  static const _listingSelectBase = '''
    id,
    seller_id,
    name,
    category,
    subcategory,
    make,
    model,
    year,
    condition,
    price,
    location,
    description,
    fulfillment,
    pickup_address,
    chassis_number,
    part_number,
    status,
    is_available,
    is_admin_listing,
    created_at,
    seller:profiles!seller_id (name),
    listing_images (url, sort_order),
    listing_compatibility (vehicle_label)
  ''';

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<dynamic> _queryListingRows({
    required Future<dynamic> Function(String select) buildQuery,
  }) async {
    try {
      return await buildQuery(_listingSelect);
    } on PostgrestException catch (e) {
      if (!_isMissingSellerRatingColumnError(e)) rethrow;
      return await buildQuery(_listingSelectBase);
    }
  }

  bool _isMissingSellerRatingColumnError(PostgrestException e) {
    final message = '${e.message} ${e.details} ${e.hint}'.toLowerCase();
    return e.code == '42703' ||
        e.code == 'PGRST204' ||
        message.contains('seller_avg_rating') ||
        message.contains('seller_rating_count');
  }

  bool _isMissingSubcategoryColumnError(PostgrestException e) {
    final message = '${e.message} ${e.details} ${e.hint}'.toLowerCase();
    return e.code == '42703' ||
        e.code == 'PGRST204' ||
        message.contains('subcategory');
  }

  bool _isMissingAvailabilityColumnError(PostgrestException e) {
    final message = '${e.message} ${e.details} ${e.hint}'.toLowerCase();
    return e.code == '42703' ||
        e.code == 'PGRST204' ||
        message.contains('is_available');
  }

  Future<List<Part>> fetchActiveListings() async {
    try {
      final rows = await _queryListingRows(
        buildQuery: (select) => _client
            .from('listings')
            .select(select)
            .eq('status', 'active')
            .eq('is_available', true)
            .order('created_at', ascending: false),
      );
      return _mapRows(rows);
    } on PostgrestException catch (e) {
      if (!_isMissingAvailabilityColumnError(e)) rethrow;
      final rows = await _queryListingRows(
        buildQuery: (select) => _client
            .from('listings')
            .select(select)
            .eq('status', 'active')
            .order('created_at', ascending: false),
      );
      return _mapRows(rows);
    }
  }

  Future<Part?> fetchListingById(String listingId) async {
    try {
      final row = await _client
          .from('listings')
          .select(_listingSelect)
          .eq('id', listingId)
          .maybeSingle();
      if (row == null) return null;
      return _mapRow(row);
    } on PostgrestException catch (e) {
      if (!_isMissingSellerRatingColumnError(e)) rethrow;
      final row = await _client
          .from('listings')
          .select(_listingSelectBase)
          .eq('id', listingId)
          .maybeSingle();
      if (row == null) return null;
      return _mapRow(row);
    }
  }

  Future<List<Part>> fetchSellerListings(
    String sellerId, {
    bool activeOnly = false,
  }) async {
    try {
      final rows = await _queryListingRows(
        buildQuery: (select) {
          var query = _client
              .from('listings')
              .select(select)
              .eq('seller_id', sellerId);
          if (activeOnly) {
            query = query.eq('status', 'active').eq('is_available', true);
          }
          return query.order('created_at', ascending: false);
        },
      );
      return _mapRows(rows);
    } on PostgrestException catch (e) {
      if (!activeOnly || !_isMissingAvailabilityColumnError(e)) rethrow;
      final rows = await _queryListingRows(
        buildQuery: (select) => _client
            .from('listings')
            .select(select)
            .eq('seller_id', sellerId)
            .eq('status', 'active')
            .order('created_at', ascending: false),
      );
      return _mapRows(rows);
    }
  }

  Future<List<Part>> fetchSavedListings(String userId) async {
    dynamic rows;
    try {
      rows = await _client
          .from('saved_listings')
          .select('listings ($_listingSelect)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
    } on PostgrestException catch (e) {
      if (!_isMissingSellerRatingColumnError(e)) rethrow;
      rows = await _client
          .from('saved_listings')
          .select('listings ($_listingSelectBase)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
    }

    return rows
        .whereType<Map<String, dynamic>>()
        .map((row) {
          final listing = row['listings'];
          if (listing is Map<String, dynamic>) return _mapRow(listing);
          return null;
        })
        .whereType<Part>()
        .toList();
  }

  Future<void> saveListing(String userId, String listingId) async {
    await _client.from('saved_listings').upsert({
      'user_id': userId,
      'listing_id': listingId,
    });
  }

  Future<void> unsaveListing(String userId, String listingId) async {
    await _client
        .from('saved_listings')
        .delete()
        .eq('user_id', userId)
        .eq('listing_id', listingId);
  }

  Future<Part> createListing({
    required String sellerId,
    required String sellerName,
    required CreateListingInput input,
  }) async {
    final insertPayload = {
      'seller_id': sellerId,
      'name': input.name,
      'category': input.category,
      if (input.subcategory != null && input.subcategory!.isNotEmpty)
        'subcategory': input.subcategory,
      'make': input.make,
      'model': input.model,
      'year': input.year,
      'condition': _conditionToDb(input.condition),
      'price': 0,
      'location': input.location,
      'description': input.description,
      'fulfillment': _fulfillmentToDb(input.fulfillment),
      'pickup_address': input.pickupAddress,
      'chassis_number': _nullableTrimmed(input.chassisNumber),
      'part_number': _nullableTrimmed(input.partNumber),
      'status': 'active',
      'is_admin_listing': true,
    };

    dynamic listingRow;
    try {
      listingRow = await _client
          .from('listings')
          .insert(insertPayload)
          .select(_listingSelect)
          .single();
    } on PostgrestException catch (e) {
      if (!_isMissingSubcategoryColumnError(e)) rethrow;
      final fallbackPayload = Map<String, dynamic>.from(insertPayload)
        ..remove('subcategory');
      listingRow = await _client
          .from('listings')
          .insert(fallbackPayload)
          .select(_listingSelect)
          .single();
    }

    final listingId = listingRow['id'] as String;

    final imageUrls = <String>[];
    for (var i = 0; i < input.localPhotoPaths.length; i++) {
      final url = await _uploadListingImage(
        sellerId: sellerId,
        listingId: listingId,
        localPath: input.localPhotoPaths[i],
        index: i,
      );
      imageUrls.add(url);
    }

    if (imageUrls.isNotEmpty) {
      await _client.from('listing_images').insert(
            imageUrls
                .asMap()
                .entries
                .map(
                  (entry) => {
                    'listing_id': listingId,
                    'url': entry.value,
                    'sort_order': entry.key,
                  },
                )
                .toList(),
          );
      listingRow['listing_images'] = imageUrls
          .asMap()
          .entries
          .map(
            (entry) => {
              'url': entry.value,
              'sort_order': entry.key,
            },
          )
          .toList();
    }

    if (input.compatibility.isNotEmpty) {
      await _client.from('listing_compatibility').insert(
            input.compatibility
                .map(
                  (label) => {
                    'listing_id': listingId,
                    'vehicle_label': label,
                  },
                )
                .toList(),
          );
      listingRow['listing_compatibility'] = input.compatibility
          .map((label) => {'vehicle_label': label})
          .toList();
    }

    if (listingRow['seller'] == null) {
      listingRow['seller'] = {'name': sellerName};
    }

    return _mapRow(listingRow);
  }

  Future<void> updateListingAvailability({
    required String listingId,
    required bool isAvailable,
  }) async {
    await _client
        .from('listings')
        .update({'is_available': isAvailable})
        .eq('id', listingId);
  }

  Future<void> refreshSellerRatingStats(String sellerId) async {
    try {
      await _client.rpc(
        'refresh_seller_rating_stats',
        params: {'p_seller_id': sellerId},
      );
    } catch (_) {
      // Optional until migration is applied.
    }
  }

  Future<String> _uploadListingImage({
    required String sellerId,
    required String listingId,
    required String localPath,
    required int index,
  }) async {
    final file = File(localPath);
    final ext = _extensionForPath(localPath);
    final objectPath =
        '$sellerId/$listingId/${index}_${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from('listing-images').upload(
          objectPath,
          file,
          fileOptions: FileOptions(
            contentType: _mimeForExtension(ext),
            upsert: true,
          ),
        );

    return _client.storage.from('listing-images').getPublicUrl(objectPath);
  }

  List<Part> _mapRows(dynamic rows) {
    if (rows is! List) return const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(_mapRow)
        .toList();
  }

  Part _mapRow(Map<String, dynamic> row) {
    final seller = row['seller'];
    final sellerName = seller is Map<String, dynamic>
        ? (seller['name'] as String? ?? 'Seller')
        : 'Seller';

    final images = _sortedImageUrls(row['listing_images']);
    final compatibility = _compatibilityLabels(row['listing_compatibility']);

    final price = row['price'];
    final sellerRatingCount = seller is Map<String, dynamic>
        ? (seller['seller_rating_count'] as num?)?.toInt() ?? 0
        : 0;
    final sellerAvgRating = seller is Map<String, dynamic>
        ? (seller['seller_avg_rating'] as num?)?.toDouble() ?? 0.0
        : 0.0;

    return Part(
      id: row['id'] as String,
      name: row['name'] as String,
      category: row['category'] as String,
      subcategory: row['subcategory'] as String?,
      make: row['make'] as String,
      model: row['model'] as String,
      year: (row['year'] as num).toInt(),
      condition: _conditionFromDb(row['condition'] as String),
      price: price is num ? price.toDouble() : 0,
      location: row['location'] as String? ?? '',
      sellerId: row['seller_id'] as String,
      sellerName: sellerName,
      sellerRating: sellerRatingCount > 0 ? sellerAvgRating : 0.0,
      sellerRatingCount: sellerRatingCount,
      imageUrl: images.isNotEmpty
          ? images.first
          : 'https://picsum.photos/seed/${row['id']}/400/300',
      imageUrls: images,
      description: row['description'] as String? ?? '',
      isAdminListing: row['is_admin_listing'] as bool? ?? false,
      compatibility: compatibility,
      fulfillment: _fulfillmentFromDb(row['fulfillment'] as String),
      chassisNumber: row['chassis_number'] as String?,
      partNumber: row['part_number'] as String?,
      isAvailable: row['is_available'] as bool? ?? true,
    );
  }

  String? _nullableTrimmed(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  List<String> _sortedImageUrls(dynamic value) {
    if (value is! List) return const [];
    final images = value.whereType<Map<String, dynamic>>().toList()
      ..sort(
        (a, b) => ((a['sort_order'] as num?) ?? 0)
            .compareTo((b['sort_order'] as num?) ?? 0),
      );
    return images
        .map((image) => image['url'] as String?)
        .whereType<String>()
        .where((url) => url.isNotEmpty)
        .toList();
  }

  List<String> _compatibilityLabels(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map((row) => row['vehicle_label'] as String?)
        .whereType<String>()
        .toList();
  }

  String _conditionToDb(PartCondition condition) => switch (condition) {
        PartCondition.used => 'used',
        PartCondition.refurbished => 'refurbished',
        PartCondition.newPart => 'new_part',
      };

  PartCondition _conditionFromDb(String value) => switch (value) {
        'refurbished' => PartCondition.refurbished,
        'new_part' => PartCondition.newPart,
        _ => PartCondition.used,
      };

  String _fulfillmentToDb(ListingFulfillment fulfillment) => switch (fulfillment) {
        ListingFulfillment.doorstepDelivery => 'doorstep_delivery',
        ListingFulfillment.inStorePickup => 'in_store_pickup',
      };

  ListingFulfillment _fulfillmentFromDb(String value) => switch (value) {
        'in_store_pickup' => ListingFulfillment.inStorePickup,
        _ => ListingFulfillment.doorstepDelivery,
      };

  String _extensionForPath(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return 'jpg';
    return path.substring(dot + 1).toLowerCase();
  }

  String _mimeForExtension(String ext) => switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
}
