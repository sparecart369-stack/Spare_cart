import 'package:intl/intl.dart';

/// Parses Supabase ISO timestamps (UTC) into local [DateTime].
DateTime parseSupabaseDateTime(dynamic value) {
  return DateTime.parse(value as String).toLocal();
}

DateTime _dateOnly(DateTime time) {
  final local = time.toLocal();
  return DateTime(local.year, local.month, local.day);
}

bool isSameCalendarDay(DateTime a, DateTime b) {
  final da = _dateOnly(a);
  final db = _dateOnly(b);
  return da == db;
}

bool isYesterday(DateTime time) {
  final yesterday = _dateOnly(DateTime.now().subtract(const Duration(days: 1)));
  return _dateOnly(time) == yesterday;
}

/// Timestamp shown in the messages list (Today → time, Yesterday, or date).
String formatChatListTimestamp(DateTime time) {
  final local = time.toLocal();
  final now = DateTime.now();

  if (isSameCalendarDay(local, now)) {
    return DateFormat('h:mm a').format(local);
  }
  if (isYesterday(local)) return 'Yesterday';
  if (now.year == local.year) {
    return DateFormat('MMM d').format(local);
  }
  return DateFormat('MMM d, yyyy').format(local);
}

/// Time shown inside a chat bubble.
String formatChatMessageTime(DateTime time) {
  return DateFormat('h:mm a').format(time.toLocal());
}

/// Centered date separator inside a chat thread.
String formatChatDateSeparator(DateTime time) {
  final local = time.toLocal();
  final now = DateTime.now();

  if (isSameCalendarDay(local, now)) return 'Today';
  if (isYesterday(local)) return 'Yesterday';
  if (now.year == local.year) {
    return DateFormat('MMMM d').format(local);
  }
  return DateFormat('MMMM d, yyyy').format(local);
}
