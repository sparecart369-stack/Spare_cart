import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:spare_kart/bloc/app_mode/app_mode_bloc.dart';
import 'package:spare_kart/bloc/auth/auth_bloc.dart';
import 'package:spare_kart/bloc/messages/messages_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:spare_kart/core/services/location_service.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/utils/date_time_utils.dart';
import 'package:spare_kart/core/utils/responsive.dart';
import 'package:spare_kart/core/validation/form_validators.dart';
import 'package:spare_kart/core/widgets/listing_image.dart';
import 'package:spare_kart/data/models/models.dart';
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

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  final _locationService = const LocationService();

  late List<ChatMessage> _messages;
  ChatSession? _session;
  ChatFlowStep _flowStep = ChatFlowStep.completed;
  bool _isGuided = false;
  bool _busy = false;
  bool _loading = true;
  String? _initError;

  @override
  void initState() {
    super.initState();
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
    ChatSessionStore.instance.removeListener(_onSessionUpdated);
    _controller.removeListener(_onComposerChanged);
    FocusManager.instance.primaryFocus?.unfocus();
    _controller.dispose();
    _scrollController.dispose();
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
    final previousCount = _messages.length;
    _safeSetState(() {
      _session = fresh;
      _messages = List.from(fresh.messages);
      _isGuided = fresh.isGuided;
    });
    if (!mounted) return;
    _applyFlowNormalization(persist: true);
    if (fresh.messages.length > previousCount) {
      _scrollToBottom();
    }
    _prefillInitialMessage();
    _markAsRead();
  }

  @override
  void activate() {
    super.activate();
    _reloadFromStore();
    _markAsRead();
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
        _applyFlowNormalization(persist: true);
        await _markAsRead();
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
    });
    if (!mounted) return;
    _applyFlowNormalization(persist: true);
    _prefillInitialMessage();
    _scrollToBottom();
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
    final localStep = _flowStep;
    _session!.normalizeFlowStep();

    var nextStep = _session!.flowStep;
    if (localStep == ChatFlowStep.freeChat &&
        nextStep != ChatFlowStep.freeChat &&
        nextStep != ChatFlowStep.completed) {
      nextStep = ChatFlowStep.freeChat;
      _session!.flowStep = ChatFlowStep.freeChat;
    } else if (ChatFlow.isDeliveryFlowComplete(
      messages: _session!.messages,
      buyerId: _session!.buyerId,
      sellerId: _session!.sellerId,
    )) {
      nextStep = ChatFlowStep.freeChat;
      _session!.flowStep = ChatFlowStep.freeChat;
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

  bool get _isFreeChatPhase {
    if (_flowStep == ChatFlowStep.freeChat || _flowStep == ChatFlowStep.completed) {
      return true;
    }
    final session = _session;
    if (session == null) return false;
    return ChatFlow.isDeliveryFlowComplete(
      messages: _messages,
      buyerId: session.buyerId,
      sellerId: session.sellerId,
    );
  }

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
      );
    }
    if (_isActingAsBuyer) {
      return ChatFlow.buyerOptions(
        _flowStep,
        agreedPrice: _session?.agreedPrice,
        listPrice: _session?.listPrice,
        sellerDeliveryOffer: _session?.sellerDeliveryOffer,
        buyerDeliveryAsk: _session?.buyerDeliveryAsk,
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
      return 'Ready to purchase?';
    }
    if (_isActingAsBuyer && _flowStep == ChatFlowStep.awaitingTokenPayment) {
      return 'Confirm payment:';
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
      return 'Share your delivery details:';
    }
    return null;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
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
  }

  Future<void> _sendMessage(
    String text, {
    required bool isBuyer,
    String? imagePath,
  }) async {
    if (_session == null || _busy) return;
    final senderId = _currentUserId;
    if (senderId == null) return;

    setState(() => _busy = true);
    try {
      await ChatSessionStore.instance.sendMessage(
        session: _session!,
        senderId: senderId,
        text: text,
        localImagePath: imagePath,
      );
      if (!mounted) return;
      setState(() {
        _messages = List.from(_session!.messages);
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
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
    final initial = (_session?.agreedPrice ?? _session?.listPrice ?? 0).toStringAsFixed(0);

    final price = await showDialog<double>(
      context: context,
      builder: (ctx) => _SetPriceDialog(initialPrice: initial),
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
    final initial = (_session?.agreedPrice ?? _session?.listPrice ?? 0).toStringAsFixed(0);

    final price = await showDialog<double>(
      context: context,
      builder: (ctx) => _SetPriceDialog(
        initialPrice: initial,
        title: 'Updated last price',
        label: 'Last price (₹)',
      ),
    );

    if (price == null || !mounted) return;

    await _sendMessage(
      'Yes, this is the last price I can offer: ${ChatFlow.formatPrice(price)}.',
      isBuyer: false,
    );
    await _advanceFlow(ChatFlowStep.awaitingBuyIntent, agreedPrice: price);
  }

  Future<void> _uploadTokenScreenshot() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _session?.tokenScreenshotPath = picked.path;
    });

    await _sendMessage(
      'Payment screenshot attached.',
      isBuyer: true,
      imagePath: picked.path,
    );
    await _advanceFlow(ChatFlowStep.awaitingDeliveryChoice);
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
      await _advanceFlow(ChatFlowStep.freeChat);
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
    await _sendMessage("I'd like doorstep delivery.", isBuyer: true);
    await _shareCustomerLocation();
    await _advanceFlow(ChatFlowStep.freeChat);
  }

  Future<void> _handleDeliveryPreference(ChatFlowOption option) async {
    await _sendMessage(option.message, isBuyer: true);
    setState(() => _session?.deliveryChoiceMade = true);

    if (option.id == 'pickup' || option.id == 'both') {
      final location = _session?.pickupLocation ?? 'Pickup location not set';
      await _sendMessage('Pickup location: $location', isBuyer: false);
    }

    if (option.id == 'doorstep' || option.id == 'both') {
      await _shareCustomerLocation();
    }

    await _advanceFlow(ChatFlowStep.freeChat);
  }

  Future<void> _shareCustomerLocation() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final location = await _locationService.getCurrentLocation();
      if (!mounted) return;
      await _sendMessage(
        'Delivery location: ${location.address}',
        isBuyer: true,
      );
    } on LocationServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _copyGooglePayNumber() {
    Clipboard.setData(const ClipboardData(text: ChatFlow.googlePayNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google Pay number copied')),
    );
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

    if (option.id == 'share_location') {
      await _handleBuyerLocationShare();
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

    await _onFlowOption(option);
  }

  List<Widget> _buildChatListItems(Responsive r) {
    final items = <Widget>[];
    DateTime? previousDay;

    for (final msg in _messages) {
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
    }

    if (_isWaitingForSeller) {
      items.add(_buildStatusBubble('Message sent. Waiting for seller to respond…', r));
    }
    if (_showQuickReplies) {
      items.add(_buildWhatsAppQuickReplyBubble(r));
    }

    return items;
  }

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
            if (_quickReplyPrompt != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                child: Text(
                  _quickReplyPrompt!,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ...List.generate(options.length, (index) {
              final option = options[index];
              return Column(
                children: [
                  if (index > 0 || _quickReplyPrompt != null)
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
      return _actionPanel(
        r,
        label: 'Set item price',
        onPressed: _setSellerPrice,
        icon: Icons.currency_rupee_rounded,
      );
    }

    if (ChatFlow.showTokenPaymentInfo(_flowStep, isSeller: _showSellerControls)) {
      return _tokenPaymentPanel(r);
    }

    if (ChatFlow.requiresScreenshotUpload(_flowStep, isSeller: _showSellerControls)) {
      return _actionPanel(
        r,
        label: 'Upload payment screenshot (required)',
        onPressed: _uploadTokenScreenshot,
        icon: Icons.upload_file_rounded,
        filled: true,
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
        child: filled
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
      ),
    );
  }

  Widget _tokenPaymentPanel(Responsive r) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(r.horizontalPadding(), 12, r.horizontalPadding(), 8),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Send token amount via Google Pay',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ChatFlow.googlePayNumber,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _copyGooglePayNumber,
                    icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
                    tooltip: 'Copy number',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'After paying, tap "I have sent the token amount" below.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
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
        (showQuickReplies || hasFlowOptions || _isWaitingForSeller);
    final inputEnabled = !_isBuyerBlocked &&
        !_isWaitingForSeller &&
        (_isFreeChatPhase || canTypeFreely) &&
        !showQuickReplies;
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

    return Scaffold(
      appBar: AppBar(
        title: Column(
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
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.all(r.horizontalPadding()),
              children: _buildChatListItems(r),
            ),
          ),
          specialPanel,
          if (inputEnabled &&
              !ChatFlow.requiresScreenshotUpload(_flowStep, isSeller: _showSellerControls))
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
  });

  final String initialPrice;
  final String title;
  final String label;

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
      content: TextField(
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
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _confirm, child: const Text('Confirm')),
      ],
    );
  }
}
