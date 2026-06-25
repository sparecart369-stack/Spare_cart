import 'package:spare_kart/data/models/models.dart';
import 'package:spare_kart/features/messages/chat_flow.dart';

class ChatSession {
  ChatSession({
    required this.id,
    required this.partTitle,
    required this.sellerName,
    required this.buyerName,
    List<ChatMessage>? messages,
    this.flowStep = ChatFlowStep.completed,
    this.isGuided = false,
  }) : messages = messages ?? [];

  final String id;
  final String partTitle;
  final String sellerName;
  final String buyerName;
  final List<ChatMessage> messages;
  ChatFlowStep flowStep;
  final bool isGuided;

  String? get lastBuyerMessage {
    for (var i = messages.length - 1; i >= 0; i--) {
      if (messages[i].isMe) return messages[i].text;
    }
    return null;
  }

  MessageThread toThread({required bool isSeller}) => MessageThread(
        id: id,
        participantName: isSeller ? buyerName : sellerName,
        lastMessage: messages.isNotEmpty ? messages.last.text : '',
        timestamp: messages.isNotEmpty ? messages.last.timestamp : DateTime.now(),
        unreadCount: 0,
        partTitle: partTitle,
      );
}

class ChatSessionStore {
  ChatSessionStore._();

  static final ChatSessionStore instance = ChatSessionStore._();

  final Map<String, ChatSession> _sessions = {};

  ChatSession? get(String id) => _sessions[id];

  ChatSession startGuidedSession({
    required String partId,
    required String partTitle,
    required String sellerName,
    String buyerName = 'You',
  }) {
    final id = 'chat_$partId';
    final existing = _sessions[id];
    if (existing != null) return existing;

    final session = ChatSession(
      id: id,
      partTitle: partTitle,
      sellerName: sellerName,
      buyerName: buyerName,
      flowStep: ChatFlowStep.started,
      isGuided: true,
    );

    _sessions[id] = session;
    return session;
  }

  void save(ChatSession session) => _sessions[session.id] = session;
}
