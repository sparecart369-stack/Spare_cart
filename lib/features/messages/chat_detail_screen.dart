import 'package:flutter/material.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/utils/responsive.dart';
import 'package:spare_kart/data/dummy_data.dart';
import 'package:spare_kart/data/models/models.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key, this.thread});

  final MessageThread? thread;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _controller = TextEditingController();
  final _messages = generateChatMessages();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final name = widget.thread?.participantName ?? 'Seller';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontSize: 16)),
            if (widget.thread != null)
              Text(widget.thread!.partTitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(r.horizontalPadding()),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                return Align(
                  alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    constraints: BoxConstraints(maxWidth: r.width * 0.75),
                    decoration: BoxDecoration(
                      color: msg.isMe ? AppColors.primary : AppColors.chipBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(color: msg.isMe ? Colors.white : AppColors.textPrimary),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(r.horizontalPadding(), 8, r.horizontalPadding(), 8),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (_controller.text.isEmpty) return;
                      setState(() {
                        _messages.add(ChatMessage(
                          id: 'new',
                          text: _controller.text,
                          isMe: true,
                          timestamp: DateTime.now(),
                        ));
                        _controller.clear();
                      });
                    },
                    icon: const Icon(Icons.send, color: AppColors.primary),
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
