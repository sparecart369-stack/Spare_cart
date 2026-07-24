enum ChatFulfillmentMode {
  doorstep,
  pickup;

  static ChatFulfillmentMode fromStorage(String? value) {
    switch (value) {
      case 'pickup':
        return ChatFulfillmentMode.pickup;
      default:
        return ChatFulfillmentMode.doorstep;
    }
  }

  String get storageValue => name;
}

enum ChatTransactionStatus {
  pendingHandoff,
  dispatched,
  buyerConfirmed,
  sellerConfirmed,
  completed,
  dispute,
  refundRequested;

  static ChatTransactionStatus fromStorage(String? value) {
    switch (value) {
      case 'dispatched':
        return ChatTransactionStatus.dispatched;
      case 'buyer_confirmed':
        return ChatTransactionStatus.buyerConfirmed;
      case 'seller_confirmed':
        return ChatTransactionStatus.sellerConfirmed;
      case 'completed':
        return ChatTransactionStatus.completed;
      case 'dispute':
        return ChatTransactionStatus.dispute;
      case 'refund_requested':
        return ChatTransactionStatus.refundRequested;
      default:
        return ChatTransactionStatus.pendingHandoff;
    }
  }

  String get storageValue => switch (this) {
        ChatTransactionStatus.pendingHandoff => 'pending_handoff',
        ChatTransactionStatus.dispatched => 'dispatched',
        ChatTransactionStatus.buyerConfirmed => 'buyer_confirmed',
        ChatTransactionStatus.sellerConfirmed => 'seller_confirmed',
        ChatTransactionStatus.completed => 'completed',
        ChatTransactionStatus.dispute => 'dispute',
        ChatTransactionStatus.refundRequested => 'refund_requested',
      };
}

class ChatTransaction {
  const ChatTransaction({
    required this.id,
    required this.threadId,
    required this.buyerId,
    required this.sellerId,
    required this.fulfillmentMode,
    required this.agreedPrice,
    required this.tokenAmount,
    required this.remainingAmount,
    required this.status,
    this.advancePaymentId,
    this.deliveryPartnerName,
    this.disputeReason,
    this.sellerDispatchedAt,
    this.buyerConfirmedAt,
    this.sellerConfirmedAt,
    this.completedAt,
    this.refundRequestedAt,
    this.createdAt,
  });

  final String id;
  final String threadId;
  final String buyerId;
  final String sellerId;
  final String? advancePaymentId;
  final ChatFulfillmentMode fulfillmentMode;
  final double agreedPrice;
  final double tokenAmount;
  final double remainingAmount;
  final ChatTransactionStatus status;
  final String? deliveryPartnerName;
  final String? disputeReason;
  final DateTime? sellerDispatchedAt;
  final DateTime? buyerConfirmedAt;
  final DateTime? sellerConfirmedAt;
  final DateTime? completedAt;
  final DateTime? refundRequestedAt;
  final DateTime? createdAt;

  bool get isDoorstep => fulfillmentMode == ChatFulfillmentMode.doorstep;
  bool get isPickup => fulfillmentMode == ChatFulfillmentMode.pickup;
  bool get isCompleted => status == ChatTransactionStatus.completed;
  bool get isDispute =>
      status == ChatTransactionStatus.dispute ||
      status == ChatTransactionStatus.refundRequested;

  factory ChatTransaction.fromJson(Map<String, dynamic> json) {
    return ChatTransaction(
      id: json['id'] as String,
      threadId: json['thread_id'] as String,
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_id'] as String,
      advancePaymentId: json['advance_payment_id'] as String?,
      fulfillmentMode: ChatFulfillmentMode.fromStorage(
        json['fulfillment_mode'] as String?,
      ),
      agreedPrice: (json['agreed_price'] as num).toDouble(),
      tokenAmount: (json['token_amount'] as num).toDouble(),
      remainingAmount: (json['remaining_amount'] as num).toDouble(),
      status: ChatTransactionStatus.fromStorage(json['status'] as String?),
      deliveryPartnerName: json['delivery_partner_name'] as String?,
      disputeReason: json['dispute_reason'] as String?,
      sellerDispatchedAt: _parseDate(json['seller_dispatched_at']),
      buyerConfirmedAt: _parseDate(json['buyer_confirmed_at']),
      sellerConfirmedAt: _parseDate(json['seller_confirmed_at']),
      completedAt: _parseDate(json['completed_at']),
      refundRequestedAt: _parseDate(json['refund_requested_at']),
      createdAt: _parseDate(json['created_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class DeliveryPartnerRating {
  const DeliveryPartnerRating({
    required this.id,
    required this.transactionId,
    required this.threadId,
    required this.buyerId,
    required this.sellerId,
    required this.deliveryPartnerName,
    required this.rating,
    this.reviewText,
    this.createdAt,
  });

  final String id;
  final String transactionId;
  final String threadId;
  final String buyerId;
  final String sellerId;
  final String deliveryPartnerName;
  final int rating;
  final String? reviewText;
  final DateTime? createdAt;

  factory DeliveryPartnerRating.fromJson(Map<String, dynamic> json) {
    return DeliveryPartnerRating(
      id: json['id'] as String,
      transactionId: json['transaction_id'] as String,
      threadId: json['thread_id'] as String,
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_id'] as String,
      deliveryPartnerName: json['delivery_partner_name'] as String,
      rating: json['rating'] as int,
      reviewText: json['review_text'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}
