import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:spare_kart/bloc/messages/messages_bloc.dart';
import 'package:spare_kart/core/router/app_routes.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/utils/responsive.dart';
import 'package:spare_kart/core/widgets/common_widgets.dart';
import 'package:spare_kart/features/messages/chat_detail_screen.dart';
import 'package:spare_kart/features/messages/chat_session_store.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    ChatSessionStore.instance.addListener(_syncMessages);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    await ChatSessionStore.instance.initialize(userId);
    if (!mounted) return;
    _syncMessages();
  }

  @override
  void dispose() {
    ChatSessionStore.instance.removeListener(_syncMessages);
    super.dispose();
  }

  void _syncMessages() {
    if (!mounted) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    context.read<MessagesBloc>().add(
          MessagesSyncedFromStore(currentUserId: userId),
        );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final timeFormat = DateFormat('h:mm a');

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: BlocBuilder<MessagesBloc, MessagesState>(
        builder: (context, state) {
          if (state.threads.isEmpty) {
            return const EmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'No messages yet',
              subtitle: 'Start a conversation from a listing',
            );
          }
          return ListView.separated(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: r.horizontalPadding()),
            itemCount: state.threads.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final thread = state.threads[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    thread.participantName.isNotEmpty
                        ? thread.participantName[0]
                        : '?',
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(thread.participantName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Text(
                      _formatTime(thread.timestamp, timeFormat),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(thread.partTitle, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                    Text(thread.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
                trailing: thread.unreadCount > 0
                    ? Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: Text(
                          '${thread.unreadCount}',
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      )
                    : null,
                onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.chatDetail,
                  arguments: ChatArgs(thread: thread),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time, DateFormat format) {
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) return format.format(time);
    if (now.difference(time).inDays == 1) return 'Yesterday';
    return DateFormat('MMM d').format(time);
  }
}
