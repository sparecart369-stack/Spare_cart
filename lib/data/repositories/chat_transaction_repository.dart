import 'package:spare_kart/data/models/chat_transaction.dart';
import 'package:spare_kart/features/messages/chat_flow.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatTransactionRepository {
  ChatTransactionRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _transactionSelect = '''
    id,
    thread_id,
    buyer_id,
    seller_id,
    advance_payment_id,
    fulfillment_mode,
    agreed_price,
    token_amount,
    remaining_amount,
    status,
    delivery_partner_name,
    dispute_reason,
    seller_dispatched_at,
    buyer_confirmed_at,
    seller_confirmed_at,
    completed_at,
    refund_requested_at,
    created_at
  ''';

  Future<ChatTransaction?> fetchForThread(String threadId) async {
    final row = await _client
        .from('chat_transactions')
        .select(_transactionSelect)
        .eq('thread_id', threadId)
        .maybeSingle();
    if (row == null) return null;
    return ChatTransaction.fromJson(row);
  }

  Future<DeliveryPartnerRating?> fetchRatingForTransaction(String transactionId) async {
    final row = await _client
        .from('delivery_partner_ratings')
        .select()
        .eq('transaction_id', transactionId)
        .maybeSingle();
    if (row == null) return null;
    return DeliveryPartnerRating.fromJson(row);
  }

  Future<ChatTransaction> ensureTransaction({
    required String threadId,
    required String buyerId,
    required String sellerId,
    required ChatFulfillmentMode fulfillmentMode,
    required double agreedPrice,
    required double tokenAmount,
    String? advancePaymentId,
  }) async {
    final existing = await fetchForThread(threadId);
    if (existing != null) {
      if (existing.fulfillmentMode != fulfillmentMode) {
        final row = await _client
            .from('chat_transactions')
            .update({'fulfillment_mode': fulfillmentMode.storageValue})
            .eq('id', existing.id)
            .select(_transactionSelect)
            .single();
        return ChatTransaction.fromJson(row);
      }
      return existing;
    }

    final remainingAmount = (agreedPrice - tokenAmount).clamp(0, agreedPrice);

    final row = await _client
        .from('chat_transactions')
        .insert({
          'thread_id': threadId,
          'buyer_id': buyerId,
          'seller_id': sellerId,
          'advance_payment_id': advancePaymentId,
          'fulfillment_mode': fulfillmentMode.storageValue,
          'agreed_price': agreedPrice,
          'token_amount': tokenAmount,
          'remaining_amount': remainingAmount,
        })
        .select(_transactionSelect)
        .single();

    return ChatTransaction.fromJson(row);
  }

  Future<ChatTransaction> markDispatched({
    required String transactionId,
    String? deliveryPartnerName,
  }) async {
    final row = await _client
        .from('chat_transactions')
        .update({
          'status': ChatTransactionStatus.dispatched.storageValue,
          'delivery_partner_name': deliveryPartnerName?.trim().isNotEmpty == true
              ? deliveryPartnerName!.trim()
              : null,
          'seller_dispatched_at': DateTime.now().toIso8601String(),
        })
        .eq('id', transactionId)
        .select(_transactionSelect)
        .single();
    return ChatTransaction.fromJson(row);
  }

  Future<ChatTransaction> markBuyerConfirmed({
    required String transactionId,
  }) async {
    final row = await _client
        .from('chat_transactions')
        .update({
          'status': ChatTransactionStatus.buyerConfirmed.storageValue,
          'buyer_confirmed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', transactionId)
        .select(_transactionSelect)
        .single();
    return ChatTransaction.fromJson(row);
  }

  Future<ChatTransaction> markBuyerDispute({
    required String transactionId,
    String? reason,
  }) async {
    final row = await _client
        .from('chat_transactions')
        .update({
          'status': ChatTransactionStatus.dispute.storageValue,
          'dispute_reason': reason?.trim().isNotEmpty == true ? reason!.trim() : null,
          'buyer_confirmed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', transactionId)
        .select(_transactionSelect)
        .single();
    return ChatTransaction.fromJson(row);
  }

  Future<ChatTransaction> markSellerConfirmed({
    required String transactionId,
  }) async {
    final row = await _client
        .from('chat_transactions')
        .update({
          'status': ChatTransactionStatus.sellerConfirmed.storageValue,
          'seller_confirmed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', transactionId)
        .select(_transactionSelect)
        .single();
    return ChatTransaction.fromJson(row);
  }

  Future<ChatTransaction> markSellerDispute({
    required String transactionId,
    String? reason,
  }) async {
    final row = await _client
        .from('chat_transactions')
        .update({
          'status': ChatTransactionStatus.dispute.storageValue,
          'dispute_reason': reason?.trim().isNotEmpty == true ? reason!.trim() : null,
          'seller_confirmed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', transactionId)
        .select(_transactionSelect)
        .single();
    return ChatTransaction.fromJson(row);
  }

  Future<ChatTransaction> markCompleted(String transactionId) async {
    final row = await _client
        .from('chat_transactions')
        .update({
          'status': ChatTransactionStatus.completed.storageValue,
          'completed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', transactionId)
        .select(_transactionSelect)
        .single();
    return ChatTransaction.fromJson(row);
  }

  Future<ChatTransaction> markRefundRequested(String transactionId) async {
    final row = await _client
        .from('chat_transactions')
        .update({
          'status': ChatTransactionStatus.refundRequested.storageValue,
          'refund_requested_at': DateTime.now().toIso8601String(),
        })
        .eq('id', transactionId)
        .select(_transactionSelect)
        .single();
    return ChatTransaction.fromJson(row);
  }

  Future<DeliveryPartnerRating> submitDeliveryRating({
    required ChatTransaction transaction,
    required int rating,
    String? reviewText,
    String? ratedPartyName,
  }) async {
    final partnerName =
        ratedPartyName?.trim() ?? transaction.deliveryPartnerName?.trim();
    if (partnerName == null || partnerName.isEmpty) {
      throw const ChatTransactionException('Rated party name is missing.');
    }

    final row = await _client
        .from('delivery_partner_ratings')
        .insert({
          'transaction_id': transaction.id,
          'thread_id': transaction.threadId,
          'buyer_id': transaction.buyerId,
          'seller_id': transaction.sellerId,
          'delivery_partner_name': partnerName,
          'rating': rating,
          if (reviewText != null && reviewText.trim().isNotEmpty)
            'review_text': reviewText.trim(),
        })
        .select()
        .single();

    try {
      await _client.rpc('upsert_seller_rating', params: {
        'p_transaction_id': transaction.id,
        'p_rating': rating,
        'p_review_text': reviewText?.trim(),
      });
    } catch (_) {
      // RPC may be missing until migration is applied; delivery trigger may sync.
    }

    await markCompleted(transaction.id);
    return DeliveryPartnerRating.fromJson(row);
  }

  ChatFlowStep flowStepForTransaction(ChatTransaction? transaction) {
    if (transaction == null) return ChatFlowStep.awaitingSellerHandoff;
    return switch (transaction.status) {
      ChatTransactionStatus.pendingHandoff => ChatFlowStep.awaitingSellerHandoff,
      ChatTransactionStatus.dispatched => ChatFlowStep.awaitingBuyerReceipt,
      ChatTransactionStatus.buyerConfirmed => ChatFlowStep.awaitingSellerConfirm,
      ChatTransactionStatus.sellerConfirmed => ChatFlowStep.awaitingDeliveryPartnerRating,
      ChatTransactionStatus.completed => ChatFlowStep.completed,
      ChatTransactionStatus.dispute => ChatFlowStep.disputeOpen,
      ChatTransactionStatus.refundRequested => ChatFlowStep.disputeOpen,
    };
  }
}

class ChatTransactionException implements Exception {
  const ChatTransactionException(this.message);
  final String message;

  @override
  String toString() => message;
}
