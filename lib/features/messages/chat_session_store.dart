import 'package:flutter/foundation.dart';
import 'package:spare_kart/data/models/models.dart';
import 'package:spare_kart/data/repositories/messages_repository.dart';
import 'package:spare_kart/features/messages/chat_flow.dart';

class ChatSession {
  ChatSession({
    required this.id,
    required this.partTitle,
    required this.sellerName,
    required this.buyerName,
    this.listingId,
    this.sellerId,
    this.buyerId,
    List<ChatMessage>? messages,
    this.flowStep = ChatFlowStep.completed,
    this.isGuided = false,
    this.listPrice = 0,
    this.pickupLocation = '',
    this.blockedUntil,
    this.agreedPrice,
    this.availabilityDate,
    this.tokenScreenshotPath,
    this.sellerRepliedAfterToken = false,
    this.deliveryChoiceMade = false,
    this.sellerDeliveryOffer,
    this.buyerDeliveryAsk,
    this.buyerUnreadCount = 0,
    this.sellerUnreadCount = 0,
  }) : messages = messages ?? [];

  final String id;
  final String? listingId;
  final String partTitle;
  String sellerName;
  String buyerName;
  final String? sellerId;
  String? buyerId;
  final List<ChatMessage> messages;
  ChatFlowStep flowStep;
  final bool isGuided;
  final double listPrice;
  final String pickupLocation;
  DateTime? blockedUntil;
  double? agreedPrice;
  DateTime? availabilityDate;
  String? tokenScreenshotPath;
  bool sellerRepliedAfterToken;
  bool deliveryChoiceMade;
  String? sellerDeliveryOffer;
  String? buyerDeliveryAsk;
  int buyerUnreadCount;
  int sellerUnreadCount;

  bool get isBuyerBlocked =>
      ChatFlow.isBuyerBlocked(flowStep, blockedUntil);

  /// Keeps guided flow in sync when DB `flow_step` lags behind messages.
  void normalizeFlowStep() {
    if (!isGuided || messages.isEmpty || buyerId == null) return;

    final last = messages.last;
    final fromBuyer = last.senderId == buyerId;
    final fromSeller = sellerId != null && last.senderId == sellerId;

    if (flowStep == ChatFlowStep.started && fromBuyer) {
      flowStep = ChatFlowStep.awaitingAvailability;
      return;
    }

    if (fromBuyer &&
        flowStep == ChatFlowStep.awaitingTokenPayment &&
        last.text.toLowerCase().contains('advance token') &&
        last.text.toLowerCase().contains('paid successfully')) {
      flowStep = ChatFlowStep.awaitingDeliveryChoice;
      return;
    }

    if (fromBuyer &&
        flowStep == ChatFlowStep.awaitingTokenPayment &&
        last.text.toLowerCase().contains('token payment') &&
        last.text.toLowerCase().contains('razorpay')) {
      flowStep = ChatFlowStep.awaitingDeliveryChoice;
      return;
    }

    if (fromBuyer &&
        (flowStep == ChatFlowStep.awaitingTokenPayment) &&
        (last.text.toLowerCase().contains('payment screenshot') || last.imagePath != null)) {
      flowStep = ChatFlowStep.awaitingDeliveryChoice;
      return;
    }

    if (buyerDeliveryAsk == null && buyerId != null) {
      for (var i = messages.length - 1; i >= 0; i--) {
        final msg = messages[i];
        if (msg.senderId != buyerId) continue;
        final ask = ChatFlow.parseBuyerDeliveryAsk(msg.text);
        if (ask != null) {
          buyerDeliveryAsk = ask;
          break;
        }
      }
    }

    if (flowStep == ChatFlowStep.awaitingAvailability && fromSeller) {
      final text = last.text.toLowerCase();
      if (text.contains('no longer available')) {
        flowStep = ChatFlowStep.buyerBlockedAfterNo;
      } else if (text.contains('will be available soon')) {
        flowStep = ChatFlowStep.awaitingWhenAvailableAsk;
      } else if (text.contains('still available') || text.contains('now available')) {
        flowStep = ChatFlowStep.awaitingPriceAsk;
      }
    }

    if (sellerDeliveryOffer == null && sellerId != null) {
      for (var i = messages.length - 1; i >= 0; i--) {
        final msg = messages[i];
        if (msg.senderId != sellerId) continue;
        final offer = ChatFlow.parseSellerDeliveryOffer(msg.text);
        if (offer != null) {
          sellerDeliveryOffer = offer;
          sellerRepliedAfterToken = true;
          break;
        }
      }
    }

    final hasDeliveryLocation = messages.any(
      (msg) =>
          msg.senderId == buyerId && msg.text.startsWith('Delivery location:'),
    );

    if (!hasDeliveryLocation) {
      final buyerWantsDoorstep = messages.any(
        (msg) =>
            msg.senderId == buyerId &&
            (msg.text.toLowerCase().contains("i'd like doorstep delivery") ||
                msg.text.toLowerCase().contains('both pickup and doorstep')),
      );
      final sellerDoorstepOnly = sellerDeliveryOffer == 'doorstep_only' ||
          sellerDeliveryOffer == 'doorstep_yes';

      if (buyerWantsDoorstep || sellerDoorstepOnly) {
        flowStep = ChatFlowStep.awaitingBuyerLocationForDelivery;
        if (buyerWantsDoorstep) deliveryChoiceMade = true;
        return;
      }

      if (fromSeller &&
          last.text.startsWith('Pickup location:') &&
          messages.any(
            (msg) =>
                msg.senderId == buyerId &&
                msg.text.toLowerCase().contains('both pickup and doorstep'),
          )) {
        flowStep = ChatFlowStep.awaitingBuyerLocationForDelivery;
        deliveryChoiceMade = true;
        return;
      }
    }

    if (ChatFlow.isDeliveryFlowComplete(
      messages: messages,
      buyerId: buyerId,
      sellerId: sellerId,
    )) {
      flowStep = ChatFlowStep.freeChat;
      deliveryChoiceMade = true;
    }
  }

  String? get lastBuyerMessage {
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].isMe) return messages[i].text;
    }
    return null;
  }

  void markRead({required bool isSeller}) {
    if (isSeller) {
      sellerUnreadCount = 0;
    } else {
      buyerUnreadCount = 0;
    }
  }

  void incrementUnreadForRecipient({required bool sentByBuyer}) {
    if (sentByBuyer) {
      sellerUnreadCount++;
    } else {
      buyerUnreadCount++;
    }
  }

  bool isVisibleTo({String? userId}) {
    if (messages.isEmpty) return false;
    if (userId == null) return true;
    return buyerId == null ||
        sellerId == null ||
        buyerId == userId ||
        sellerId == userId;
  }

  MessageThread toThread({required String? currentUserId}) {
    final isCurrentUserSeller =
        currentUserId != null && sellerId == currentUserId;
    return MessageThread(
      id: id,
      participantName: isCurrentUserSeller ? buyerName : sellerName,
      lastMessage: messages.isNotEmpty ? messages.last.text : '',
      timestamp: messages.isNotEmpty ? messages.last.timestamp : DateTime.now(),
      unreadCount: isCurrentUserSeller ? sellerUnreadCount : buyerUnreadCount,
      partTitle: partTitle,
    );
  }
}

class ChatSessionStore extends ChangeNotifier {
  ChatSessionStore._();

  static final ChatSessionStore instance = ChatSessionStore._();

  final MessagesRepository _repository = MessagesRepository();
  final Map<String, ChatSession> _sessions = {};
  String? _activeUserId;
  bool _isRefreshing = false;

  MessagesRepository get repository => _repository;

  ChatSession? get(String id) => _sessions[id];

  List<ChatSession> get allSessions => _sessions.values.toList();

  List<ChatSession> sessionsFor({String? userId}) {
    return _sessions.values.where((session) => session.isVisibleTo(userId: userId)).toList();
  }

  Future<void> initialize(String? userId) async {
    if (userId == null) {
      _clear();
      return;
    }

    if (_activeUserId == userId && _sessions.isNotEmpty) {
      _repository.subscribeToChanges(onChanged: () => refresh(userId));
      return;
    }

    _activeUserId = userId;
    _repository.subscribeToChanges(onChanged: () => refresh(userId));
    await refresh(userId);
  }

  void _clear() {
    _activeUserId = null;
    _sessions.clear();
    _repository.unsubscribe();
    notifyListeners();
  }

  Future<void> refresh(String userId) async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      final sessions = await _repository.fetchSessionsForUser(userId);
      for (final session in sessions) {
        _sessions[session.id] = session;
      }
      notifyListeners();
    } finally {
      _isRefreshing = false;
    }
  }

  void cacheSession(ChatSession session) {
    _sessions[session.id] = session;
    notifyListeners();
  }

  Future<ChatSession?> loadSession(String threadId, String userId) async {
    final cached = _sessions[threadId];
    if (cached != null) {
      return cached;
    }

    final session = await _repository.fetchSession(threadId, userId);
    if (session != null) {
      _sessions[threadId] = session;
      notifyListeners();
    }
    return session;
  }

  Future<ChatSession?> startGuidedSession({
    required String listingId,
    required String partTitle,
    required String sellerName,
    required double listPrice,
    required String pickupLocation,
    String? sellerId,
    String? buyerId,
    String buyerName = 'Guest',
  }) async {
    if (buyerId == null || sellerId == null) return null;

    final session = await _repository.getOrCreateThread(
      listingId: listingId,
      buyerId: buyerId,
      sellerId: sellerId,
      partTitle: partTitle,
      listPrice: listPrice,
      pickupLocation: pickupLocation,
      buyerName: buyerName,
      sellerName: sellerName,
    );

    if (session != null) {
      cacheSession(session);
    }
    return session;
  }

  Future<ChatMessage?> sendMessage({
    required ChatSession session,
    required String senderId,
    required String text,
    String? localImagePath,
  }) async {
    String? imageUrl;
    if (localImagePath != null && localImagePath.isNotEmpty) {
      imageUrl = await _repository.uploadChatImage(
        threadId: session.id,
        localPath: localImagePath,
      );
    }

    final message = await _repository.sendMessage(
      threadId: session.id,
      senderId: senderId,
      text: text,
      imageUrl: imageUrl,
    );

    session.messages.add(message);
    session.incrementUnreadForRecipient(
      sentByBuyer: senderId == session.buyerId,
    );
    _sessions[session.id] = session;
    notifyListeners();
    return message;
  }

  Future<void> save(ChatSession session) async {
    _refreshBuyerBlock(session);
    _sessions[session.id] = session;
    try {
      await _repository.updateThreadState(session);
    } catch (_) {
      // Flow columns may be missing until migration is applied; keep local state.
    }
    notifyListeners();
  }

  Future<void> markRead(ChatSession session, {required bool isSeller}) async {
    final hadUnread = isSeller
        ? session.sellerUnreadCount > 0
        : session.buyerUnreadCount > 0;
    if (!hadUnread) return;

    session.markRead(isSeller: isSeller);
    _sessions[session.id] = session;
    await _repository.markThreadRead(threadId: session.id, asSeller: isSeller);
    notifyListeners();
  }

  void _refreshBuyerBlock(ChatSession session) {
    if (session.flowStep == ChatFlowStep.buyerBlockedAfterNo &&
        session.blockedUntil != null &&
        DateTime.now().isAfter(session.blockedUntil!)) {
      session.flowStep = ChatFlowStep.started;
      session.blockedUntil = null;
    }
  }
}
