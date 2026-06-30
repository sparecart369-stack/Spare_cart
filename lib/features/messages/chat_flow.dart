import 'package:spare_kart/data/models/models.dart';

enum ChatFlowStep {
  started,
  awaitingAvailability,
  buyerBlockedAfterNo,
  awaitingWhenAvailableAsk,
  awaitingAvailabilityDate,
  awaitingPriceAsk,
  awaitingPriceSet,
  awaitingNegotiation,
  awaitingNegotiationReply,
  awaitingBuyIntent,
  awaitingTokenPayment,
  awaitingTokenScreenshot,
  awaitingSellerReplyForDelivery,
  awaitingBuyerLocationForDelivery,
  awaitingDeliveryChoice,
  freeChat,
  completed,
}

class ChatFlowOption {
  const ChatFlowOption({
    required this.id,
    required this.label,
    required this.message,
    required this.nextStep,
    this.reductionAmount,
  });

  final String id;
  final String label;
  final String message;
  final ChatFlowStep nextStep;
  final int? reductionAmount;
}

abstract final class ChatFlow {
  static const initialBuyerMessage = 'Is the item still available?';
  static const nowAvailableMessage = 'The item is now available!';
  static const googlePayNumber = '9645299758';
  static const buyerBlockDuration = Duration(days: 3);

  static String formatPrice(double price) => '₹${price.toStringAsFixed(0)}';

  static int? parseReductionAsk(String text) {
    final match = RegExp(
      r'reduce the amount by ₹(\d+)',
      caseSensitive: false,
    ).firstMatch(text);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  static List<ChatFlowOption> sellerOptions(
    ChatFlowStep step, {
    double? listPrice,
    int? lastReductionAsk,
    String? buyerDeliveryAsk,
  }) {
    switch (step) {
      case ChatFlowStep.awaitingAvailability:
        return const [
          ChatFlowOption(
            id: 'yes',
            label: 'Yes',
            message: 'Yes, the item is still available!',
            nextStep: ChatFlowStep.awaitingPriceAsk,
          ),
          ChatFlowOption(
            id: 'no',
            label: 'No',
            message: 'Sorry, this item is no longer available.',
            nextStep: ChatFlowStep.buyerBlockedAfterNo,
          ),
          ChatFlowOption(
            id: 'will_be_available',
            label: 'Will be available',
            message: 'The item will be available soon.',
            nextStep: ChatFlowStep.awaitingWhenAvailableAsk,
          ),
        ];
      case ChatFlowStep.buyerBlockedAfterNo:
        return const [
          ChatFlowOption(
            id: 'now_available',
            label: 'Now available',
            message: nowAvailableMessage,
            nextStep: ChatFlowStep.awaitingPriceAsk,
          ),
        ];
      case ChatFlowStep.awaitingAvailabilityDate:
        return const [];
      case ChatFlowStep.awaitingPriceSet:
        return const [];
      case ChatFlowStep.awaitingNegotiationReply:
        final options = <ChatFlowOption>[
          const ChatFlowOption(
            id: 'fixed_price',
            label: 'This price is fixed',
            message: 'This price is fixed and cannot be reduced.',
            nextStep: ChatFlowStep.awaitingBuyIntent,
          ),
        ];
        if (lastReductionAsk != null && lastReductionAsk > 0) {
          options.add(
            ChatFlowOption(
              id: 'accept_reduction',
              label: 'Yes, I can reduce by ₹$lastReductionAsk',
              message: 'Yes, I can reduce the price by ${formatPrice(lastReductionAsk.toDouble())}.',
              nextStep: ChatFlowStep.awaitingBuyIntent,
              reductionAmount: lastReductionAsk,
            ),
          );
        }
        options.add(
          const ChatFlowOption(
            id: 'last_price',
            label: 'Yes, this is the last price (tap to enter the updated last price)',
            message: '',
            nextStep: ChatFlowStep.awaitingBuyIntent,
          ),
        );
        return options;
      case ChatFlowStep.awaitingSellerReplyForDelivery:
        switch (buyerDeliveryAsk) {
          case 'ask_doorstep':
            return const [
              ChatFlowOption(
                id: 'doorstep_yes',
                label: 'Yes, doorstep delivery is available',
                message: 'Yes, doorstep delivery is available.',
                nextStep: ChatFlowStep.awaitingBuyerLocationForDelivery,
              ),
              ChatFlowOption(
                id: 'pickup_only',
                label: 'Sorry, pickup only',
                message: 'Sorry, only pickup is available. Please collect from the pickup location.',
                nextStep: ChatFlowStep.freeChat,
              ),
            ];
          case 'ask_pickup':
            return const [
              ChatFlowOption(
                id: 'pickup_yes',
                label: 'Yes, pickup is available',
                message: 'Yes, you can pick up the item.',
                nextStep: ChatFlowStep.freeChat,
              ),
              ChatFlowOption(
                id: 'doorstep_only',
                label: 'Sorry, doorstep delivery only',
                message: 'Sorry, only doorstep delivery is available.',
                nextStep: ChatFlowStep.awaitingBuyerLocationForDelivery,
              ),
            ];
          case 'ask_both':
          default:
            return const [
              ChatFlowOption(
                id: 'doorstep_only',
                label: 'Doorstep delivery is available',
                message: 'Doorstep delivery is available for this item.',
                nextStep: ChatFlowStep.awaitingBuyerLocationForDelivery,
              ),
              ChatFlowOption(
                id: 'pickup_only',
                label: 'Pickup only',
                message: 'Pickup only — please collect the item from the pickup location.',
                nextStep: ChatFlowStep.freeChat,
              ),
              ChatFlowOption(
                id: 'both_available',
                label: 'Both pickup and doorstep delivery',
                message: 'Both pickup and doorstep delivery are available.',
                nextStep: ChatFlowStep.awaitingDeliveryChoice,
              ),
            ];
        }
      default:
        return [];
    }
  }

  static List<ChatFlowOption> buyerOptions(
    ChatFlowStep step, {
    double? agreedPrice,
    double? listPrice,
    String? sellerDeliveryOffer,
    String? buyerDeliveryAsk,
  }) {
    switch (step) {
      case ChatFlowStep.awaitingWhenAvailableAsk:
        return const [
          ChatFlowOption(
            id: 'when_available',
            label: 'When will it be available?',
            message: 'When will the item be available?',
            nextStep: ChatFlowStep.awaitingAvailabilityDate,
          ),
        ];
      case ChatFlowStep.awaitingPriceAsk:
        return const [
          ChatFlowOption(
            id: 'ask_price',
            label: 'What is the price?',
            message: 'What is the price for this item?',
            nextStep: ChatFlowStep.awaitingPriceSet,
          ),
        ];
      case ChatFlowStep.awaitingNegotiation:
        final price = agreedPrice ?? listPrice ?? 0;
        final reductions = _negotiationReductions(price);
        return [
          const ChatFlowOption(
            id: 'last_price_ask',
            label: 'Is this the last price?',
            message: 'Is this the last price?',
            nextStep: ChatFlowStep.awaitingNegotiationReply,
          ),
          ...reductions.map(
            (amount) => ChatFlowOption(
              id: 'reduce_$amount',
              label: 'Reduce by ₹$amount',
              message: 'Can you reduce the amount by ₹$amount?',
              nextStep: ChatFlowStep.awaitingNegotiationReply,
              reductionAmount: amount,
            ),
          ),
          const ChatFlowOption(
            id: 'custom_reduction',
            label: 'Reduce by custom amount (tap to enter)',
            message: '',
            nextStep: ChatFlowStep.awaitingNegotiationReply,
          ),
        ];
      case ChatFlowStep.awaitingBuyIntent:
        return const [
          ChatFlowOption(
            id: 'willing_to_buy',
            label: 'Okay, I am willing to buy',
            message: 'Okay, I am willing to buy this item.',
            nextStep: ChatFlowStep.awaitingTokenPayment,
          ),
        ];
      case ChatFlowStep.awaitingTokenPayment:
        return const [
          ChatFlowOption(
            id: 'token_sent',
            label: 'I have sent the token amount',
            message: 'I have sent the token amount via Google Pay.',
            nextStep: ChatFlowStep.awaitingTokenScreenshot,
          ),
        ];
      case ChatFlowStep.awaitingDeliveryChoice:
        if (sellerDeliveryOffer == 'both_available') {
          return const [
            ChatFlowOption(
              id: 'pickup',
              label: 'Pickup',
              message: "I'd like to pick up the item.",
              nextStep: ChatFlowStep.freeChat,
            ),
            ChatFlowOption(
              id: 'doorstep',
              label: 'Doorstep delivery',
              message: "I'd like doorstep delivery.",
              nextStep: ChatFlowStep.freeChat,
            ),
            ChatFlowOption(
              id: 'both',
              label: 'Both options work',
              message: 'Both pickup and doorstep delivery work for me.',
              nextStep: ChatFlowStep.freeChat,
            ),
          ];
        }
        return const [
          ChatFlowOption(
            id: 'ask_doorstep',
            label: 'Is doorstep delivery available?',
            message: 'Is doorstep delivery available?',
            nextStep: ChatFlowStep.awaitingSellerReplyForDelivery,
          ),
          ChatFlowOption(
            id: 'ask_pickup',
            label: 'Can I pick up the item?',
            message: 'Can I pick up the item?',
            nextStep: ChatFlowStep.awaitingSellerReplyForDelivery,
          ),
          ChatFlowOption(
            id: 'ask_both',
            label: 'Are pickup and doorstep delivery available?',
            message: 'Are pickup and doorstep delivery available?',
            nextStep: ChatFlowStep.awaitingSellerReplyForDelivery,
          ),
        ];
      case ChatFlowStep.awaitingBuyerLocationForDelivery:
        return const [
          ChatFlowOption(
            id: 'share_location',
            label: 'Share my delivery location',
            message: "I'd like doorstep delivery.",
            nextStep: ChatFlowStep.freeChat,
          ),
        ];
      default:
        return [];
    }
  }

  static List<int> _negotiationReductions(double price) {
    if (price <= 0) return [50, 100, 200];
    final candidates = <int>[
      (price * 0.05).round(),
      (price * 0.1).round(),
      (price * 0.15).round(),
      50,
      100,
      200,
      500,
    ];
    final unique = <int>{};
    for (final value in candidates) {
      if (value >= 50 && value < price) unique.add(value);
    }
    return unique.take(3).toList()..sort();
  }

  static bool isBuyerBlocked(ChatFlowStep step, DateTime? blockedUntil) {
    if (step != ChatFlowStep.buyerBlockedAfterNo) return false;
    if (blockedUntil == null) return true;
    return DateTime.now().isBefore(blockedUntil);
  }

  static ChatFlowStep resolveBuyerBlock(DateTime? blockedUntil) {
    if (blockedUntil == null || DateTime.now().isBefore(blockedUntil)) {
      return ChatFlowStep.buyerBlockedAfterNo;
    }
    return ChatFlowStep.started;
  }

  static bool canTypeFreely(ChatFlowStep step, {required bool isSeller, required bool isGuided}) {
    if (!isGuided) return true;
    if (step == ChatFlowStep.freeChat || step == ChatFlowStep.completed) return true;
    return false;
  }

  static String? parseSellerDeliveryOffer(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('both pickup and doorstep')) return 'both_available';
    if (lower.contains('pickup only')) return 'pickup_only';
    if (lower.contains('doorstep delivery is available') || lower.contains('only doorstep delivery')) {
      return 'doorstep_only';
    }
    if (lower.contains('you can pick up')) return 'pickup_yes';
    return null;
  }

  static String? parseBuyerDeliveryAsk(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('are pickup and doorstep')) return 'ask_both';
    if (lower.contains('can i pick up')) return 'ask_pickup';
    if (lower.contains('is doorstep delivery available')) return 'ask_doorstep';
    return null;
  }

  static bool isDeliveryFlowComplete({
    required List<ChatMessage> messages,
    required String? buyerId,
    required String? sellerId,
  }) {
    if (buyerId == null || sellerId == null) return false;
    for (final msg in messages) {
      if (msg.senderId == sellerId && msg.text.startsWith('Pickup location:')) {
        return true;
      }
      if (msg.senderId == buyerId && msg.text.startsWith('Delivery location:')) {
        return true;
      }
    }
    return false;
  }

  static bool showSpecialSellerDatePicker(ChatFlowStep step) =>
      step == ChatFlowStep.awaitingAvailabilityDate;

  static bool showSpecialSellerPriceEditor(ChatFlowStep step) =>
      step == ChatFlowStep.awaitingPriceSet;

  static bool showTokenPaymentInfo(ChatFlowStep step, {required bool isSeller}) =>
      !isSeller && step == ChatFlowStep.awaitingTokenPayment;

  static bool requiresScreenshotUpload(ChatFlowStep step, {required bool isSeller}) =>
      !isSeller && step == ChatFlowStep.awaitingTokenScreenshot;
}
