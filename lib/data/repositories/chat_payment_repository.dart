import 'package:spare_kart/data/models/chat_payment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatPaymentRepository {
  ChatPaymentRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<CashfreeCheckoutSession> createCheckoutSession(String threadId) async {
    final response = await _client.functions.invoke(
      'create-cashfree-order',
      body: {'thread_id': threadId},
    );

    final data = response.data;
    if (response.status != 200 || data is! Map<String, dynamic>) {
      final error = data is Map ? data['error'] : null;
      throw ChatPaymentException(
        error?.toString() ?? 'Failed to create Cashfree order',
      );
    }

    return CashfreeCheckoutSession.fromJson(data);
  }

  Future<double> verifyPayment({
    required String threadId,
    required String orderId,
  }) async {
    final response = await _client.functions.invoke(
      'verify-cashfree-payment',
      body: {
        'thread_id': threadId,
        'cashfree_order_id': orderId,
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
    cashfree_order_id,
    cashfree_payment_id,
    cashfree_order_note,
    cashfree_payment_session_id,
    payment_method,
    cashfree_payment_status,
    refund_reason,
    cashfree_refund_id,
    paid_at,
    refund_requested_at,
    refund_approved_at,
    created_at,
    cashfree_order_response,
    cashfree_payment_response,
    cashfree_webhook_events,
    cashfree_refund_response
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
