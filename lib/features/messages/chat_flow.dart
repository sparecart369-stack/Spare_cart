import 'package:spare_kart/data/models/chat_transaction.dart';
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
  awaitingSellerReplyForDelivery,
  awaitingBuyerLocationForDelivery,
  awaitingDeliveryChoice,
  awaitingSellerHandoff,
  awaitingBuyerReceipt,
  awaitingSellerConfirm,
  awaitingDeliveryPartnerRating,
  disputeOpen,
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
  static const buyerBlockDuration = Duration(days: 3);
  static const tokenPercent = 0.01;

  static String formatPrice(double price) => '₹${price.toStringAsFixed(0)}';

  static double tokenAmount(double agreedPrice) {
    if (agreedPrice <= 0) return 1;
    final amount = agreedPrice * tokenPercent;
    return amount < 1 ? 1 : amount.roundToDouble();
  }

  static int tokenAmountPaise(double agreedPrice) {
    final paise = (agreedPrice * tokenPercent * 100).round();
    return paise < 100 ? 100 : paise;
  }

  static String tokenPaymentNote(double agreedPrice) {
    final token = tokenAmount(agreedPrice);
    return 'Send advance token of ${formatPrice(token)} (1% of ${formatPrice(agreedPrice)}) via Cashfree to confirm your purchase.';
  }

  static String advanceTokenPaidMessage({
    required double tokenAmount,
    required double agreedPrice,
  }) {
    return 'Advance token of ${formatPrice(tokenAmount)} (1% of ${formatPrice(agreedPrice)}) paid successfully via Cashfree.';
  }

  static String advanceTokenPaidChatTitle({required bool isSellerView}) =>
      isSellerView ? 'Buyer paid advance token' : 'Advance token paid';

  static String advanceTokenPaidChatNote({
    required bool isSellerView,
    required double tokenAmount,
    required double agreedPrice,
  }) {
    if (isSellerView) {
      return 'Buyer sent ${formatPrice(tokenAmount)} as 1% advance token for this item (agreed price ${formatPrice(agreedPrice)}).';
    }
    return advanceTokenPaidMessage(
      tokenAmount: tokenAmount,
      agreedPrice: agreedPrice,
    );
  }

  static String advanceTokenPercentLabel() => '1% advance token';

  static String sellerPriceSetNote({double? listPrice}) {
    if (listPrice != null && listPrice > 0) {
      return 'Listed at ${formatPrice(listPrice)}. If needed, you can set a higher rate.';
    }
    return 'If needed, you can set a higher rate than the listed price.';
  }

  static const sellerNegotiationReplyNote =
      'After negotiation, you can set your fixed last price using the option below.';

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
    ChatFulfillmentMode fulfillmentMode = ChatFulfillmentMode.doorstep,
    double? agreedPrice,
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
            label: 'Set fixed last price after negotiation',
            message: '',
            nextStep: ChatFlowStep.awaitingBuyIntent,
          ),
        );
        return options;
      case ChatFlowStep.awaitingSellerHandoff:
        if (fulfillmentMode == ChatFulfillmentMode.pickup) {
          return const [
            ChatFlowOption(
              id: 'ready_pickup',
              label: 'Item is ready for pickup',
              message: sellerReadyPickupMessage,
              nextStep: ChatFlowStep.awaitingBuyerReceipt,
            ),
          ];
        }
        return const [
          ChatFlowOption(
            id: 'dispatched',
            label: 'Item dispatched for delivery',
            message: '',
            nextStep: ChatFlowStep.awaitingBuyerReceipt,
          ),
        ];
      case ChatFlowStep.awaitingSellerConfirm:
        return fulfillmentMode == ChatFulfillmentMode.pickup
            ? const [
                ChatFlowOption(
                  id: 'confirm_pickup',
                  label: 'Pickup and payment confirmed',
                  message: sellerConfirmPickupMessage,
                  nextStep: ChatFlowStep.awaitingDeliveryPartnerRating,
                ),
                ChatFlowOption(
                  id: 'seller_dispute',
                  label: 'Payment not received — raise dispute',
                  message: sellerDisputeMessage,
                  nextStep: ChatFlowStep.disputeOpen,
                ),
              ]
            : const [
                ChatFlowOption(
                  id: 'confirm_doorstep',
                  label: 'Delivery and payment confirmed',
                  message: sellerConfirmDoorstepMessage,
                  nextStep: ChatFlowStep.awaitingDeliveryPartnerRating,
                ),
                ChatFlowOption(
                  id: 'seller_dispute',
                  label: 'Payment not received — raise dispute',
                  message: sellerDisputeMessage,
                  nextStep: ChatFlowStep.disputeOpen,
                ),
              ];
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
    ChatFulfillmentMode fulfillmentMode = ChatFulfillmentMode.doorstep,
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
        return _buyerNegotiationOptions(price);
      case ChatFlowStep.awaitingBuyIntent:
        final price = agreedPrice ?? listPrice ?? 0;
        return [
          const ChatFlowOption(
            id: 'willing_to_buy',
            label: 'Okay, I am willing to buy',
            message: 'Okay, I am willing to buy this item.',
            nextStep: ChatFlowStep.awaitingTokenPayment,
          ),
          ..._buyerNegotiationOptions(price),
        ];
      case ChatFlowStep.awaitingTokenPayment:
        return const [];
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
              nextStep: ChatFlowStep.awaitingBuyerLocationForDelivery,
            ),
            ChatFlowOption(
              id: 'both',
              label: 'Both options work',
              message: 'Both pickup and doorstep delivery work for me.',
              nextStep: ChatFlowStep.awaitingBuyerLocationForDelivery,
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
            id: 'share_current_location',
            label: 'Use my current location',
            message: '',
            nextStep: ChatFlowStep.awaitingSellerHandoff,
          ),
          ChatFlowOption(
            id: 'enter_delivery_address',
            label: 'Enter address manually',
            message: '',
            nextStep: ChatFlowStep.awaitingSellerHandoff,
          ),
        ];
      case ChatFlowStep.awaitingBuyerReceipt:
        final price = agreedPrice ?? listPrice ?? 0;
        final remaining = remainingAmount(price);
        if (fulfillmentMode == ChatFulfillmentMode.pickup) {
          return [
            ChatFlowOption(
              id: 'confirm_pickup_paid',
              label: 'I picked up and paid ${formatPrice(remaining)}',
              message: buyerReceivedPaidPickupMessage(remaining),
              nextStep: ChatFlowStep.awaitingSellerConfirm,
            ),
            const ChatFlowOption(
              id: 'report_issue',
              label: 'Item has a problem — request return',
              message: buyerReportIssueMessage,
              nextStep: ChatFlowStep.disputeOpen,
            ),
          ];
        }
        return [
          ChatFlowOption(
            id: 'confirm_doorstep_paid',
            label: 'I received and paid ${formatPrice(remaining)} to delivery',
            message: buyerReceivedPaidDoorstepMessage(remaining),
            nextStep: ChatFlowStep.awaitingSellerConfirm,
          ),
          const ChatFlowOption(
            id: 'report_issue',
            label: 'Item has a problem — request return',
            message: buyerReportIssueMessage,
            nextStep: ChatFlowStep.disputeOpen,
          ),
        ];
      case ChatFlowStep.awaitingDeliveryPartnerRating:
        final rateLabel = fulfillmentMode == ChatFulfillmentMode.pickup
            ? 'Rate seller'
            : 'Rate delivery partner';
        return [
          ChatFlowOption(
            id: 'rate_delivery_partner',
            label: rateLabel,
            message: '',
            nextStep: ChatFlowStep.completed,
          ),
          const ChatFlowOption(
            id: 'skip_delivery_rating',
            label: 'Skip for now',
            message: '',
            nextStep: ChatFlowStep.completed,
          ),
        ];
      default:
        return [];
    }
  }

  static List<ChatFlowOption> _buyerNegotiationOptions(double price) {
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

  static bool isHandoverFlowStep(ChatFlowStep step) => switch (step) {
        ChatFlowStep.awaitingSellerHandoff ||
        ChatFlowStep.awaitingBuyerReceipt ||
        ChatFlowStep.awaitingSellerConfirm ||
        ChatFlowStep.awaitingDeliveryPartnerRating ||
        ChatFlowStep.disputeOpen =>
          true,
        _ => false,
      };

  /// Handover steps where both parties can still chat freely before the
  /// seller confirms delivery/payment.
  static bool isPreConfirmationHandoverStep(ChatFlowStep step) => switch (step) {
        ChatFlowStep.awaitingSellerHandoff ||
        ChatFlowStep.awaitingBuyerReceipt ||
        ChatFlowStep.awaitingSellerConfirm ||
        ChatFlowStep.disputeOpen =>
          true,
        _ => false,
      };

  static bool canTypeFreely(ChatFlowStep step, {required bool isSeller, required bool isGuided}) {
    if (!isGuided) return true;
    if (step == ChatFlowStep.freeChat || isPreConfirmationHandoverStep(step)) {
      return true;
    }
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

    bool buyerMessageContains(String pattern) => messages.any(
          (msg) =>
              msg.senderId == buyerId &&
              msg.text.toLowerCase().contains(pattern),
        );

    final wantsDoorstep = buyerMessageContains("i'd like doorstep delivery") ||
        buyerMessageContains('both pickup and doorstep');
    final wantsPickupOnly = buyerMessageContains("i'd like to pick up the item");

    final hasDeliveryLocation = messages.any(
      (msg) =>
          msg.senderId == buyerId && msg.text.startsWith('Delivery location:'),
    );
    final hasPickupLocation = messages.any(
      (msg) =>
          msg.senderId == sellerId && msg.text.startsWith('Pickup location:'),
    );

    if (wantsDoorstep) return hasDeliveryLocation;
    if (wantsPickupOnly) return hasPickupLocation;

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

  static const doorstepPaymentWarning =
      'Pay the remaining amount to the delivery person in cash or UPI only after you receive and check the item. SpareKart does not handle this payment — the seller arranges delivery at their risk.';

  static const pickupPaymentWarning =
      'Meet the seller at the pickup location. Pay the remaining amount directly to the seller after you inspect the item.';

  static double remainingAmount(double agreedPrice) {
    final token = tokenAmount(agreedPrice);
    return (agreedPrice - token).clamp(0, agreedPrice);
  }

  static String sellerDispatchedMessage({String? deliveryPartnerName}) {
    if (deliveryPartnerName != null && deliveryPartnerName.trim().isNotEmpty) {
      return 'Item dispatched for delivery via ${deliveryPartnerName.trim()}.';
    }
    return 'Item dispatched for delivery.';
  }

  static const sellerReadyPickupMessage = 'Item is ready for pickup.';

  static String buyerReceivedPaidDoorstepMessage(double remainingAmount) =>
      'I received the item and paid ${formatPrice(remainingAmount)} to the delivery person.';

  static String buyerReceivedPaidPickupMessage(double remainingAmount) =>
      'I picked up the item and paid ${formatPrice(remainingAmount)} to the seller.';

  static const buyerReportIssueMessage =
      'Item has a problem — I would like to request a return.';

  static const sellerConfirmDoorstepMessage = 'Delivery and payment confirmed.';

  static const sellerConfirmPickupMessage = 'Pickup and payment confirmed.';

  static const sellerDisputeMessage = 'Payment not received — I am raising a dispute.';

  static bool isHandoverMessage(String text) {
    final lower = text.toLowerCase();
    return lower.contains('item dispatched for delivery') ||
        lower.contains('item is ready for pickup') ||
        lower.contains('received the item and paid') ||
        lower.contains('picked up the item and paid') ||
        lower.contains('item has a problem') ||
        lower.contains('delivery and payment confirmed') ||
        lower.contains('pickup and payment confirmed') ||
        lower.contains('payment not received');
  }

  static bool hasSellerHandoverConfirmation({
    required List<ChatMessage> messages,
    required String? sellerId,
  }) {
    if (sellerId == null) return false;
    return messages.any((msg) {
      if (msg.senderId != sellerId) return false;
      final lower = msg.text.toLowerCase();
      return lower.contains('delivery and payment confirmed') ||
          lower.contains('pickup and payment confirmed');
    });
  }

  /// Derives the current handover step from chat messages so both parties
  /// stay in sync via realtime without restarting the app.
  static ChatFlowStep? inferHandoverStepFromMessages({
    required List<ChatMessage> messages,
    required String? buyerId,
    required String? sellerId,
  }) {
    if (buyerId == null || sellerId == null) return null;

    if (hasSellerHandoverConfirmation(messages: messages, sellerId: sellerId)) {
      return ChatFlowStep.awaitingDeliveryPartnerRating;
    }

    if (!isDeliveryFlowComplete(
      messages: messages,
      buyerId: buyerId,
      sellerId: sellerId,
    )) {
      return null;
    }

    var step = ChatFlowStep.awaitingSellerHandoff;

    for (final msg in messages) {
      final lower = msg.text.toLowerCase();
      if (msg.senderId == sellerId) {
        if (lower.contains('item dispatched for delivery') ||
            lower.contains('item is ready for pickup')) {
          step = ChatFlowStep.awaitingBuyerReceipt;
        } else if (lower.contains('delivery and payment confirmed') ||
            lower.contains('pickup and payment confirmed')) {
          step = ChatFlowStep.awaitingDeliveryPartnerRating;
        } else if (lower.contains('payment not received')) {
          step = ChatFlowStep.disputeOpen;
        }
      } else if (msg.senderId == buyerId) {
        if (lower.contains('received the item and paid') ||
            lower.contains('picked up the item and paid')) {
          step = ChatFlowStep.awaitingSellerConfirm;
        } else if (lower.contains('item has a problem')) {
          step = ChatFlowStep.disputeOpen;
        }
      }
    }

    return step;
  }

  static ChatFulfillmentMode resolveFulfillmentMode({
    required List<ChatMessage> messages,
    required String? buyerId,
    String? sellerDeliveryOffer,
  }) {
    if (buyerId != null) {
      final buyerChosePickup = messages.any((msg) {
        if (msg.senderId != buyerId) return false;
        final lower = msg.text.toLowerCase();
        return lower.contains("i'd like to pick up the item");
      });
      if (buyerChosePickup) return ChatFulfillmentMode.pickup;

      final buyerChoseDoorstep = messages.any((msg) {
        if (msg.senderId != buyerId) return false;
        final lower = msg.text.toLowerCase();
        return lower.contains("i'd like doorstep delivery") ||
            lower.contains('both pickup and doorstep');
      });
      if (buyerChoseDoorstep) return ChatFulfillmentMode.doorstep;
    }

    if (sellerDeliveryOffer == 'pickup_only' || sellerDeliveryOffer == 'pickup_yes') {
      return ChatFulfillmentMode.pickup;
    }

    if (messages.any((msg) => msg.text.startsWith('Delivery location:'))) {
      return ChatFulfillmentMode.doorstep;
    }

    if (messages.any((msg) => msg.text.startsWith('Pickup location:'))) {
      return ChatFulfillmentMode.pickup;
    }

    return ChatFulfillmentMode.doorstep;
  }

  static bool isDoorstepDeliveryActive({
    required List<ChatMessage> messages,
    required String? buyerId,
    required String? sellerId,
    String? sellerDeliveryOffer,
  }) {
    if (buyerId == null) return false;

    final buyerChoseDoorstep = messages.any((msg) {
      if (msg.senderId != buyerId) return false;
      final lower = msg.text.toLowerCase();
      return lower.contains("i'd like doorstep delivery") ||
          lower.contains('both pickup and doorstep');
    });
    if (buyerChoseDoorstep) return true;

    if (sellerDeliveryOffer == 'doorstep_only' || sellerDeliveryOffer == 'doorstep_yes') {
      return true;
    }

    if (sellerId == null) return false;

    return messages.any((msg) {
      if (msg.senderId != sellerId) return false;
      final lower = msg.text.toLowerCase();
      return lower.contains('only doorstep delivery is available') ||
          lower.contains('doorstep delivery is available for this item') ||
          lower.contains('yes, doorstep delivery is available');
    });
  }

  static bool showSpecialSellerDatePicker(ChatFlowStep step) =>
      step == ChatFlowStep.awaitingAvailabilityDate;

  static bool showSpecialSellerPriceEditor(ChatFlowStep step) =>
      step == ChatFlowStep.awaitingPriceSet;

  static bool showCashfreePaymentPanel(ChatFlowStep step, {required bool isSeller}) =>
      !isSeller && step == ChatFlowStep.awaitingTokenPayment;
}
