import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:spare_kart/core/utils/date_time_utils.dart';
import 'package:spare_kart/data/models/models.dart';
import 'package:spare_kart/features/messages/chat_flow.dart';
import 'package:spare_kart/features/messages/chat_session_store.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MessagesRepository {
  MessagesRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  RealtimeChannel? _realtimeChannel;

  static const _threadSelect = '''
    id,
    listing_id,
    buyer_id,
    seller_id,
    part_title,
    flow_step,
    blocked_until,
    agreed_price,
    availability_date,
    list_price,
    pickup_location,
    seller_replied_after_token,
    delivery_choice_made,
    buyer_last_read_at,
    seller_last_read_at,
    is_guided,
    last_message_at,
    buyer:profiles!buyer_id (name),
    seller:profiles!seller_id (name)
  ''';

  void subscribeToChanges({required void Function() onChanged}) {
    final userId = currentUserId;
    if (userId == null) return;

    unsubscribe();
    _realtimeChannel = _client
        .channel('messages-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (_) => onChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'message_threads',
          callback: (_) => onChanged(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chat_transactions',
          callback: (_) => onChanged(),
        )
        .subscribe();
  }

  void unsubscribe() {
    final channel = _realtimeChannel;
    if (channel != null) {
      _client.removeChannel(channel);
      _realtimeChannel = null;
    }
  }

  Future<List<ChatSession>> fetchSessionsForUser(String userId) async {
    final rows = await _client
        .from('message_threads')
        .select(_threadSelect)
        .or('buyer_id.eq.$userId,seller_id.eq.$userId')
        .order('last_message_at', ascending: false);

    final sessions = <ChatSession>[];
    for (final row in rows as List) {
      final session = await _mapThreadRow(row as Map<String, dynamic>, userId);
      if (session != null && session.messages.isNotEmpty) {
        sessions.add(session);
      }
    }
    return sessions;
  }

  Future<ChatSession?> fetchSession(String threadId, String userId) async {
    final row = await _client
        .from('message_threads')
        .select(_threadSelect)
        .eq('id', threadId)
        .maybeSingle();
    if (row == null) return null;
    return _mapThreadRow(row, userId);
  }

  Future<ChatSession?> getOrCreateThread({
    required String listingId,
    required String buyerId,
    required String sellerId,
    required String partTitle,
    required double listPrice,
    required String pickupLocation,
    required String buyerName,
    required String sellerName,
  }) async {
    final existing = await _client
        .from('message_threads')
        .select(_threadSelect)
        .eq('listing_id', listingId)
        .eq('buyer_id', buyerId)
        .maybeSingle();

    if (existing != null) {
      final session = await _mapThreadRow(existing, buyerId);
      if (session != null &&
          session.messages.isEmpty &&
          session.flowStep != ChatFlowStep.started) {
        session.flowStep = ChatFlowStep.started;
        await updateThreadState(session);
      }
      return session;
    }

    final inserted = await _client
        .from('message_threads')
        .insert({
          'listing_id': listingId,
          'buyer_id': buyerId,
          'seller_id': sellerId,
          'part_title': partTitle,
          'list_price': listPrice,
          'pickup_location': pickupLocation,
          'flow_step': ChatFlowStep.started.name,
          'is_guided': true,
        })
        .select(_threadSelect)
        .single();

    final session = await _mapThreadRow(inserted, buyerId);
    if (session != null) {
      session.buyerName = buyerName;
      session.sellerName = sellerName;
    }
    return session;
  }

  Future<ChatMessage> sendMessage({
    required String threadId,
    required String senderId,
    required String text,
    String? imageUrl,
  }) async {
    final row = await _client
        .from('messages')
        .insert({
          'thread_id': threadId,
          'sender_id': senderId,
          'text': text,
          if (imageUrl != null) 'image_url': imageUrl,
        })
        .select('id, sender_id, text, image_url, created_at')
        .single();

    unawaited(_invokeChatPush(threadId: threadId, senderId: senderId, text: text));

    return _mapMessageRow(row, senderId);
  }

  Future<String> uploadChatImage({
    required String threadId,
    required String localPath,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw const MessagesRepositoryException('You must be signed in to upload images.');
    }

    final file = File(localPath);
    final ext = localPath.split('.').last.toLowerCase();
    final path = '$userId/$threadId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from('chat-attachments').upload(
          path,
          file,
          fileOptions: FileOptions(
            contentType: _mimeForExt(ext),
            upsert: false,
          ),
        );

    return _client.storage.from('chat-attachments').getPublicUrl(path);
  }

  Future<void> updateThreadState(ChatSession session) async {
    await _client.from('message_threads').update({
      'flow_step': session.flowStep.name,
      'blocked_until': session.blockedUntil?.toIso8601String(),
      'agreed_price': session.agreedPrice,
      'availability_date': session.availabilityDate?.toIso8601String(),
      'seller_replied_after_token': session.sellerRepliedAfterToken,
      'delivery_choice_made': session.deliveryChoiceMade,
      'list_price': session.listPrice,
      'pickup_location': session.pickupLocation,
    }).eq('id', session.id);
  }

  Future<void> markThreadRead({
    required String threadId,
    required bool asSeller,
  }) async {
    final field = asSeller ? 'seller_last_read_at' : 'buyer_last_read_at';
    await _client.from('message_threads').update({
      field: DateTime.now().toIso8601String(),
    }).eq('id', threadId);
  }

  Future<ChatSession?> _mapThreadRow(
    Map<String, dynamic> row,
    String currentUserId,
  ) async {
    final threadId = row['id'] as String;
    final buyerId = row['buyer_id'] as String;
    final sellerId = row['seller_id'] as String;

    final messageRows = await _client
        .from('messages')
        .select('id, sender_id, text, image_url, created_at')
        .eq('thread_id', threadId)
        .order('created_at', ascending: true);

    final rawMessages = (messageRows as List).cast<Map<String, dynamic>>();
    final messages = rawMessages
        .map((m) => _mapMessageRow(m, currentUserId))
        .toList();

    final buyerProfile = row['buyer'] as Map<String, dynamic>?;
    final sellerProfile = row['seller'] as Map<String, dynamic>?;

    final session = ChatSession(
      id: threadId,
      listingId: row['listing_id'] as String?,
      partTitle: row['part_title'] as String? ?? '',
      sellerName: sellerProfile?['name'] as String? ?? 'Seller',
      buyerName: buyerProfile?['name'] as String? ?? 'Buyer',
      sellerId: sellerId,
      buyerId: buyerId,
      messages: messages,
      flowStep: ChatFlowStepX.fromStorage(row['flow_step'] as String?),
      isGuided: row['is_guided'] as bool? ?? true,
      listPrice: (row['list_price'] as num?)?.toDouble() ?? 0,
      pickupLocation: row['pickup_location'] as String? ?? '',
      blockedUntil: _parseDate(row['blocked_until']),
      agreedPrice: (row['agreed_price'] as num?)?.toDouble(),
      availabilityDate: _parseDate(row['availability_date']),
      sellerRepliedAfterToken: row['seller_replied_after_token'] as bool? ?? false,
      deliveryChoiceMade: row['delivery_choice_made'] as bool? ?? false,
    );

    session.buyerUnreadCount = _unreadCountFromRows(
      rows: rawMessages,
      readerId: buyerId,
      lastReadAt: _parseDate(row['buyer_last_read_at']),
    );
    session.sellerUnreadCount = _unreadCountFromRows(
      rows: rawMessages,
      readerId: sellerId,
      lastReadAt: _parseDate(row['seller_last_read_at']),
    );

    _refreshBuyerBlock(session);
    session.normalizeFlowStep();
    return session;
  }

  ChatMessage _mapMessageRow(Map<String, dynamic> row, String currentUserId) {
    final senderId = row['sender_id'] as String;
    final imageUrl = row['image_url'] as String?;
    return ChatMessage(
      id: row['id'] as String,
      text: row['text'] as String,
      isMe: senderId == currentUserId,
      timestamp: parseSupabaseDateTime(row['created_at']),
      imagePath: imageUrl,
      senderId: senderId,
    );
  }

  int _unreadCountFromRows({
    required List<Map<String, dynamic>> rows,
    required String readerId,
    required DateTime? lastReadAt,
  }) {
    var count = 0;
    for (final row in rows) {
      final senderId = row['sender_id'] as String;
      if (senderId == readerId) continue;
      final created = parseSupabaseDateTime(row['created_at']);
      if (lastReadAt == null || created.isAfter(lastReadAt)) {
        count++;
      }
    }
    return count;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return parseSupabaseDateTime(value);
  }

  String _mimeForExt(String ext) => switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

  void _refreshBuyerBlock(ChatSession session) {
    if (session.flowStep == ChatFlowStep.buyerBlockedAfterNo &&
        session.blockedUntil != null &&
        DateTime.now().isAfter(session.blockedUntil!)) {
      session.flowStep = ChatFlowStep.started;
      session.blockedUntil = null;
    }
  }

  Future<void> _invokeChatPush({
    required String threadId,
    required String senderId,
    required String text,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'send-chat-push',
        body: {
          'thread_id': threadId,
          'sender_id': senderId,
          'message_text': text,
        },
      );
      if (kDebugMode) {
        debugPrint('send-chat-push: ${response.data}');
      }
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('send-chat-push failed: $error');
        debugPrint('$stack');
      }
    }
  }
}

class MessagesRepositoryException implements Exception {
  const MessagesRepositoryException(this.message);
  final String message;

  @override
  String toString() => message;
}

extension ChatFlowStepX on ChatFlowStep {
  static ChatFlowStep fromStorage(String? value) {
    if (value == null || value.isEmpty) return ChatFlowStep.completed;
    if (value == 'awaitingTokenScreenshot') {
      return ChatFlowStep.awaitingDeliveryChoice;
    }
    for (final step in ChatFlowStep.values) {
      if (step.name == value) return step;
    }
    return ChatFlowStep.completed;
  }
}
