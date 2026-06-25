import 'package:equatable/equatable.dart';

enum PartCondition { used, refurbished, newPart }

enum OrderStatus { paid, shipped, delivered, cancelled }

class Part extends Equatable {
  const Part({
    required this.id,
    required this.name,
    required this.category,
    required this.make,
    required this.model,
    required this.year,
    required this.condition,
    required this.price,
    required this.location,
    required this.sellerId,
    required this.sellerName,
    required this.sellerRating,
    required this.imageUrl,
    required this.description,
    this.imageUrls = const [],
    this.isAdminListing = false,
    this.compatibility = const [],
  });

  final String id;
  final String name;
  final String category;
  final String make;
  final String model;
  final int year;
  final PartCondition condition;
  final double price;
  final String location;
  final String sellerId;
  final String sellerName;
  final double sellerRating;
  final String imageUrl;
  final String description;
  final List<String> imageUrls;
  final bool isAdminListing;
  final List<String> compatibility;

  List<String> get displayImages => imageUrls.isNotEmpty ? imageUrls : [imageUrl];

  String get fullTitle => '$name $make $model $year';

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

  Part copyWith({
    String? id,
    String? name,
    String? category,
    String? make,
    String? model,
    int? year,
    PartCondition? condition,
    double? price,
    String? location,
    String? sellerId,
    String? sellerName,
    double? sellerRating,
    String? imageUrl,
    String? description,
    List<String>? imageUrls,
    bool? isAdminListing,
    List<String>? compatibility,
  }) {
    return Part(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      condition: condition ?? this.condition,
      price: price ?? this.price,
      location: location ?? this.location,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerRating: sellerRating ?? this.sellerRating,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      imageUrls: imageUrls ?? this.imageUrls,
      isAdminListing: isAdminListing ?? this.isAdminListing,
      compatibility: compatibility ?? this.compatibility,
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
  List<Object?> get props => [id];
}

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
  });

  final String id;
  final String text;
  final bool isMe;
  final DateTime timestamp;

  @override
  List<Object?> get props => [id];
}

class UserProfile extends Equatable {
  const UserProfile({
    required this.name,
    required this.phone,
    this.listings = 0,
    this.positiveFeedback = 98,
    this.orders = 0,
  });

  final String name;
  final String phone;
  final int listings;
  final int positiveFeedback;
  final int orders;

  @override
  List<Object?> get props => [phone];
}
