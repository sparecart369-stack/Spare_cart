import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:spare_kart/bloc/app_mode/app_mode_bloc.dart';
import 'package:spare_kart/bloc/auth/auth_bloc.dart';
import 'package:spare_kart/bloc/messages/messages_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:spare_kart/core/router/app_routes.dart';
import 'package:spare_kart/core/services/location_service.dart';
import 'package:spare_kart/core/services/location_settings_helper.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/utils/date_time_utils.dart';
import 'package:spare_kart/core/utils/responsive.dart';
import 'package:spare_kart/core/validation/form_validators.dart';
import 'package:spare_kart/core/widgets/listing_image.dart';
import 'package:spare_kart/data/models/models.dart';
import 'package:spare_kart/core/services/cashfree_checkout_service.dart';
import 'package:spare_kart/data/models/chat_payment.dart';
import 'package:spare_kart/data/models/chat_transaction.dart';
import 'package:spare_kart/data/repositories/chat_transaction_repository.dart';
import 'package:spare_kart/data/repositories/chat_payment_repository.dart';
import 'package:spare_kart/data/repositories/listings_repository.dart';
import 'package:spare_kart/features/messages/chat_flow.dart';
import 'package:spare_kart/features/messages/chat_session_store.dart';

class ChatArgs {
  const ChatArgs({this.thread, this.part});

  final MessageThread? thread;
  final Part? part;

  bool get isNewGuidedChat => part != null;
}

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key, this.args});

  final ChatArgs? args;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _locationService = const LocationService();
  final _paymentRepository = ChatPaymentRepository();
  final _transactionRepository = ChatTransactionRepository();
  final _listingsRepository = ListingsRepository();
  final _cashfreeCheckout = CashfreeCheckoutService();

  late List<ChatMessage> _messages;
  ChatSession? _session;
  Part? _listingPart;
  ChatPayment? _chatPayment;
  ChatTransaction? _chatTransaction;
  DeliveryPartnerRating? _deliveryRating;
  ChatFlowStep _flowStep = ChatFlowStep.completed;
  bool _isGuided = false;
  bool _busy = false;
  bool _loading = true;
  String? _initError;
  bool _pendingDeliveryLocationShare = false;
  bool _deliveryLocationLoading = false;
  String? _deliveryLocationError;
  String? _fetchedDeliveryAddress;
  LocationSettingsAction _deliveryLocationSettingsAction = LocationSettingsAction.none;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messages = [];
    _controller.addListener(_onComposerChanged);
    ChatSessionStore.instance.addListener(_onSessionUpdated);
    _initChat();
  }

  void _onComposerChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ChatSessionStore.instance.removeListener(_onSessionUpdated);
    _controller.removeListener(_onComposerChanged);
    FocusManager.instance.primaryFocus?.unfocus();
    _controller.dispose();
    _scrollController.dispose();
    _cashfreeCheckout.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  void _onSessionUpdated() {
    if (!mounted || _session == null) return;
    final fresh = ChatSessionStore.instance.get(_session!.id);
    if (fresh == null) return;
    _safeSetState(() {
      _session = fresh;
      _messages = List.from(fresh.messages);
      _isGuided = fresh.isGuided;
      _flowStep = fresh.flowStep;
    });
    if (!mounted) return;
    unawaited(_syncRealtimeSessionState());
  }

  Future<void> _syncRealtimeSessionState() async {
    if (!mounted || _session == null) return;

    _applyFlowNormalization(persist: false);
    await _refreshChatPayment();
    await _refreshChatTransaction();
    if (!mounted) return;

    _applyFlowNormalization(persist: false);
    _scrollToBottom();
    _prefillInitialMessage();
    await _markAsRead();
  }

  @override
  void activate() {
    super.activate();
    _reloadFromStore();
    _markAsRead();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_pendingDeliveryLocationShare) return;
    _pendingDeliveryLocationShare = false;
    _retryDeliveryLocationAfterSettings();
  }

  Future<void> _retryDeliveryLocationAfterSettings() async {
    if (!mounted || _flowStep != ChatFlowStep.awaitingBuyerLocationForDelivery) return;
    final success = await _shareCurrentDeliveryLocation(showSettingsDialog: false);
    if (success && mounted) {
      await _afterFulfillmentReady();
    }
  }

  Future<void> _initChat() async {
    if (!mounted) return;
    _safeSetState(() {
      _loading = true;
      _initError = null;
    });

    try {
      final args = widget.args;
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        _safeSetState(() {
          _messages = [];
          _flowStep = ChatFlowStep.completed;
          _initError = 'Sign in to use messages.';
        });
        return;
      }

      if (args?.isNewGuidedChat == true) {
        final part = args!.part!;
        final authUser = context.read<AuthBloc>().state.user;
        _session = await ChatSessionStore.instance.startGuidedSession(
          listingId: part.id,
          partTitle: part.fullTitle,
          sellerName: part.sellerName,
          sellerId: part.sellerId,
          buyerId: userId,
          buyerName: authUser?.name ?? 'Guest',
          listPrice: part.price,
          pickupLocation: part.location,
        );
      } else {
        final thread = args?.thread;
        if (thread != null) {
          _session = await ChatSessionStore.instance.loadSession(thread.id, userId);
        }
      }

      if (!mounted) return;

      if (_session != null) {
        _messages = List.from(_session!.messages);
        _isGuided = _session!.isGuided;
        _flowStep = _session!.flowStep;
        await _loadListingPart();
        await _syncRealtimeSessionState();
        if (!mounted) return;
        _prefillInitialMessage();
        _scrollToBottom();
      } else {
        _messages = [];
        _flowStep = ChatFlowStep.completed;
      }
    } catch (e) {
      _initError = e.toString();
    } finally {
      _safeSetState(() => _loading = false);
    }
  }

  void _prefillInitialMessage() {
    // First message is sent via WhatsApp-style quick reply bubble.
  }

  void _reloadFromStore() {
    if (!mounted || _session == null) return;
    final fresh = ChatSessionStore.instance.get(_session!.id);
    if (fresh == null) return;
    _safeSetState(() {
      _session = fresh;
      _messages = List.from(fresh.messages);
      _isGuided = fresh.isGuided;
      _flowStep = fresh.flowStep;
    });
    if (!mounted) return;
    unawaited(_syncRealtimeSessionState());
  }

  Future<void> _markAsRead() async {
    if (!mounted || _session == null) return;
    final asSeller = _showSellerControls;
    await ChatSessionStore.instance.markRead(_session!, isSeller: asSeller);
    if (!mounted) return;
    _syncThread();
  }

  void _syncThread() {
    if (_session == null) return;
    context.read<MessagesBloc>().add(
          MessagesThreadUpserted(_session!.toThread(currentUserId: _currentUserId)),
        );
  }

  Future<void> _persistSession() async {
    if (_session == null) return;
    await ChatSessionStore.instance.save(_session!);
  }

  String? get _currentUserId => Supabase.instance.client.auth.currentUser?.id;

  bool get _isSeller => context.read<AppModeBloc>().state.isAdmin;

  bool get _isActingAsBuyer {
    final userId = _currentUserId;
    if (_session?.buyerId != null && userId != null) {
      return _session!.buyerId == userId;
    }
    return !_isSeller;
  }

  bool get _isActingAsSeller {
    final userId = _currentUserId;
    if (_session?.sellerId != null && userId != null) {
      return _session!.sellerId == userId;
    }
    return _isSeller;
  }

  bool get _showSellerControls => _isActingAsSeller;

  void _applyFlowNormalization({bool persist = false}) {
    if (!mounted || _session == null) return;
    final before = _session!.flowStep;
    _session!.normalizeFlowStep();

    var nextStep = _session!.flowStep;

    if (_chatTransaction != null) {
      final txStep = _transactionRepository.flowStepForTransaction(_chatTransaction);
      if (_deliveryRating != null && txStep == ChatFlowStep.awaitingDeliveryPartnerRating) {
        nextStep = ChatFlowStep.completed;
      } else {
        nextStep = txStep;
      }
      _session!.flowStep = nextStep;
    }

    _safeSetState(() => _flowStep = nextStep);
    if (persist && _session!.flowStep != before) {
      _persistSession();
    }
  }

  String get _participantName {
    if (_session != null) {
      return _showSellerControls ? _session!.buyerName : _session!.sellerName;
    }
    return widget.args?.thread?.participantName ?? 'Seller';
  }

  String? get _partTitle => _session?.partTitle ?? widget.args?.thread?.partTitle;

  bool get _canOpenSellerProfile =>
      _isActingAsBuyer && _session?.sellerId?.isNotEmpty == true;

  Future<void> _loadListingPart() async {
    if (widget.args?.part != null) {
      _listingPart = widget.args!.part;
      return;
    }

    final listingId = _session?.listingId;
    if (listingId == null || listingId.isEmpty) return;

    try {
      _listingPart = await _listingsRepository.fetchListingById(listingId);
    } catch (_) {
      // Seller profile can still open with a fallback part.
    }
  }

  Future<void> _openSellerProfile() async {
    if (!_canOpenSellerProfile) return;

    final part = _listingPart ?? widget.args?.part ?? _fallbackPartForSellerProfile();
    if (part == null) return;

    await Navigator.pushNamed(context, AppRoutes.sellerProfile, arguments: part);
  }

  Part? _fallbackPartForSellerProfile() {
    final session = _session;
    final sellerId = session?.sellerId;
    if (sellerId == null || sellerId.isEmpty) return null;

    return Part(
      id: session?.listingId ?? sellerId,
      name: _partTitle ?? session!.sellerName,
      category: '',
      make: '',
      model: '',
      year: 0,
      condition: PartCondition.used,
      price: session?.listPrice ?? 0,
      location: session?.pickupLocation ?? '',
      sellerId: sellerId,
      sellerName: session?.sellerName ?? 'Seller',
      imageUrl: '',
      description: '',
    );
  }

  Widget _buildAppBarTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_participantName, style: const TextStyle(fontSize: 16)),
        if (_partTitle != null)
          Text(
            _partTitle!,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.normal,
            ),
          ),
      ],
    );
  }

  bool _isFromCurrentUser(ChatMessage msg) {
    final userId = _currentUserId;
    if (msg.senderId != null && userId != null) {
      return msg.senderId == userId;
    }
    return _showSellerControls ? !msg.isMe : msg.isMe;
  }

  bool get _isPrefilledOnly =>
      _isGuided &&
      _isActingAsBuyer &&
      _flowStep == ChatFlowStep.started &&
      _messages.isEmpty;

  bool get _isWaitingForSeller =>
      _isGuided && _isActingAsBuyer && _flowStep == ChatFlowStep.awaitingAvailability;

  bool get _isBuyerBlocked =>
      _isActingAsBuyer && _isGuided && (_session?.isBuyerBlocked ?? false);

  bool get _isInHandoverPhase {
    if (_flowStep == ChatFlowStep.completed) return false;
    return _chatPayment?.isPaid == true &&
        (_chatTransaction != null || ChatFlow.isHandoverFlowStep(_flowStep));
  }

  bool get _isFreeChatPhase {
    if (_flowStep == ChatFlowStep.completed) return false;
    if (_isInHandoverPhase) return false;
    if (_flowStep == ChatFlowStep.freeChat) {
      return true;
    }
    final session = _session;
    if (session == null) return false;
    if (_chatPayment?.isPaid == true &&
        ChatFlow.isDeliveryFlowComplete(
          messages: _messages,
          buyerId: session.buyerId,
          sellerId: session.sellerId,
        )) {
      return false;
    }
    return ChatFlow.isDeliveryFlowComplete(
      messages: _messages,
      buyerId: session.buyerId,
      sellerId: session.sellerId,
    );
  }

  ChatFulfillmentMode get _fulfillmentMode => ChatFlow.resolveFulfillmentMode(
        messages: _messages,
        buyerId: _session?.buyerId,
        sellerDeliveryOffer: _session?.sellerDeliveryOffer,
      );

  int? get _lastBuyerReductionAsk {
    final buyerId = _session?.buyerId;
    if (buyerId == null) return null;
    for (var i = _messages.length - 1; i >= 0; i--) {
      final msg = _messages[i];
      if (msg.senderId != buyerId) continue;
      final amount = ChatFlow.parseReductionAsk(msg.text);
      if (amount != null) return amount;
    }
    return null;
  }

  List<ChatFlowOption> get _flowOptions {
    if (!_isGuided || (_isBuyerBlocked && _isActingAsBuyer)) return [];
    if (_isFreeChatPhase) return [];

    if (_isActingAsSeller) {
      return ChatFlow.sellerOptions(
        _flowStep,
        listPrice: _session?.listPrice,
        lastReductionAsk: _lastBuyerReductionAsk,
        buyerDeliveryAsk: _session?.buyerDeliveryAsk,
        fulfillmentMode: _fulfillmentMode,
        agreedPrice: _session?.agreedPrice,
      );
    }
    if (_isActingAsBuyer) {
      return ChatFlow.buyerOptions(
        _flowStep,
        agreedPrice: _session?.agreedPrice,
        listPrice: _session?.listPrice,
        sellerDeliveryOffer: _session?.sellerDeliveryOffer,
        buyerDeliveryAsk: _session?.buyerDeliveryAsk,
        fulfillmentMode: _fulfillmentMode,
      );
    }
    return [];
  }

  List<ChatFlowOption> get _displayQuickReplies {
    if (_isPrefilledOnly) {
      return const [
        ChatFlowOption(
          id: 'ask_available',
          label: 'Is the item still available?',
          message: ChatFlow.initialBuyerMessage,
          nextStep: ChatFlowStep.awaitingAvailability,
        ),
      ];
    }
    return _flowOptions;
  }

  bool get _showQuickReplies => _displayQuickReplies.isNotEmpty;

  String? get _quickReplyPrompt {
    if (_isPrefilledOnly) return null;
    if (_showSellerControls && _flowStep == ChatFlowStep.awaitingAvailability) {
      return 'Please choose your response:';
    }
    if (_isActingAsBuyer && _flowStep == ChatFlowStep.awaitingPriceAsk) {
      return 'Ask the seller:';
    }
    if (_isActingAsBuyer && _flowStep == ChatFlowStep.awaitingNegotiation) {
      return 'Negotiate the price:';
    }
    if (_showSellerControls && _flowStep == ChatFlowStep.awaitingNegotiationReply) {
      return 'Respond to the buyer:';
    }
    if (_isActingAsBuyer && _flowStep == ChatFlowStep.awaitingBuyIntent) {
      return 'Ready to purchase? You can still negotiate:';
    }
    if (_isActingAsBuyer && _flowStep == ChatFlowStep.awaitingTokenPayment) {
      return 'Send 1% advance token:';
    }
    if (_showSellerControls && _flowStep == ChatFlowStep.awaitingSellerReplyForDelivery) {
      return 'Respond to the buyer:';
    }
    if (_isActingAsBuyer && _flowStep == ChatFlowStep.awaitingDeliveryChoice) {
      if (_session?.sellerDeliveryOffer == 'both_available') {
        return 'Choose delivery option:';
      }
      return 'Ask about delivery:';
    }
    if (_isActingAsBuyer && _flowStep == ChatFlowStep.awaitingBuyerLocationForDelivery) {
      return 'Share your delivery location:';
    }
    if (_showSellerControls && _flowStep == ChatFlowStep.awaitingSellerHandoff) {
      return _fulfillmentMode == ChatFulfillmentMode.pickup
          ? 'Mark item ready for pickup:'
          : 'Mark item as dispatched:';
    }
    if (_isActingAsBuyer && _flowStep == ChatFlowStep.awaitingBuyerReceipt) {
      return 'Confirm after you receive the item:';
    }
    if (_showSellerControls && _flowStep == ChatFlowStep.awaitingSellerConfirm) {
      return 'Confirm handover:';
    }
    if (_isActingAsBuyer && _flowStep == ChatFlowStep.awaitingDeliveryPartnerRating) {
      return _fulfillmentMode == ChatFulfillmentMode.pickup
          ? 'Rate the seller:'
          : 'Rate your delivery experience:';
    }
    if (_flowStep == ChatFlowStep.disputeOpen) {
      return 'Issue reported:';
    }
    return null;
  }

  String? get _quickReplyNote {
    if (_showSellerControls && _flowStep == ChatFlowStep.awaitingNegotiationReply) {
      return ChatFlow.sellerNegotiationReplyNote;
    }
    if (_isActingAsBuyer && _flowStep == ChatFlowStep.awaitingBuyerLocationForDelivery) {
      return 'Use GPS or type your delivery address manually.';
    }
    return null;
  }

  Future<void> _refreshChatPayment() async {
    final session = _session;
    if (session == null) return;

    try {
      final payment = await _paymentRepository.fetchLatestForThread(session.id);
      if (!mounted) return;

      _safeSetState(() => _chatPayment = payment);

      if (payment?.isPaid == true && _flowStep == ChatFlowStep.awaitingTokenPayment) {
        await _advanceFlow(ChatFlowStep.awaitingDeliveryChoice);
      }
      if (payment?.isPaid == true &&
          ChatFlow.isDeliveryFlowComplete(
            messages: _messages,
            buyerId: session.buyerId,
            sellerId: session.sellerId,
          ) &&
          !ChatFlow.isHandoverFlowStep(_flowStep) &&
          _flowStep != ChatFlowStep.completed) {
        await _ensureHandoverTransaction();
      }
      _scrollToBottom();
    } catch (_) {
      // Payment lookup is optional until buyer reaches checkout.
    }
  }

  Future<void> _refreshChatTransaction() async {
    final session = _session;
    if (session == null) return;

    try {
      final transaction = await _transactionRepository.fetchForThread(session.id);
      DeliveryPartnerRating? rating;
      if (transaction != null) {
        rating = await _transactionRepository.fetchRatingForTransaction(transaction.id);
      }
      if (!mounted) return;

      _safeSetState(() {
        _chatTransaction = transaction;
        _deliveryRating = rating;
      });

      if (transaction != null) {
        final step = _transactionRepository.flowStepForTransaction(transaction);
        final resolvedStep =
            rating != null && step == ChatFlowStep.awaitingDeliveryPartnerRating
                ? ChatFlowStep.completed
                : step;
        if (_flowStep != resolvedStep) {
          _safeSetState(() => _flowStep = resolvedStep);
          if (_session != null) {
            _session!.flowStep = resolvedStep;
            ChatSessionStore.instance.cacheSession(_session!);
          }
        }
      }
    } catch (_) {
      // Handover tables may be missing until migration is applied.
    }
  }

  Future<void> _ensureHandoverTransaction() async {
    final session = _session;
    final payment = _chatPayment;
    if (session == null || payment?.isPaid != true) return;
    if (session.buyerId == null || session.sellerId == null) return;

    final agreedPrice = session.agreedPrice ?? session.listPrice;
    if (agreedPrice <= 0) return;

    try {
      final transaction = await _transactionRepository.ensureTransaction(
        threadId: session.id,
        buyerId: session.buyerId!,
        sellerId: session.sellerId!,
        fulfillmentMode: _fulfillmentMode,
        agreedPrice: agreedPrice,
        tokenAmount: payment!.tokenAmount,
        advancePaymentId: payment.id,
      );
      if (!mounted) return;
      _safeSetState(() => _chatTransaction = transaction);
    } catch (_) {
      // Optional until migration is applied.
    }
  }

  Future<void> _afterFulfillmentReady() async {
    await _refreshChatPayment();
    if (_chatPayment?.isPaid == true) {
      await _ensureHandoverTransaction();
      final step =
          _transactionRepository.flowStepForTransaction(_chatTransaction);
      await _advanceFlow(step);
    } else {
      await _advanceFlow(ChatFlowStep.freeChat);
    }
  }

  Future<void> _startCashfreePayment() async {
    final session = _session;
    if (session == null || _busy) return;

    final agreedPrice = session.agreedPrice ?? session.listPrice;
    if (agreedPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agreed price is not set yet.')),
      );
      return;
    }

    _safeSetState(() => _busy = true);
    try {
      final checkout = await _paymentRepository.createCheckoutSession(session.id);
      final result = await _cashfreeCheckout.openCheckout(checkout);
      final tokenAmount = await _paymentRepository.verifyPayment(
        threadId: session.id,
        orderId: result.orderId,
      );

      final agreedPrice = session.agreedPrice ?? session.listPrice;
      await _sendMessage(
        ChatFlow.advanceTokenPaidMessage(
          tokenAmount: tokenAmount,
          agreedPrice: agreedPrice,
        ),
        isBuyer: true,
      );
      await _advanceFlow(ChatFlowStep.awaitingDeliveryChoice);
      await _refreshChatPayment();
    } on CashfreeCheckoutException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } on ChatPaymentException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $error')),
      );
    } finally {
      if (mounted) _safeSetState(() => _busy = false);
    }
  }

  void _scrollToBottom({bool animated = false}) {
    void scrollNow() {
      if (!mounted || !_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          max,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(max);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollNow();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollNow();
      });
    });
  }

  Future<void> _advanceFlow(
    ChatFlowStep nextStep, {
    DateTime? blockedUntil,
    double? agreedPrice,
  }) async {
    _safeSetState(() {
      _flowStep = nextStep;
      if (_session != null) {
        _session!.flowStep = nextStep;
        if (blockedUntil != null) _session!.blockedUntil = blockedUntil;
        if (agreedPrice != null) _session!.agreedPrice = agreedPrice;
      }
    });
    if (_session != null) {
      ChatSessionStore.instance.cacheSession(_session!);
    }
    await _persistSession();
    _scrollToBottom();
  }

  Future<bool> _sendMessage(
    String text, {
    required bool isBuyer,
    String? imagePath,
    bool bypassBusy = false,
  }) async {
    if (_session == null || (!bypassBusy && _busy)) return false;
    final senderId = _currentUserId;
    if (senderId == null) return false;

    setState(() => _busy = true);
    try {
      await ChatSessionStore.instance.sendMessage(
        session: _session!,
        senderId: senderId,
        text: text,
        localImagePath: imagePath,
      );
      if (!mounted) return false;
      setState(() {
        _messages = List.from(_session!.messages);
      });
      _scrollToBottom(animated: true);
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onFlowOption(ChatFlowOption option) async {
    final isBuyerReply = _isActingAsBuyer && !_isSeller;
    await _sendMessage(option.message, isBuyer: isBuyerReply);

    if (option.id == 'no') {
      final blockedUntil = DateTime.now().add(ChatFlow.buyerBlockDuration);
      await _advanceFlow(ChatFlowStep.buyerBlockedAfterNo, blockedUntil: blockedUntil);
      return;
    }

    if (option.id == 'now_available') {
      if (_session != null) {
        _session!.blockedUntil = null;
      }
      await _advanceFlow(ChatFlowStep.awaitingPriceAsk);
      return;
    }

    await _advanceFlow(option.nextStep);
  }

  Future<void> _sendFreeText() async {
    if (_busy || !mounted) return;
    final text = _controller.text.trim();
    final error = FormValidators.messageText(text);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final isBuyer = _isActingAsBuyer && !_isSeller;
    final previousStep = _flowStep;
    await _sendMessage(text, isBuyer: isBuyer);
    _controller.clear();

    if (_isGuided) {
      if (previousStep == ChatFlowStep.started && isBuyer) {
        await _advanceFlow(ChatFlowStep.awaitingAvailability);
        return;
      }
      if (_showSellerControls) {
        final lower = text.toLowerCase();
        if (lower.contains('delivery and payment confirmed') ||
            lower.contains('pickup and payment confirmed')) {
          final transaction = _chatTransaction;
          if (transaction != null) {
            final updated = await _transactionRepository.markSellerConfirmed(
              transactionId: transaction.id,
            );
            if (mounted) _safeSetState(() => _chatTransaction = updated);
          }
          await _advanceFlow(ChatFlowStep.awaitingDeliveryPartnerRating);
          return;
        }
      }
    }
  }

  Future<void> _pickAvailabilityDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'When will the item be available?',
    );
    if (picked == null || !mounted) return;

    final formatted = DateFormat('d MMM yyyy').format(picked);
    await _sendMessage('The item will be available on $formatted.', isBuyer: false);
    setState(() {
      _session?.availabilityDate = picked;
    });
    await _advanceFlow(ChatFlowStep.awaitingPriceAsk);
  }

  Future<void> _setSellerPrice() async {
    final existing = _session?.agreedPrice ?? _session?.listPrice;
    final initial = existing != null && existing > 0
        ? existing.toStringAsFixed(0)
        : '';

    final listPrice = _session?.listPrice;
    final price = await showDialog<double>(
      context: context,
      builder: (ctx) => _SetPriceDialog(
        initialPrice: initial,
        hint: ChatFlow.sellerPriceSetNote(
          listPrice: listPrice != null && listPrice > 0 ? listPrice : null,
        ),
      ),
    );

    if (price == null || !mounted) return;

    await _sendMessage(
      'The price is ${ChatFlow.formatPrice(price)}.',
      isBuyer: false,
    );
    await _advanceFlow(ChatFlowStep.awaitingNegotiation, agreedPrice: price);
  }

  Future<void> _askCustomReduction() async {
    final currentPrice = _session?.agreedPrice ?? _session?.listPrice ?? 0;
    if (currentPrice <= 0 || !mounted) return;

    final maxReduction = currentPrice.floor() - 1;
    if (maxReduction < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Price is too low to request a reduction.')),
      );
      return;
    }

    final reduction = await showDialog<int>(
      context: context,
      builder: (ctx) => _ReductionAmountDialog(maxReduction: maxReduction),
    );
    if (reduction == null || !mounted) return;

    await _sendMessage(
      'Can you reduce the amount by ${ChatFlow.formatPrice(reduction.toDouble())}?',
      isBuyer: true,
    );
    await _advanceFlow(ChatFlowStep.awaitingNegotiationReply);
  }

  Future<void> _acceptBuyerReduction(ChatFlowOption option) async {
    final reduction = option.reductionAmount;
    if (reduction == null || reduction <= 0) return;

    final currentPrice = _session?.agreedPrice ?? _session?.listPrice ?? 0;
    if (currentPrice <= reduction) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reduction is larger than the current price.')),
      );
      return;
    }

    final newPrice = currentPrice - reduction;
    await _sendMessage(
      'Yes, I can reduce the price by ${ChatFlow.formatPrice(reduction.toDouble())}. '
      'The new price is ${ChatFlow.formatPrice(newPrice)}.',
      isBuyer: false,
    );
    await _advanceFlow(ChatFlowStep.awaitingBuyIntent, agreedPrice: newPrice);
  }

  Future<void> _setLastOfferedPrice() async {
    final existing = _session?.agreedPrice ?? _session?.listPrice;
    final initial = existing != null && existing > 0
        ? existing.toStringAsFixed(0)
        : '';

    final price = await showDialog<double>(
      context: context,
      builder: (ctx) => _SetPriceDialog(
        initialPrice: initial,
        title: 'Fixed last price',
        label: 'Last price (₹)',
        hint: 'Enter the final price after negotiation. This will be the fixed last price offered to the buyer.',
      ),
    );

    if (price == null || !mounted) return;

    await _sendMessage(
      'Yes, this is the last price I can offer: ${ChatFlow.formatPrice(price)}.',
      isBuyer: false,
    );
    await _advanceFlow(ChatFlowStep.awaitingBuyIntent, agreedPrice: price);
  }

  Future<void> _handleBuyerDeliveryAsk(ChatFlowOption option) async {
    await _sendMessage(option.message, isBuyer: true);
    _safeSetState(() => _session?.buyerDeliveryAsk = option.id);
    await _persistSession();
    await _advanceFlow(ChatFlowStep.awaitingSellerReplyForDelivery);
  }

  Future<void> _handleSellerDeliveryOffer(ChatFlowOption option) async {
    await _sendMessage(option.message, isBuyer: false);
    _safeSetState(() {
      _session?.sellerDeliveryOffer = option.id;
      _session?.sellerRepliedAfterToken = true;
    });
    await _persistSession();

    if (option.id == 'pickup_only' || option.id == 'pickup_yes') {
      final location = _session?.pickupLocation ?? 'Pickup location not set';
      await _sendMessage('Pickup location: $location', isBuyer: false);
      await _afterFulfillmentReady();
      return;
    }

    if (option.id == 'doorstep_yes' || option.id == 'doorstep_only') {
      await _advanceFlow(ChatFlowStep.awaitingBuyerLocationForDelivery);
      return;
    }

    if (option.id == 'both_available') {
      await _advanceFlow(ChatFlowStep.awaitingDeliveryChoice);
    }
  }

  Future<void> _handleBuyerLocationShare() async {
    final success = await _shareCurrentDeliveryLocation();
    if (success && mounted) {
      await _afterFulfillmentReady();
    }
  }

  Future<bool> _shareCurrentDeliveryLocation({bool showSettingsDialog = true}) async {
    if (_busy && !_deliveryLocationLoading) return false;

    setState(() {
      _deliveryLocationLoading = true;
      _deliveryLocationError = null;
      _fetchedDeliveryAddress = null;
      _deliveryLocationSettingsAction = LocationSettingsAction.none;
    });
    _scrollToBottom();

    try {
      final location = await _locationService.getCurrentLocation();
      if (!mounted) return false;

      setState(() => _fetchedDeliveryAddress = location.address);
      _scrollToBottom();

      final sent = await _sendMessage(
        'Delivery location: ${location.address}',
        isBuyer: true,
        bypassBusy: true,
      );
      if (!mounted) return false;

      if (!sent) {
        setState(() {
          _deliveryLocationLoading = false;
          _deliveryLocationError = 'Could not send your delivery location. Please try again.';
        });
        _scrollToBottom();
        return false;
      }

      setState(() {
        _deliveryLocationLoading = false;
        _deliveryLocationError = null;
        _fetchedDeliveryAddress = null;
        _deliveryLocationSettingsAction = LocationSettingsAction.none;
        _pendingDeliveryLocationShare = false;
      });
      return true;
    } on LocationServiceException catch (e) {
      if (!mounted) return false;

      setState(() {
        _deliveryLocationLoading = false;
        _deliveryLocationError = e.message;
        _fetchedDeliveryAddress = null;
        _deliveryLocationSettingsAction = e.settingsAction;
      });
      _scrollToBottom();

      if (!showSettingsDialog) {
        return false;
      }

      final openedSettings = await handleLocationServiceException(
        context,
        e,
        title: 'Location required for delivery',
      );
      if (openedSettings) {
        setState(() => _pendingDeliveryLocationShare = true);
      }
      return false;
    } catch (e) {
      if (!mounted) return false;
      setState(() {
        _deliveryLocationLoading = false;
        _deliveryLocationError = 'Failed to get location: $e';
        _fetchedDeliveryAddress = null;
      });
      _scrollToBottom();
      return false;
    }
  }

  Future<void> _openDeliveryLocationSettings() async {
    if (_deliveryLocationSettingsAction == LocationSettingsAction.none) return;

    setState(() => _pendingDeliveryLocationShare = true);
    await LocationService.openSettingsFor(
      LocationServiceException(
        _deliveryLocationError ?? '',
        settingsAction: _deliveryLocationSettingsAction,
      ),
    );
  }

  Future<void> _handleDeliveryPreference(ChatFlowOption option) async {
    await _sendMessage(option.message, isBuyer: true);
    setState(() => _session?.deliveryChoiceMade = true);

    if (option.id == 'pickup') {
      final location = _session?.pickupLocation ?? 'Pickup location not set';
      await _sendMessage('Pickup location: $location', isBuyer: false);
      await _afterFulfillmentReady();
      return;
    }

    if (option.id == 'doorstep') {
      await _advanceFlow(ChatFlowStep.awaitingBuyerLocationForDelivery);
      return;
    }

    if (option.id == 'both') {
      final location = _session?.pickupLocation ?? 'Pickup location not set';
      await _sendMessage('Pickup location: $location', isBuyer: false);
      await _advanceFlow(ChatFlowStep.awaitingBuyerLocationForDelivery);
    }
  }

  Future<void> _enterManualDeliveryAddress() async {
    final address = await showDialog<String>(
      context: context,
      builder: (context) => const _DeliveryAddressDialog(),
    );
    if (address == null || !mounted) return;

    setState(() {
      _deliveryLocationLoading = false;
      _deliveryLocationError = null;
      _pendingDeliveryLocationShare = false;
      _deliveryLocationSettingsAction = LocationSettingsAction.none;
    });

    await _sendMessage('Delivery location: $address', isBuyer: true);
    if (!mounted) return;
    if (!_messages.any((m) => m.text == 'Delivery location: $address')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send delivery address. Please try again.')),
      );
      return;
    }
    await _afterFulfillmentReady();
  }

  Widget _buildDateSeparator(DateTime time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.chipBg.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            formatChatDateSeparator(time),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, Responsive r) {
    final isMine = _isFromCurrentUser(msg);
    final timeLabel = formatChatMessageTime(msg.timestamp);
    final timeColor = isMine ? Colors.white.withValues(alpha: 0.75) : AppColors.textSecondary;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: r.width * 0.75),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : const Color.fromARGB(255, 211, 221, 229),
          borderRadius: BorderRadius.circular(16),
        
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.hasImage)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ListingImage(
                    url: msg.imagePath!,
                    width: r.width * 0.55,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            if (msg.text.isNotEmpty)
              Text(
                msg.text,
                style: TextStyle(color: isMine ? Colors.white : AppColors.textPrimary),
              ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                timeLabel,
                style: TextStyle(fontSize: 11, color: timeColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSellerDispatch(ChatFlowOption option) async {
    String? partnerName;
    if (option.id == 'dispatched') {
      partnerName = await showDialog<String>(
        context: context,
        builder: (ctx) => const _DeliveryPartnerDialog(),
      );
      if (!mounted || partnerName == null) return;
    }

    final message = option.id == 'ready_pickup'
        ? ChatFlow.sellerReadyPickupMessage
        : ChatFlow.sellerDispatchedMessage(deliveryPartnerName: partnerName);

    await _sendMessage(message, isBuyer: false);

    final transaction = _chatTransaction;
    if (transaction != null) {
      final updated = await _transactionRepository.markDispatched(
        transactionId: transaction.id,
        deliveryPartnerName: partnerName,
      );
      if (!mounted) return;
      _safeSetState(() => _chatTransaction = updated);
    }

    await _advanceFlow(ChatFlowStep.awaitingBuyerReceipt);
  }

  Future<void> _handleBuyerReceiptConfirm(ChatFlowOption option) async {
    await _sendMessage(option.message, isBuyer: true);

    final transaction = _chatTransaction;
    if (transaction == null) {
      await _advanceFlow(option.nextStep);
      return;
    }

    if (option.id == 'report_issue') {
      final updated = await _transactionRepository.markBuyerDispute(
        transactionId: transaction.id,
        reason: option.message,
      );
      if (!mounted) return;
      _safeSetState(() => _chatTransaction = updated);
      await _advanceFlow(ChatFlowStep.disputeOpen);
      return;
    }

    final updated = await _transactionRepository.markBuyerConfirmed(
      transactionId: transaction.id,
    );
    if (!mounted) return;
    _safeSetState(() => _chatTransaction = updated);
    await _advanceFlow(ChatFlowStep.awaitingSellerConfirm);
  }

  Future<void> _handleSellerHandoffConfirm(ChatFlowOption option) async {
    await _sendMessage(option.message, isBuyer: false);

    final transaction = _chatTransaction;
    if (transaction == null) {
      await _advanceFlow(option.nextStep);
      return;
    }

    if (option.id == 'seller_dispute') {
      final updated = await _transactionRepository.markSellerDispute(
        transactionId: transaction.id,
        reason: option.message,
      );
      if (!mounted) return;
      _safeSetState(() => _chatTransaction = updated);
      await _advanceFlow(ChatFlowStep.disputeOpen);
      return;
    }

    final updated = await _transactionRepository.markSellerConfirmed(
      transactionId: transaction.id,
    );
    if (!mounted) return;
    _safeSetState(() => _chatTransaction = updated);
    await _advanceFlow(ChatFlowStep.awaitingDeliveryPartnerRating);
  }

  Future<void> _requestAdvanceRefund() async {
    final payment = _chatPayment;
    if (payment == null || !payment.isPaid || _busy) return;

    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => const _RefundReasonDialog(),
    );
    if (reason == null || !mounted) return;

    _safeSetState(() => _busy = true);
    try {
      await _paymentRepository.requestRefund(
        paymentId: payment.id,
        reason: reason,
      );
      final transaction = _chatTransaction;
      if (transaction != null) {
        final updated = await _transactionRepository.markRefundRequested(transaction.id);
        if (mounted) _safeSetState(() => _chatTransaction = updated);
      }
      await _refreshChatPayment();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refund request submitted for admin review.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to request refund: $error')),
      );
    } finally {
      if (mounted) _safeSetState(() => _busy = false);
    }
  }

  Future<void> _openDeliveryPartnerRating() async {
    final transaction = _chatTransaction;
    if (transaction == null || _busy || !_isActingAsBuyer) return;

    final isPickup = transaction.isPickup;
    final ratedPartyName = isPickup
        ? _session?.sellerName ?? 'Seller'
        : transaction.deliveryPartnerName ?? 'Delivery partner';

    final result = await showDialog<({int rating, String? review})>(
      context: context,
      builder: (ctx) => _DeliveryPartnerRatingDialog(
        title: isPickup ? 'Rate seller' : 'Rate delivery partner',
        partnerName: ratedPartyName,
      ),
    );
    if (result == null || !mounted) return;

    _safeSetState(() => _busy = true);
    try {
      final rating = await _transactionRepository.submitDeliveryRating(
        transaction: transaction,
        rating: result.rating,
        reviewText: result.review,
        ratedPartyName: ratedPartyName,
      );
      if (!mounted) return;
      _safeSetState(() => _deliveryRating = rating);
      await _refreshChatTransaction();
      await _advanceFlow(ChatFlowStep.completed);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            transaction.isPickup
                ? 'Thanks for rating the seller.'
                : 'Thanks for rating the delivery partner.',
          ),
        ),
      );
    } on ChatTransactionException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit rating: $error')),
      );
    } finally {
      if (mounted) _safeSetState(() => _busy = false);
    }
  }

  Future<void> _skipDeliveryPartnerRating() async {
    final transaction = _chatTransaction;
    if (transaction == null) {
      await _advanceFlow(ChatFlowStep.completed);
      return;
    }

    _safeSetState(() => _busy = true);
    try {
      await _transactionRepository.markCompleted(transaction.id);
      await _refreshChatTransaction();
      await _advanceFlow(ChatFlowStep.completed);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete transaction: $error')),
      );
    } finally {
      if (mounted) _safeSetState(() => _busy = false);
    }
  }

  Future<void> _onQuickReplyTap(ChatFlowOption option) async {
    if (_busy) return;

    if (option.id == 'ask_available') {
      await _sendMessage(option.message, isBuyer: true);
      await _advanceFlow(ChatFlowStep.awaitingAvailability);
      return;
    }

    if (_flowStep == ChatFlowStep.awaitingDeliveryChoice) {
      if (_session?.sellerDeliveryOffer == 'both_available') {
        await _handleDeliveryPreference(option);
      } else {
        await _handleBuyerDeliveryAsk(option);
      }
      return;
    }

    if (option.id == 'share_current_location') {
      await _handleBuyerLocationShare();
      return;
    }

    if (option.id == 'enter_delivery_address') {
      await _enterManualDeliveryAddress();
      return;
    }

    if (_showSellerControls && _flowStep == ChatFlowStep.awaitingSellerReplyForDelivery) {
      await _handleSellerDeliveryOffer(option);
      return;
    }

    if (option.id == 'accept_reduction') {
      await _acceptBuyerReduction(option);
      return;
    }

    if (option.id == 'last_price') {
      await _setLastOfferedPrice();
      return;
    }

    if (option.id == 'custom_reduction') {
      await _askCustomReduction();
      return;
    }

    if (_showSellerControls && _flowStep == ChatFlowStep.awaitingSellerHandoff) {
      await _handleSellerDispatch(option);
      return;
    }

    if (_isActingAsBuyer && _flowStep == ChatFlowStep.awaitingBuyerReceipt) {
      await _handleBuyerReceiptConfirm(option);
      return;
    }

    if (_showSellerControls && _flowStep == ChatFlowStep.awaitingSellerConfirm) {
      await _handleSellerHandoffConfirm(option);
      return;
    }

    if (option.id == 'rate_delivery_partner') {
      await _openDeliveryPartnerRating();
      return;
    }

    if (option.id == 'skip_delivery_rating') {
      await _skipDeliveryPartnerRating();
      return;
    }

    await _onFlowOption(option);
  }

  List<Widget> _buildChatListItems(Responsive r) {
    final items = <Widget>[];
    DateTime? previousDay;
    final paymentAnchor = _willingToBuyMessageIndex;
    final deliveryAnchor = _deliveryLocationAnchorIndex;
    final handoverAnchor = _handoverAnchorIndex;

    for (var i = 0; i < _messages.length; i++) {
      final msg = _messages[i];
      final day = DateTime(
        msg.timestamp.year,
        msg.timestamp.month,
        msg.timestamp.day,
      );
      if (previousDay == null || day != previousDay) {
        items.add(_buildDateSeparator(msg.timestamp));
        previousDay = day;
      }
      items.add(_buildMessageBubble(msg, r));

      if (paymentAnchor != null && i == paymentAnchor) {
        items.addAll(_inlinePaymentWidgets(r));
      }
      if (deliveryAnchor != null && i == deliveryAnchor) {
        items.addAll(_inlineDeliveryLocationWidgets(r));
      }
      if (handoverAnchor != null && i == handoverAnchor) {
        items.addAll(_inlineHandoverWidgets(r));
      }
    }

    if (paymentAnchor == null) {
      items.addAll(_inlinePaymentWidgets(r));
    }
    if (deliveryAnchor == null) {
      items.addAll(_inlineDeliveryLocationWidgets(r));
    }
    if (handoverAnchor == null) {
      items.addAll(_inlineHandoverWidgets(r));
    }

    if (_isWaitingForSeller) {
      items.add(_buildStatusBubble('Message sent. Waiting for seller to respond…', r));
    }
    if (_showSellerControls &&
        _flowStep == ChatFlowStep.awaitingDeliveryPartnerRating) {
      items.add(_buildStatusBubble('Waiting for buyer to rate the experience…', r));
    }
    if (_showQuickReplies) {
      items.add(_buildWhatsAppQuickReplyBubble(r));
    }

    return items;
  }

  List<Widget> _inlineDeliveryLocationWidgets(Responsive r) {
    if (!_showDeliveryLocationStatusInChat) return const [];
    return [_buildDeliveryLocationStatusCard(r)];
  }

  bool get _showDeliveryLocationStatusInChat =>
      _isActingAsBuyer &&
      !_showSellerControls &&
      _flowStep == ChatFlowStep.awaitingBuyerLocationForDelivery &&
      (_deliveryLocationLoading ||
          _deliveryLocationError != null ||
          _fetchedDeliveryAddress != null);

  int? get _deliveryLocationAnchorIndex {
    if (_flowStep != ChatFlowStep.awaitingBuyerLocationForDelivery) return null;

    final buyerId = _session?.buyerId;
    if (buyerId != null) {
      for (var i = _messages.length - 1; i >= 0; i--) {
        final msg = _messages[i];
        if (msg.senderId != buyerId) continue;
        final lower = msg.text.toLowerCase();
        if (lower.contains("i'd like doorstep delivery") ||
            lower.contains('both pickup and doorstep')) {
          return i;
        }
      }
    }

    return _messages.isEmpty ? null : _messages.length - 1;
  }

  Widget _buildDeliveryLocationStatusCard(Responsive r) {
    final canOpenSettings = _deliveryLocationSettingsAction != LocationSettingsAction.none;
    final settingsLabel = switch (_deliveryLocationSettingsAction) {
      LocationSettingsAction.openLocationSettings => 'Open Location Settings',
      LocationSettingsAction.openAppSettings => 'Open App Settings',
      LocationSettingsAction.none => 'Open Settings',
    };
    final hasFetchedAddress =
        _fetchedDeliveryAddress != null && _fetchedDeliveryAddress!.isNotEmpty;
    final isError = _deliveryLocationError != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: r.width * 0.92),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isError
                  ? AppColors.surface
                  : hasFetchedAddress
                      ? AppColors.successSoft
                      : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (isError
                        ? AppColors.warning
                        : hasFetchedAddress
                            ? AppColors.success
                            : AppColors.primary)
                    .withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isError
                          ? Icons.location_off_rounded
                          : hasFetchedAddress
                              ? Icons.check_circle_rounded
                              : Icons.my_location_rounded,
                      color: isError
                          ? AppColors.warning
                          : hasFetchedAddress
                              ? AppColors.success
                              : AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isError
                            ? 'Location access needed'
                            : hasFetchedAddress
                                ? 'Delivery location found'
                                : 'Getting your location...',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (_deliveryLocationLoading && !hasFetchedAddress)
                  const Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Please wait while we fetch your delivery address.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  )
                else if (hasFetchedAddress)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fetchedDeliveryAddress!,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Sending location to seller...',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  )
                else if (isError) ...[
                  Text(
                    _deliveryLocationError ?? 'Enable location to share your delivery address.',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (canOpenSettings)
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _busy ? null : _openDeliveryLocationSettings,
                            icon: const Icon(Icons.settings_rounded, size: 18),
                            label: Text(settingsLabel),
                          ),
                        ),
                      if (canOpenSettings) const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _handleBuyerLocationShare,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Try again'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  int? get _handoverAnchorIndex {
    if (!_isInHandoverPhase) return null;

    for (var i = _messages.length - 1; i >= 0; i--) {
      final text = _messages[i].text;
      if (text.startsWith('Delivery location:') || text.startsWith('Pickup location:')) {
        return i;
      }
    }
    return null;
  }

  List<Widget> _inlineHandoverWidgets(Responsive r) {
    if (!_isInHandoverPhase || _chatTransaction == null) return const [];

    final widgets = <Widget>[];
    final transaction = _chatTransaction!;

    if ((transaction.status == ChatTransactionStatus.buyerConfirmed ||
            transaction.status == ChatTransactionStatus.sellerConfirmed ||
            transaction.status == ChatTransactionStatus.completed) &&
        !transaction.isDispute) {
      widgets.add(_buildOfflinePaymentCard(r, transaction));
    }

    if (transaction.isCompleted) {
      widgets.add(_buildTransactionCompleteCard(r, transaction));
    }

    if (_deliveryRating != null) {
      widgets.add(_buildDeliveryRatingCard(r, _deliveryRating!));
    }

    if (transaction.isDispute) {
      widgets.add(_buildDisputeCard(r, transaction));
    }

    return widgets;
  }

  Widget _buildOfflinePaymentCard(Responsive r, ChatTransaction transaction) {
    final paidToLabel = transaction.isPickup
        ? 'Paid to seller (offline)'
        : 'Paid to delivery agent (offline)';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: r.width * 0.92),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.success),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Remaining balance paid offline',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _tokenBreakdownRow('Agreed item price', ChatFlow.formatPrice(transaction.agreedPrice)),
                const SizedBox(height: 6),
                _tokenBreakdownRow(
                  'Advance token (in app)',
                  ChatFlow.formatPrice(transaction.tokenAmount),
                ),
                const SizedBox(height: 6),
                _tokenBreakdownRow(
                  paidToLabel,
                  ChatFlow.formatPrice(transaction.remainingAmount),
                  emphasized: true,
                ),
                if (transaction.buyerConfirmedAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Buyer confirmed on ${DateFormat('d MMM yyyy, h:mm a').format(transaction.buyerConfirmedAt!)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCompleteCard(Responsive r, ChatTransaction transaction) {
    final completedAt = transaction.completedAt ?? transaction.sellerConfirmedAt;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: r.width * 0.92),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.verified_rounded, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Transaction complete',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Advance token ${ChatFlow.formatPrice(transaction.tokenAmount)} was paid in app. '
                  'Remaining ${ChatFlow.formatPrice(transaction.remainingAmount)} was paid offline.',
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                if (completedAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Both parties confirmed on ${DateFormat('d MMM yyyy, h:mm a').format(completedAt)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryRatingCard(Responsive r, DeliveryPartnerRating rating) {
    final isPickup = _chatTransaction?.isPickup == true;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: r.width * 0.92),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.chipBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPickup ? 'Seller rated' : 'Delivery partner rated',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  rating.deliveryPartnerName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppColors.warning,
                      size: 20,
                    );
                  }),
                ),
                if (rating.reviewText?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    rating.reviewText!,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisputeCard(Responsive r, ChatTransaction transaction) {
    final canRequestRefund = _isActingAsBuyer &&
        _chatPayment?.isPaid == true &&
        _chatPayment?.status != ChatPaymentStatus.refundRequested &&
        _chatPayment?.status != ChatPaymentStatus.refunded;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: r.width * 0.92),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warningSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.report_problem_outlined, color: AppColors.warning),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Return / issue reported',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  transaction.disputeReason?.trim().isNotEmpty == true
                      ? transaction.disputeReason!
                      : 'Waiting for resolution. Offline remaining payment disputes are between buyer and seller.',
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                if (_chatPayment?.status == ChatPaymentStatus.refundRequested) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Advance token refund requested — waiting for admin review.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
                if (canRequestRefund) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _requestAdvanceRefund,
                    icon: const Icon(Icons.currency_rupee_rounded, size: 18),
                    label: const Text('Request refund of advance token'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _inlinePaymentWidgets(Responsive r) {
    if (_showInlinePaymentPrompt) {
      return [_buildInlineCashfreePaymentCard(r)];
    }
    if (_showAdvanceTokenPaidInChat) {
      return [_buildAdvanceTokenPaidChatCard(r)];
    }
    return const [];
  }

  int? get _willingToBuyMessageIndex {
    final buyerId = _session?.buyerId;
    if (buyerId == null) return null;

    for (var i = _messages.length - 1; i >= 0; i--) {
      final msg = _messages[i];
      if (msg.senderId == buyerId && msg.text.toLowerCase().contains('willing to buy')) {
        return i;
      }
    }
    return null;
  }

  bool get _showInlinePaymentPrompt =>
      _isActingAsBuyer &&
      !_showSellerControls &&
      ChatFlow.showCashfreePaymentPanel(_flowStep, isSeller: false) &&
      _chatPayment?.isPaid != true;

  Widget _buildWhatsAppQuickReplyBubble(Responsive r) {
    final options = _displayQuickReplies;
    if (options.isEmpty) return const SizedBox.shrink();

    final alignRight = _isActingAsBuyer;

    return Align(
      alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, top: 4),
        constraints: BoxConstraints(maxWidth: r.width * 0.82),
        decoration: BoxDecoration(
          color: AppColors.chipBg,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_quickReplyPrompt != null || _quickReplyNote != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_quickReplyPrompt != null)
                      Text(
                        _quickReplyPrompt!,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.35,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    if (_quickReplyNote != null) ...[
                      if (_quickReplyPrompt != null) const SizedBox(height: 6),
                      Text(
                        _quickReplyNote!,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ...List.generate(options.length, (index) {
              final option = options[index];
              return Column(
                children: [
                  if (index > 0 || _quickReplyPrompt != null || _quickReplyNote != null)
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.divider.withValues(alpha: 0.85),
                    ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _busy ? null : () => _onQuickReplyTap(option),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        child: Row(
                          children: [
                            Icon(
                              Icons.reply_rounded,
                              size: 20,
                              color: AppColors.primary.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                option.label,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  bool get _showAdvanceTokenPaidInChat => _chatPayment?.isPaid == true;

  bool get _isSellerView =>
      _showSellerControls || (_session?.sellerId == _currentUserId);

  Widget _buildAdvanceTokenPaidChatCard(Responsive r) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: r.width * 0.92),
          child: _buildAdvanceTokenPaidContent(
            isSellerView: _isSellerView,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBubble(String text, Responsive r) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.chipBg.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildSpecialActionPanel(Responsive r) {
    if (_isBuyerBlocked) {
      final until = _session?.blockedUntil;
      final label = until != null
          ? 'You can message again after ${DateFormat('d MMM, h:mm a').format(until)}'
          : 'Messaging is temporarily unavailable';
      return _infoPanel(
        r,
        icon: Icons.schedule_rounded,
        title: 'Item not available',
        subtitle: label,
      );
    }

    if (_showSellerControls && ChatFlow.showSpecialSellerDatePicker(_flowStep)) {
      return _actionPanel(
        r,
        label: 'Select availability date',
        onPressed: _pickAvailabilityDate,
        icon: Icons.calendar_today_rounded,
      );
    }

    if (_showSellerControls && ChatFlow.showSpecialSellerPriceEditor(_flowStep)) {
      final listPrice = _session?.listPrice;
      return _actionPanel(
        r,
        label: 'Set item price',
        onPressed: _setSellerPrice,
        icon: Icons.currency_rupee_rounded,
        note: ChatFlow.sellerPriceSetNote(
          listPrice: listPrice != null && listPrice > 0 ? listPrice : null,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _infoPanel(
    Responsive r, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(r.horizontalPadding(), 12, r.horizontalPadding(), 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionPanel(
    Responsive r, {
    required String label,
    required VoidCallback onPressed,
    required IconData icon,
    bool filled = false,
    String? note,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(r.horizontalPadding(), 8, r.horizontalPadding(), 4),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (note != null) ...[
              Text(
                note,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
            ],
            filled
                ? FilledButton.icon(
                    onPressed: _busy ? null : onPressed,
                    icon: Icon(icon),
                    label: Text(label),
                  )
                : OutlinedButton.icon(
                    onPressed: _busy ? null : onPressed,
                    icon: Icon(icon),
                    label: Text(label),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineCashfreePaymentCard(Responsive r) {
    final agreedPrice = _session?.agreedPrice ?? _session?.listPrice ?? 0;
    final tokenAmount = ChatFlow.tokenAmount(agreedPrice);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: r.width * 0.92),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Send 1% advance token',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _tokenBreakdownRow('Agreed item price', ChatFlow.formatPrice(agreedPrice)),
                      const SizedBox(height: 8),
                      _tokenBreakdownRow(
                        'Advance token (1%)',
                        ChatFlow.formatPrice(tokenAmount),
                        emphasized: true,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        ChatFlow.tokenPaymentNote(agreedPrice),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _busy || agreedPrice <= 0 ? null : _startCashfreePayment,
                  icon: const Icon(Icons.payment_rounded),
                  label: Text('Send ${ChatFlow.formatPrice(tokenAmount)} via Cashfree'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdvanceTokenPaidContent({
    required bool isSellerView,
  }) {
    final payment = _chatPayment;
    final agreedPrice = payment?.agreedPrice ?? _session?.agreedPrice ?? _session?.listPrice ?? 0;
    final tokenAmount = payment?.tokenAmount ?? ChatFlow.tokenAmount(agreedPrice);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ChatFlow.advanceTokenPaidChatTitle(isSellerView: isSellerView),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _tokenBreakdownRow('Agreed item price', ChatFlow.formatPrice(agreedPrice)),
          const SizedBox(height: 6),
          _tokenBreakdownRow(
            isSellerView ? 'Advance token received (1%)' : 'Advance token sent (1%)',
            ChatFlow.formatPrice(tokenAmount),
            emphasized: true,
          ),
          if (payment?.cashfreePaymentId != null) ...[
            const SizedBox(height: 6),
            _tokenBreakdownRow('Payment ID', payment!.cashfreePaymentId!),
          ],
          const SizedBox(height: 8),
          Text(
            ChatFlow.advanceTokenPaidChatNote(
              isSellerView: isSellerView,
              tokenAmount: tokenAmount,
              agreedPrice: agreedPrice,
            ),
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDoorstepDeliveryWarning(Responsive r) {
    final remaining = _chatTransaction?.remainingAmount ??
        ChatFlow.remainingAmount(_session?.agreedPrice ?? _session?.listPrice ?? 0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(r.horizontalPadding(), 10, r.horizontalPadding(), 0),
      color: AppColors.surface,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.warningSoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.shield_outlined, size: 18, color: AppColors.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${ChatFlow.doorstepPaymentWarning} Remaining: ${ChatFlow.formatPrice(remaining)}.',
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _showDoorstepDeliveryWarning =>
      _isActingAsBuyer &&
      !_showSellerControls &&
      _isInHandoverPhase &&
      _fulfillmentMode == ChatFulfillmentMode.doorstep &&
      _chatTransaction != null &&
      !_chatTransaction!.isCompleted &&
      !_chatTransaction!.isDispute;

  bool get _showPickupPaymentWarning =>
      _isActingAsBuyer &&
      !_showSellerControls &&
      _isInHandoverPhase &&
      _fulfillmentMode == ChatFulfillmentMode.pickup &&
      _chatTransaction != null &&
      !_chatTransaction!.isCompleted &&
      !_chatTransaction!.isDispute;

  Widget _buildPickupPaymentWarning(Responsive r) {
    final remaining = _chatTransaction?.remainingAmount ??
        ChatFlow.remainingAmount(_session?.agreedPrice ?? _session?.listPrice ?? 0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(r.horizontalPadding(), 10, r.horizontalPadding(), 0),
      color: AppColors.surface,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.warningSoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.shield_outlined, size: 18, color: AppColors.warning),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${ChatFlow.pickupPaymentWarning} Remaining: ${ChatFlow.formatPrice(remaining)}.',
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tokenBreakdownRow(String label, String value, {bool emphasized = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: emphasized ? 14 : 13,
              fontWeight: emphasized ? FontWeight.w600 : FontWeight.normal,
              color: emphasized ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasized ? 16 : 13,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
            color: emphasized ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final flowOptions = _flowOptions;
    final specialPanel = _buildSpecialActionPanel(r);
    final showQuickReplies = _showQuickReplies;

    final canTypeFreely = ChatFlow.canTypeFreely(
      _flowStep,
      isSeller: _showSellerControls,
      isGuided: _isGuided,
    );
    final hasFlowOptions = flowOptions.isNotEmpty;
    final guidedInputLocked = _isGuided &&
        !_isFreeChatPhase &&
        !canTypeFreely &&
        (showQuickReplies || hasFlowOptions || _isWaitingForSeller);
    final inputEnabled = !_isBuyerBlocked &&
        !_isWaitingForSeller &&
        (_isFreeChatPhase || canTypeFreely);
    final canSend = !_busy && inputEnabled && _controller.text.trim().isNotEmpty;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_initError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: Center(child: Text(_initError!)),
      );
    }

    _scrollToBottom();

    return Scaffold(
      appBar: AppBar(
        title: _canOpenSellerProfile
            ? InkWell(
                onTap: _openSellerProfile,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _buildAppBarTitle(),
                ),
              )
            : _buildAppBarTitle(),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.all(r.horizontalPadding()),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: _buildChatListItems(r),
            ),
          ),
          specialPanel,
          if (_showDoorstepDeliveryWarning) _buildDoorstepDeliveryWarning(r),
          if (_showPickupPaymentWarning) _buildPickupPaymentWarning(r),
          if (inputEnabled)
            Container(
              padding: EdgeInsets.fromLTRB(r.horizontalPadding(), 8, r.horizontalPadding(), 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: specialPanel is SizedBox
                    ? const Border(top: BorderSide(color: AppColors.divider))
                    : null,
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        enabled: inputEnabled,
                        textInputAction: TextInputAction.send,
                        decoration: InputDecoration(
                          hintText: _isBuyerBlocked
                              ? 'Messaging paused...'
                              : guidedInputLocked
                                  ? 'Tap a reply above...'
                                  : 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: canSend ? (_) => _sendFreeText() : null,
                      ),
                    ),
                    IconButton(
                      onPressed: canSend ? _sendFreeText : null,
                      icon: Icon(
                        Icons.send,
                        color: canSend
                            ? AppColors.primary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReductionAmountDialog extends StatefulWidget {
  const _ReductionAmountDialog({required this.maxReduction});

  final int maxReduction;

  @override
  State<_ReductionAmountDialog> createState() => _ReductionAmountDialogState();
}

class _ReductionAmountDialogState extends State<_ReductionAmountDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid reduction amount')),
      );
      return;
    }
    if (value > widget.maxReduction) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reduction cannot exceed ${ChatFlow.formatPrice(widget.maxReduction.toDouble())}',
          ),
        ),
      );
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reduce by amount'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: 'Reduction amount (₹)',
          prefixText: '₹ ',
          helperText: 'Max ${ChatFlow.formatPrice(widget.maxReduction.toDouble())}',
        ),
        autofocus: true,
        onSubmitted: (_) => _confirm(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _confirm, child: const Text('Confirm')),
      ],
    );
  }
}

class _SetPriceDialog extends StatefulWidget {
  const _SetPriceDialog({
    required this.initialPrice,
    this.title = 'Set price',
    this.label = 'Price (₹)',
    this.hint,
  });

  final String initialPrice;
  final String title;
  final String label;
  final String? hint;

  @override
  State<_SetPriceDialog> createState() => _SetPriceDialogState();
}

class _SetPriceDialogState extends State<_SetPriceDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPrice);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final value = double.tryParse(_controller.text.trim());
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid price')),
      );
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.hint != null) ...[
            Text(
              widget.hint!,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: widget.label,
              prefixText: '₹ ',
            ),
            autofocus: true,
            onSubmitted: (_) => _confirm(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _confirm, child: const Text('Confirm')),
      ],
    );
  }
}

class _DeliveryAddressDialog extends StatefulWidget {
  const _DeliveryAddressDialog();

  @override
  State<_DeliveryAddressDialog> createState() => _DeliveryAddressDialogState();
}

class _DeliveryAddressDialogState extends State<_DeliveryAddressDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final address = _controller.text.trim();
    if (address.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a complete delivery address')),
      );
      return;
    }
    Navigator.pop(context, address);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delivery address'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.streetAddress,
        textCapitalization: TextCapitalization.sentences,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Full address',
          hintText: 'House no., street, area, city, pincode',
          alignLabelWithHint: true,
        ),
        autofocus: true,
        onSubmitted: (_) => _confirm(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _confirm, child: const Text('Share address')),
      ],
    );
  }
}

class _DeliveryPartnerDialog extends StatefulWidget {
  const _DeliveryPartnerDialog();

  @override
  State<_DeliveryPartnerDialog> createState() => _DeliveryPartnerDialogState();
}

class _DeliveryPartnerDialogState extends State<_DeliveryPartnerDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final name = _controller.text.trim();
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the delivery partner name')),
      );
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delivery partner'),
      content: TextField(
        controller: _controller,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Partner / agent name',
          hintText: 'e.g. FastDrop, Rajesh',
        ),
        autofocus: true,
        onSubmitted: (_) => _confirm(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _confirm, child: const Text('Dispatch')),
      ],
    );
  }
}

class _DeliveryPartnerRatingDialog extends StatefulWidget {
  const _DeliveryPartnerRatingDialog({
    required this.partnerName,
    this.title = 'Rate delivery partner',
  });

  final String partnerName;
  final String title;

  @override
  State<_DeliveryPartnerRatingDialog> createState() =>
      _DeliveryPartnerRatingDialogState();
}

class _DeliveryPartnerRatingDialogState extends State<_DeliveryPartnerRatingDialog> {
  int _rating = 5;
  late final TextEditingController _reviewController;

  @override
  void initState() {
    super.initState();
    _reviewController = TextEditingController();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _confirm() {
    Navigator.pop(
      context,
      (rating: _rating, review: _reviewController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.partnerName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final star = index + 1;
              return IconButton(
                onPressed: () => setState(() => _rating = star),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: AppColors.warning,
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reviewController,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Review (optional)',
              hintText: 'How was the delivery experience?',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _confirm, child: const Text('Submit rating')),
      ],
    );
  }
}

class _RefundReasonDialog extends StatefulWidget {
  const _RefundReasonDialog();

  @override
  State<_RefundReasonDialog> createState() => _RefundReasonDialogState();
}

class _RefundReasonDialogState extends State<_RefundReasonDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final reason = _controller.text.trim();
    if (reason.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the issue briefly')),
      );
      return;
    }
    Navigator.pop(context, reason);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request advance token refund'),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Reason',
          hintText: 'Why should the advance token be refunded?',
          alignLabelWithHint: true,
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _confirm, child: const Text('Submit request')),
      ],
    );
  }
}
