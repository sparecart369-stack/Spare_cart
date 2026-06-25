enum ChatFlowStep {
  started,
  awaitingAvailability,
  awaitingDeliveryChoice,
  awaitingDeliveryReply,
  completed,
}

enum ChatQuickReply {
  yes(
    label: 'Yes',
    message: 'Yes, the item is still available!',
    nextStep: ChatFlowStep.awaitingDeliveryChoice,
  ),
  no(
    label: 'No',
    message: 'Sorry, this item is no longer available.',
    nextStep: ChatFlowStep.completed,
  ),
  doorstep(
    label: 'Doorstep delivery',
    message: "I'd like doorstep delivery, please.",
    nextStep: ChatFlowStep.awaitingDeliveryReply,
  ),
  pickup(
    label: 'Pickup',
    message: "I'll pick it up myself.",
    nextStep: ChatFlowStep.awaitingDeliveryReply,
  ),
  doorstepReply(
    label: 'Confirm doorstep delivery',
    message: 'Great! We offer doorstep delivery within 2-3 business days.',
    nextStep: ChatFlowStep.completed,
  ),
  pickupReply(
    label: 'Confirm pickup',
    message: "Sure! You can pick it up at our location. We're open Mon-Sat, 9 AM - 6 PM.",
    nextStep: ChatFlowStep.completed,
  );

  const ChatQuickReply({
    required this.label,
    required this.message,
    required this.nextStep,
  });

  final String label;
  final String message;
  final ChatFlowStep nextStep;
}

abstract final class ChatFlow {
  static const initialBuyerMessage = 'Is the item still available?';

  static List<ChatQuickReply> sellerReplies(ChatFlowStep step, {String? lastBuyerMessage}) {
    switch (step) {
      case ChatFlowStep.awaitingAvailability:
        return [ChatQuickReply.yes, ChatQuickReply.no];
      case ChatFlowStep.awaitingDeliveryReply:
        if (lastBuyerMessage == ChatQuickReply.pickup.message) {
          return [ChatQuickReply.pickupReply];
        }
        return [ChatQuickReply.doorstepReply];
      default:
        return [];
    }
  }

  static List<ChatQuickReply> buyerReplies(ChatFlowStep step) {
    switch (step) {
      case ChatFlowStep.awaitingDeliveryChoice:
        return [ChatQuickReply.doorstep, ChatQuickReply.pickup];
      default:
        return [];
    }
  }
}
