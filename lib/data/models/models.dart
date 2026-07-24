import 'package:equatable/equatable.dart';

enum PartCondition { used, refurbished, newPart }

enum ListingFulfillment { doorstepDelivery, inStorePickup }

enum PickupLocationSource { current, other }

extension ListingFulfillmentX on ListingFulfillment {
  String get label => switch (this) {
        ListingFulfillment.doorstepDelivery => 'Doorstep Delivery',
        ListingFulfillment.inStorePickup => 'In-Store Pickup',
      };
}

enum OrderStatus { paid, shipped, delivered, cancelled }

class Part extends Equatable {
  const Part({
    required this.id,
    required this.name,
    required this.category,
    this.subcategory,
    required this.make,
    required this.model,
    required this.year,
    required this.condition,
    required this.price,
    required this.location,
    required this.sellerId,
    required this.sellerName,
    this.sellerRating = 0,
    this.sellerRatingCount = 0,
    required this.imageUrl,
    required this.description,
    this.imageUrls = const [],
    this.isAdminListing = false,
    this.compatibility = const [],
    this.fulfillment = ListingFulfillment.doorstepDelivery,
    this.chassisNumber,
    this.partNumber,
    this.isAvailable = true,
  });

  final String id;
  final String name;
  final String category;
  final String? subcategory;
  final String make;
  final String model;
  final int year;
  final PartCondition condition;
  final double price;
  final String location;
  final String sellerId;
  final String sellerName;
  final double sellerRating;
  final int sellerRatingCount;
  final String imageUrl;
  final String description;
  final List<String> imageUrls;
  final bool isAdminListing;
  final List<String> compatibility;
  final ListingFulfillment fulfillment;
  final String? chassisNumber;
  final String? partNumber;
  final bool isAvailable;

  List<String> get displayImages => imageUrls.isNotEmpty ? imageUrls : [imageUrl];

  String get fulfillmentLabel => fulfillment.label;

  String get displayLocation => switch (fulfillment) {
        ListingFulfillment.doorstepDelivery => fulfillmentLabel,
        ListingFulfillment.inStorePickup => location,
      };

  String? get locationDistrict {
    final parsed = _parseDistrictState();
    return parsed.$1;
  }

  String? get locationState {
    final parsed = _parseDistrictState();
    return parsed.$2;
  }

  (String?, String?) _parseDistrictState() {
    final trimmed = location.trim();
    if (trimmed.isEmpty) return (null, null);

    final parts = trimmed
        .split(',')
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (parts.isEmpty) return (null, null);

    if (fulfillment == ListingFulfillment.doorstepDelivery) {
      if (parts.length >= 2) return (parts[0], parts[1]);
      return (parts[0], null);
    }

    if (parts.length >= 2) {
      return (parts[parts.length - 2], parts[parts.length - 1]);
    }
    return (parts[0], null);
  }

  String get fullTitle => '$name $make $model $year';

  bool get hasSellerRatings => sellerRatingCount > 0;

  String get conditionLabel {
    switch (condition) {
      case PartCondition.used:
        return 'Used - Tested';
      case PartCondition.refurbished:
        return 'Refurbished';
      case PartCondition.newPart:
        return 'New';
    }
  }

  String? get subcategoryLabel {
    if (subcategory == null || subcategory!.isEmpty) return null;
    return subcategory;
  }

  Part copyWith({
    String? id,
    String? name,
    String? category,
    String? subcategory,
    String? make,
    String? model,
    int? year,
    PartCondition? condition,
    double? price,
    String? location,
    String? sellerId,
    String? sellerName,
    double? sellerRating,
    int? sellerRatingCount,
    String? imageUrl,
    String? description,
    List<String>? imageUrls,
    bool? isAdminListing,
    List<String>? compatibility,
    ListingFulfillment? fulfillment,
    String? chassisNumber,
    String? partNumber,
    bool? isAvailable,
  }) {
    return Part(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      condition: condition ?? this.condition,
      price: price ?? this.price,
      location: location ?? this.location,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerRating: sellerRating ?? this.sellerRating,
      sellerRatingCount: sellerRatingCount ?? this.sellerRatingCount,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      isAdminListing: isAdminListing ?? this.isAdminListing,
      compatibility: compatibility ?? this.compatibility,
      fulfillment: fulfillment ?? this.fulfillment,
      chassisNumber: chassisNumber ?? this.chassisNumber,
      partNumber: partNumber ?? this.partNumber,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  @override
  List<Object?> get props => [id];
}

class CartItem extends Equatable {
  const CartItem({required this.part, this.quantity = 1});

  final Part part;
  final int quantity;

  double get total => part.price * quantity;

  CartItem copyWith({int? quantity}) =>
      CartItem(part: part, quantity: quantity ?? this.quantity);

  @override
  List<Object?> get props => [part.id, quantity];
}

class Order extends Equatable {
  const Order({
    required this.id,
    required this.items,
    required this.status,
    required this.date,
    required this.total,
    required this.trackingNumber,
  });

  final String id;
  final List<CartItem> items;
  final OrderStatus status;
  final DateTime date;
  final double total;
  final String trackingNumber;

  String get statusLabel {
    switch (status) {
      case OrderStatus.paid:
        return 'Paid';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  List<Object?> get props => [id];
}

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;

  @override
  List<Object?> get props => [id];
}

class MessageThread extends Equatable {
  const MessageThread({
    required this.id,
    required this.participantName,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
    required this.partTitle,
  });

  final String id;
  final String participantName;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;
  final String partTitle;

  @override
  List<Object?> get props => [
        id,
        participantName,
        lastMessage,
        timestamp,
        unreadCount,
        partTitle,
      ];
}

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.imagePath,
    this.senderId,
  });

  final String id;
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final String? imagePath;
  final String? senderId;

  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  @override
  List<Object?> get props => [id];
}

class SellerBankAccount extends Equatable {
  const SellerBankAccount({
    required this.upiId,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.ifscCode,
  });

  final String upiId;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final String ifscCode;

  bool get isComplete =>
      upiId.trim().isNotEmpty &&
      bankName.trim().isNotEmpty &&
      accountNumber.trim().isNotEmpty &&
      accountName.trim().isNotEmpty &&
      ifscCode.trim().isNotEmpty;

  SellerBankAccount copyWith({
    String? upiId,
    String? bankName,
    String? accountNumber,
    String? accountName,
    String? ifscCode,
  }) =>
      SellerBankAccount(
        upiId: upiId ?? this.upiId,
        bankName: bankName ?? this.bankName,
        accountNumber: accountNumber ?? this.accountNumber,
        accountName: accountName ?? this.accountName,
        ifscCode: ifscCode ?? this.ifscCode,
      );

  @override
  List<Object?> get props => [upiId, bankName, accountNumber, accountName, ifscCode];
}

class OperatingCountriesSelection extends Equatable {
  const OperatingCountriesSelection({
    this.countryCodes = const ['IN'],
    this.operatesGlobally = false,
  });

  final List<String> countryCodes;
  final bool operatesGlobally;

  bool get isValid => operatesGlobally || countryCodes.isNotEmpty;

  OperatingCountriesSelection copyWith({
    List<String>? countryCodes,
    bool? operatesGlobally,
  }) =>
      OperatingCountriesSelection(
        countryCodes: countryCodes ?? this.countryCodes,
        operatesGlobally: operatesGlobally ?? this.operatesGlobally,
      );

  @override
  List<Object?> get props => [countryCodes, operatesGlobally];
}

class UserProfile extends Equatable {
  const UserProfile({
    required this.name,
    required this.phone,
    this.listings = 0,
    this.positiveFeedback = 98,
    this.orders = 0,
    this.bankAccount,
    this.operatingCountries = const [],
    this.operatesGlobally = false,
  });

  final String name;
  final String phone;
  final int listings;
  final int positiveFeedback;
  final int orders;
  final SellerBankAccount? bankAccount;
  final List<String> operatingCountries;
  final bool operatesGlobally;

  OperatingCountriesSelection get operatingCountriesSelection =>
      OperatingCountriesSelection(
        countryCodes: operatingCountries,
        operatesGlobally: operatesGlobally,
      );

  UserProfile copyWith({
    String? name,
    String? phone,
    int? listings,
    int? positiveFeedback,
    int? orders,
    SellerBankAccount? bankAccount,
    List<String>? operatingCountries,
    bool? operatesGlobally,
  }) =>
      UserProfile(
        name: name ?? this.name,
        phone: phone ?? this.phone,
        listings: listings ?? this.listings,
        positiveFeedback: positiveFeedback ?? this.positiveFeedback,
        orders: orders ?? this.orders,
        bankAccount: bankAccount ?? this.bankAccount,
        operatingCountries: operatingCountries ?? this.operatingCountries,
        operatesGlobally: operatesGlobally ?? this.operatesGlobally,
      );

  @override
  List<Object?> get props => [
        name,
        phone,
        listings,
        positiveFeedback,
        orders,
        bankAccount,
        operatingCountries,
        operatesGlobally,
      ];
}
