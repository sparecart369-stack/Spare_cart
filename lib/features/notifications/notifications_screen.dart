import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spare_kart/core/theme/app_colors.dart';
import 'package:spare_kart/core/utils/responsive.dart';
import 'package:spare_kart/core/widgets/common_widgets.dart';
import 'package:spare_kart/data/models/models.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);
    const notifications = <AppNotification>[];
    final timeFormat = DateFormat('h:mm a');

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notifications.isEmpty
          ? const EmptyState(icon: Icons.notifications_none_rounded, title: 'No notifications yet')
          : ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: r.horizontalPadding()),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) => _NotificationTile(
                notification: notifications[i],
                timeFormat: timeFormat,
              ),
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.timeFormat,
  });

  final AppNotification notification;
  final DateFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: CircleAvatar(
        backgroundColor: notification.isRead ? AppColors.chipBg : AppColors.primaryLight,
        child: Icon(
          Icons.notifications_rounded,
          color: notification.isRead ? AppColors.textSecondary : AppColors.primary,
          size: 20,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              notification.title,
              style: TextStyle(
                fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
              ),
            ),
          ),
          Text(
            _formatTime(notification.timestamp, timeFormat),
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          notification.body,
          style: TextStyle(
            color: notification.isRead ? AppColors.textSecondary : AppColors.textPrimary,
          ),
        ),
      ),
      trailing: notification.isRead
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
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
