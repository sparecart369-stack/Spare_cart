import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spare_kart/bloc/auth/auth_bloc.dart';
import 'package:spare_kart/bloc/messages/messages_bloc.dart';
import 'package:spare_kart/features/messages/chat_session_store.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

/// Keeps [MessagesBloc] in sync with [ChatSessionStore] for live updates and unread counts.
class MessageSyncHost extends StatefulWidget {
  const MessageSyncHost({super.key, required this.child});

  final Widget child;

  @override
  State<MessageSyncHost> createState() => _MessageSyncHostState();
}

class _MessageSyncHostState extends State<MessageSyncHost> {
  @override
  void initState() {
    super.initState();
    ChatSessionStore.instance.addListener(_syncMessages);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    ChatSessionStore.instance.removeListener(_syncMessages);
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    await ChatSessionStore.instance.initialize(userId);
    if (!mounted) return;
    _syncMessages();
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
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        _bootstrap();
      },
      child: widget.child,
    );
  }
}
