enum ChatPaymentStatus {
  pending,
  paid,
  failed,
  refundRequested,
  refunded;

  static ChatPaymentStatus fromStorage(String? value) {
    switch (value) {
      case 'paid':
        return ChatPaymentStatus.paid;
      case 'failed':
        return ChatPaymentStatus.failed;
      case 'refund_requested':
        return ChatPaymentStatus.refundRequested;
      case 'refunded':
        return ChatPaymentStatus.refunded;
      default:
        return ChatPaymentStatus.pending;
    }
  }

  String get storageValue => switch (this) {
        ChatPaymentStatus.pending => 'pending',
        ChatPaymentStatus.paid => 'paid',
        ChatPaymentStatus.failed => 'failed',
        ChatPaymentStatus.refundRequested => 'refund_requested',
        ChatPaymentStatus.refunded => 'refunded',
      };

  String get label => switch (this) {
        ChatPaymentStatus.pending => 'Pending',
        ChatPaymentStatus.paid => 'Paid',
        ChatPaymentStatus.failed => 'Failed',
        ChatPaymentStatus.refundRequested => 'Refund requested',
        ChatPaymentStatus.refunded => 'Refunded',
      };
}

class ChatPayment {
  const ChatPayment({
    required this.id,
    required this.threadId,
    required this.buyerId,
    required this.sellerId,
    required this.agreedPrice,
    required this.tokenAmount,
    required this.amountPaise,
    required this.currency,
    required this.status,
    this.listingId,
    this.partTitle = '',
    this.buyerName = '',
    this.sellerName = '',
    this.tokenPercent = 0.01,
    this.cashfreeOrderId,
    this.cashfreePaymentId,
    this.cashfreeOrderNote,
    this.cashfreePaymentSessionId,
    this.paymentMethod,
    this.cashfreePaymentStatus,
    this.refundReason,
    this.cashfreeRefundId,
    this.paidAt,
    this.refundRequestedAt,
    this.refundApprovedAt,
    this.createdAt,
    this.cashfreeOrderResponse = const {},
    this.cashfreePaymentResponse = const {},
    this.cashfreeWebhookEvents = const [],
    this.cashfreeRefundResponse,
  });

  final String id;
  final String threadId;
  final String? listingId;
  final String partTitle;
  final String buyerId;
  final String sellerId;
  final String buyerName;
  final String sellerName;
  final double agreedPrice;
  final double tokenAmount;
  final double tokenPercent;
  final int amountPaise;
  final String currency;
  final ChatPaymentStatus status;
  final String? cashfreeOrderId;
  final String? cashfreePaymentId;
  final String? cashfreeOrderNote;
  final String? cashfreePaymentSessionId;
  final String? paymentMethod;
  final String? cashfreePaymentStatus;
  final String? refundReason;
  final String? cashfreeRefundId;
  final DateTime? paidAt;
  final DateTime? refundRequestedAt;
  final DateTime? refundApprovedAt;
  final DateTime? createdAt;
  final Map<String, dynamic> cashfreeOrderResponse;
  final Map<String, dynamic> cashfreePaymentResponse;
  final List<dynamic> cashfreeWebhookEvents;
  final Map<String, dynamic>? cashfreeRefundResponse;

  bool get isPaid => status == ChatPaymentStatus.paid;

  factory ChatPayment.fromJson(Map<String, dynamic> json) {
    return ChatPayment(
      id: json['id'] as String,
      threadId: json['thread_id'] as String,
      listingId: json['listing_id'] as String?,
      partTitle: json['part_title'] as String? ?? '',
      buyerId: json['buyer_id'] as String,
      sellerId: json['seller_id'] as String,
      buyerName: json['buyer_name'] as String? ?? '',
      sellerName: json['seller_name'] as String? ?? '',
      agreedPrice: (json['agreed_price'] as num).toDouble(),
      tokenAmount: (json['token_amount'] as num).toDouble(),
      tokenPercent: (json['token_percent'] as num?)?.toDouble() ?? 0.01,
      amountPaise: json['amount_paise'] as int,
      currency: json['currency'] as String? ?? 'INR',
      status: ChatPaymentStatus.fromStorage(json['status'] as String?),
      cashfreeOrderId: json['cashfree_order_id'] as String?,
      cashfreePaymentId: json['cashfree_payment_id'] as String?,
      cashfreeOrderNote: json['cashfree_order_note'] as String?,
      cashfreePaymentSessionId: json['cashfree_payment_session_id'] as String?,
      paymentMethod: json['payment_method'] as String?,
      cashfreePaymentStatus: json['cashfree_payment_status'] as String?,
      refundReason: json['refund_reason'] as String?,
      cashfreeRefundId: json['cashfree_refund_id'] as String?,
      paidAt: _parseDate(json['paid_at']),
      refundRequestedAt: _parseDate(json['refund_requested_at']),
      refundApprovedAt: _parseDate(json['refund_approved_at']),
      createdAt: _parseDate(json['created_at']),
      cashfreeOrderResponse:
          (json['cashfree_order_response'] as Map?)?.cast<String, dynamic>() ?? {},
      cashfreePaymentResponse:
          (json['cashfree_payment_response'] as Map?)?.cast<String, dynamic>() ?? {},
      cashfreeWebhookEvents: json['cashfree_webhook_events'] as List? ?? const [],
      cashfreeRefundResponse:
          (json['cashfree_refund_response'] as Map?)?.cast<String, dynamic>(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

class CashfreeCheckoutSession {
  const CashfreeCheckoutSession({
    required this.appId,
    required this.orderId,
    required this.paymentSessionId,
    required this.amountPaise,
    required this.tokenAmount,
    required this.agreedPrice,
    required this.tokenPercent,
    required this.currency,
    required this.paymentId,
    required this.description,
    this.isProduction = true,
    this.prefillName = '',
    this.prefillContact = '',
  });

  final String appId;
  final String orderId;
  final String paymentSessionId;
  final int amountPaise;
  final double tokenAmount;
  final double agreedPrice;
  final double tokenPercent;
  final String currency;
  final String paymentId;
  final String description;
  final bool isProduction;
  final String prefillName;
  final String prefillContact;

  factory CashfreeCheckoutSession.fromJson(Map<String, dynamic> json) {
    final prefill = json['prefill'] as Map<String, dynamic>? ?? {};
    return CashfreeCheckoutSession(
      appId: json['app_id'] as String,
      orderId: json['order_id'] as String,
      paymentSessionId: json['payment_session_id'] as String,
      amountPaise: json['amount_paise'] as int,
      tokenAmount: (json['token_amount'] as num).toDouble(),
      agreedPrice: (json['agreed_price'] as num).toDouble(),
      tokenPercent: (json['token_percent'] as num?)?.toDouble() ?? 0.01,
      currency: json['currency'] as String? ?? 'INR',
      paymentId: json['payment_id'] as String,
      description: json['description'] as String? ?? 'SpareKart advance token',
      isProduction: (json['environment'] as String?) != 'sandbox',
      prefillName: prefill['name'] as String? ?? '',
      prefillContact: prefill['contact'] as String? ?? '',
    );
  }
}
