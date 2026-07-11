import 'dart:io';

import 'package:spare_kart/data/models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateListingInput {
  const CreateListingInput({
    required this.name,
    required this.category,
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
    is_admin_listing,
    seller_rating,
    created_at,
    seller:profiles!seller_id (name),
    listing_images (url, sort_order),
    listing_compatibility (vehicle_label)
  ''';

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<Part>> fetchActiveListings() async {
    final rows = await _client
        .from('listings')
        .select(_listingSelect)
        .eq('status', 'active')
        .order('created_at', ascending: false);

    return _mapRows(rows);
  }

  Future<List<Part>> fetchSellerListings(String sellerId) async {
    final rows = await _client
        .from('listings')
        .select(_listingSelect)
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false);

    return _mapRows(rows);
  }

  Future<List<Part>> fetchSavedListings(String userId) async {
    final rows = await _client
        .from('saved_listings')
        .select('listings ($_listingSelect)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

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
    final listingRow = await _client
        .from('listings')
        .insert({
          'seller_id': sellerId,
          'name': input.name,
          'category': input.category,
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
        })
        .select(_listingSelect)
        .single();

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
    final rating = row['seller_rating'];

    return Part(
      id: row['id'] as String,
      name: row['name'] as String,
      category: row['category'] as String,
      make: row['make'] as String,
      model: row['model'] as String,
      year: (row['year'] as num).toInt(),
      condition: _conditionFromDb(row['condition'] as String),
      price: price is num ? price.toDouble() : 0,
      location: row['location'] as String? ?? '',
      sellerId: row['seller_id'] as String,
      sellerName: sellerName,
      sellerRating: rating is num ? rating.toDouble() : 4.8,
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
