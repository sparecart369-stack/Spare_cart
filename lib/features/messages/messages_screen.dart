import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:spare_kart/bloc/messages/messages_bloc.dart';
import 'package:spare_kart/core/router/app_routes.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/utils/responsive.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    final timeFormat = DateFormat('h:mm a');

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: BlocBuilder<MessagesBloc, MessagesState>(
        builder: (context, state) {
          return ListView.separated(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: r.horizontalPadding()),
            itemCount: state.threads.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final thread = state.threads[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Text(thread.participantName[0], style: const TextStyle(color: AppColors.primary)),
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
                        child: Text('${thread.unreadCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 11)),
                      )
                    : null,
                onTap: () => Navigator.pushNamed(context, AppRoutes.chatDetail, arguments: thread),
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
