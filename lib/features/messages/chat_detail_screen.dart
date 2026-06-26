import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spare_kart/bloc/app_mode/app_mode_bloc.dart';
import 'package:spare_kart/bloc/messages/messages_bloc.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/utils/responsive.dart';
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
  late List<ChatMessage> _messages;
  ChatSession? _session;
  ChatFlowStep _flowStep = ChatFlowStep.completed;
  bool _isGuided = false;
  int _messageCounter = 0;

  @override
  void initState() {
    super.initState();
    _initChat();
    _prefillInitialMessage();
  }

  @override
  void activate() {
    super.activate();
    _reloadFromStore();
  }

  void _reloadFromStore() {
    if (_session == null) return;
    final fresh = ChatSessionStore.instance.get(_session!.id);
    if (fresh == null) return;
    setState(() {
      _session = fresh;
      _messages = List.from(fresh.messages);
      _flowStep = fresh.flowStep;
    });
    _prefillInitialMessage();
  }

  void _initChat() {
    final args = widget.args;
    if (args?.isNewGuidedChat == true) {
      final part = args!.part!;
      _session = ChatSessionStore.instance.startGuidedSession(
        partId: part.id,
        partTitle: part.fullTitle,
        sellerName: part.sellerName,
      );
      _messages = List.from(_session!.messages);
      _flowStep = _session!.flowStep;
      _isGuided = true;
      return;
    }

    final thread = args?.thread;
    if (thread != null) {
      final stored = ChatSessionStore.instance.get(thread.id);
      if (stored != null) {
        _session = stored;
        _messages = List.from(stored.messages);
        _flowStep = stored.flowStep;
        _isGuided = stored.isGuided;
        return;
      }
    }

    _messages = [];
    _flowStep = ChatFlowStep.completed;
  }

  void _prefillInitialMessage() {
    if (!_isGuided || _isSeller) return;
    if (_flowStep != ChatFlowStep.started || _messages.isNotEmpty) return;
    if (_controller.text.isNotEmpty) return;
    _controller.text = ChatFlow.initialBuyerMessage;
  }

  void _syncThread() {
    if (_session == null) return;
    context.read<MessagesBloc>().add(MessagesThreadUpserted(_session!.toThread(isSeller: false)));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isSeller => context.read<AppModeBloc>().state.isAdmin;

  String get _participantName {
    if (_session != null) {
      return _isSeller ? _session!.buyerName : _session!.sellerName;
    }
    return widget.args?.thread?.participantName ?? 'Seller';
  }

  String? get _partTitle => _session?.partTitle ?? widget.args?.thread?.partTitle;

  bool _isFromCurrentUser(ChatMessage msg) => _isSeller ? !msg.isMe : msg.isMe;

  bool get _isPrefilledOnly =>
      _isGuided && !_isSeller && _flowStep == ChatFlowStep.started && _messages.isEmpty;

  List<ChatQuickReply> get _quickReplies {
    if (!_isGuided || _flowStep == ChatFlowStep.completed) return [];
    if (_isSeller) {
      return ChatFlow.sellerReplies(_flowStep, lastBuyerMessage: _session?.lastBuyerMessage);
    }
    return ChatFlow.buyerReplies(_flowStep);
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

  void _sendMessage(String text, {required bool isBuyer}) {
    setState(() {
      _messageCounter++;
      _messages.add(ChatMessage(
        id: 'msg_$_messageCounter',
        text: text,
        isMe: isBuyer,
        timestamp: DateTime.now(),
      ));
      _session?.messages.add(_messages.last);
    });
    _scrollToBottom();
  }

  void _onQuickReply(ChatQuickReply reply) {
    final isBuyerReply = !_isSeller;
    _sendMessage(reply.message, isBuyer: isBuyerReply);

    setState(() {
      _flowStep = reply.nextStep;
      if (_session != null) {
        _session!.flowStep = _flowStep;
        ChatSessionStore.instance.save(_session!);
        context.read<MessagesBloc>().add(
              MessagesThreadUpserted(_session!.toThread(isSeller: _isSeller)),
            );
      }
    });
  }

  void _sendFreeText() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _sendMessage(text, isBuyer: !_isSeller);
    _controller.clear();

    if (_isGuided && _flowStep == ChatFlowStep.started && !_isSeller) {
      setState(() {
        _flowStep = ChatFlowStep.awaitingAvailability;
        _session?.flowStep = _flowStep;
      });
    }

    if (_session != null) {
      ChatSessionStore.instance.save(_session!);
      _syncThread();
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final quickReplies = _quickReplies;
    final guidedInputLocked = _isGuided && _flowStep != ChatFlowStep.completed && quickReplies.isNotEmpty;
    final inputEnabled = !guidedInputLocked;
    final canSend = inputEnabled && (_isPrefilledOnly ? _controller.text.trim().isNotEmpty : true);

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
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(r.horizontalPadding()),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                final isMine = _isFromCurrentUser(msg);
                return Align(
                  alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    constraints: BoxConstraints(maxWidth: r.width * 0.75),
                    decoration: BoxDecoration(
                      color: isMine ? AppColors.primary : AppColors.chipBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(color: isMine ? Colors.white : AppColors.textPrimary),
                    ),
                  ),
                );
              },
            ),
          ),
          if (quickReplies.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(r.horizontalPadding(), 8, r.horizontalPadding(), 4),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isSeller ? 'Quick reply' : 'Choose an option',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: quickReplies.map((reply) {
                        return ActionChip(
                          label: Text(reply.label),
                          backgroundColor: AppColors.primaryLight,
                          labelStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                          side: const BorderSide(color: AppColors.primary),
                          onPressed: () => _onQuickReply(reply),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          Container(
            padding: EdgeInsets.fromLTRB(r.horizontalPadding(), 8, r.horizontalPadding(), 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: quickReplies.isEmpty
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
                      readOnly: _isPrefilledOnly,
                      enabled: inputEnabled,
                      enableInteractiveSelection: !_isPrefilledOnly,
                      showCursor: !_isPrefilledOnly,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: guidedInputLocked
                            ? 'Select an option above...'
                            : 'Type a message...',
                        border: _isPrefilledOnly
                            ? OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(color: AppColors.primary),
                              )
                            : InputBorder.none,
                        enabledBorder: _isPrefilledOnly
                            ? OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(color: AppColors.primary),
                              )
                            : InputBorder.none,
                        focusedBorder: _isPrefilledOnly
                            ? OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                              )
                            : InputBorder.none,
                        filled: _isPrefilledOnly,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: canSend ? (_) => _sendFreeText() : null,
                    ),
                  ),
                  IconButton(
                    onPressed: canSend ? _sendFreeText : null,
                    icon: Icon(
                      Icons.send,
                      color: canSend ? AppColors.primary : AppColors.textTertiary,
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
