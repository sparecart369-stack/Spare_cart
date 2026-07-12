import 'package:spare_kart/data/models/chat_payment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatPaymentRepository {
  ChatPaymentRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<RazorpayCheckoutSession> createCheckoutSession(String threadId) async {
    final response = await _client.functions.invoke(
      'create-razorpay-order',
      body: {'thread_id': threadId},
    );

    final data = response.data;
    if (response.status != 200 || data is! Map<String, dynamic>) {
      final error = data is Map ? data['error'] : null;
      throw ChatPaymentException(
        error?.toString() ?? 'Failed to create Razorpay order',
      );
    }

    return RazorpayCheckoutSession.fromJson(data);
  }

  Future<double> verifyPayment({
    required String threadId,
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final response = await _client.functions.invoke(
      'verify-razorpay-payment',
      body: {
        'thread_id': threadId,
        'razorpay_order_id': orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature': signature,
      },
    );

    final data = response.data;
    if (response.status != 200 || data is! Map<String, dynamic>) {
      final error = data is Map ? data['error'] : null;
      throw ChatPaymentException(
        error?.toString() ?? 'Payment verification failed',
      );
    }

    return (data['token_amount'] as num?)?.toDouble() ?? 0;
  }

  static const _paymentSelect = '''
    id,
    thread_id,
    listing_id,
    part_title,
    buyer_id,
    seller_id,
    buyer_name,
    seller_name,
    agreed_price,
    token_amount,
    token_percent,
    amount_paise,
    currency,
    status,
    razorpay_order_id,
    razorpay_payment_id,
    razorpay_receipt,
    razorpay_signature,
    payment_method,
    razorpay_payment_status,
    refund_reason,
    razorpay_refund_id,
    paid_at,
    refund_requested_at,
    refund_approved_at,
    created_at,
    razorpay_order_response,
    razorpay_payment_response,
    razorpay_webhook_events,
    razorpay_refund_response
  ''';

  Future<ChatPayment?> fetchLatestForThread(String threadId) async {
    final row = await _client
        .from('chat_payments')
        .select(_paymentSelect)
        .eq('thread_id', threadId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (row == null) return null;
    return ChatPayment.fromJson(row);
  }

  Future<List<ChatPayment>> fetchAllPayments() async {
    final rows = await _client
        .from('chat_payments')
        .select(_paymentSelect)
        .order('created_at', ascending: false);

    return (rows as List)
        .map((row) => ChatPayment.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> requestRefund({
    required String paymentId,
    String? reason,
  }) async {
    await _client.from('chat_payments').update({
      'status': ChatPaymentStatus.refundRequested.storageValue,
      'refund_requested_at': DateTime.now().toIso8601String(),
      if (reason != null && reason.trim().isNotEmpty) 'refund_reason': reason.trim(),
    }).eq('id', paymentId);
  }

  Future<List<ChatPayment>> fetchRefundRequests() async {
    final rows = await _client
        .from('chat_payments')
        .select(_paymentSelect)
        .eq('status', ChatPaymentStatus.refundRequested.storageValue)
        .order('refund_requested_at', ascending: false);

    return (rows as List)
        .map((row) => ChatPayment.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> approveRefund(String paymentId) async {
    final response = await _client.functions.invoke(
      'approve-chat-refund',
      body: {'payment_id': paymentId},
    );

    final data = response.data;
    if (response.status != 200 || data is! Map<String, dynamic>) {
      final error = data is Map ? data['error'] : null;
      throw ChatPaymentException(
        error?.toString() ?? 'Refund approval failed',
      );
    }
  }
}

class ChatPaymentException implements Exception {
  const ChatPaymentException(this.message);
  final String message;

  @override
  String toString() => message;
}
