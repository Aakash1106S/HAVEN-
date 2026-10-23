import 'package:intl/intl.dart';

/// Date and time formatting utilities for Haven.
class HavenDateUtils {
  HavenDateUtils._();

  static final _dateTimeFormat = DateFormat('MMM d, y · h:mm a');
  static final _timeFormat = DateFormat('h:mm a');
  static final _dateFormat = DateFormat('MMM d, y');

  /// Format a [DateTime] to a readable string: "Oct 21, 2026 · 2:30 PM"
  static String formatDateTime(DateTime dt) => _dateTimeFormat.format(dt.toLocal());

  /// Format a [DateTime] to time only: "2:30 PM"
  static String formatTime(DateTime dt) => _timeFormat.format(dt.toLocal());

  /// Format a [DateTime] to date only: "Oct 21, 2026"
  static String formatDate(DateTime dt) => _dateFormat.format(dt.toLocal());

  /// Human-readable relative time: "just now", "5 min ago", "2 hours ago", "yesterday", "Oct 21"
  static String formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt.toLocal());

    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return formatDate(dt);
  }

  /// Format a cron expression into a human-readable description.
  static String describeCron(String cron, String timezone) {
    final parts = cron.trim().split(' ');
    if (parts.length < 5) return cron;

    final minute = parts[0];
    final hour = parts[1];
    final dayOfWeek = parts[4];

    try {
      final h = int.parse(hour);
      final m = int.parse(minute);
      final timeStr = DateFormat('h:mm a').format(
        DateTime(2000, 1, 1, h, m),
      );

      if (dayOfWeek == '*') {
        return 'Daily at $timeStr';
      }

      final dayMap = {'1': 'Mon', '2': 'Tue', '3': 'Wed', '4': 'Thu', '5': 'Fri', '6': 'Sat', '0': 'Sun'};
      final days = dayOfWeek.split(',').map((d) => dayMap[d] ?? d).join(', ');

      if (dayOfWeek == '1,2,3,4,5') return 'Weekdays at $timeStr';
      if (dayOfWeek == '0,6') return 'Weekends at $timeStr';

      return '$days at $timeStr';
    } catch (_) {
      return cron;
    }
  }

  /// Build a cron expression from hour, minute, and weekdays list (empty = daily).
  static String buildCron({
    required int hour,
    required int minute,
    List<int> weekdays = const [], // 0=Sun, 1=Mon, ... 6=Sat
  }) {
    final minuteStr = minute.toString().padLeft(2, '0');
    final hourStr = hour.toString();

    if (weekdays.isEmpty) {
      return '$minuteStr $hourStr * * *'; // Daily
    }

    final dayStr = weekdays.map((d) => d.toString()).join(',');
    return '$minuteStr $hourStr * * $dayStr';
  }

  /// Return the next DateTime that matches the cron (simplified - for display only).
  static DateTime? nextCronRun(String cron, String timezone) {
    try {
      final parts = cron.trim().split(' ');
      if (parts.length < 5) return null;

      final minute = int.parse(parts[0]);
      final hour = int.parse(parts[1]);
      final now = DateTime.now();

      // Find next occurrence at the given hour:minute
      var next = DateTime(now.year, now.month, now.day, hour, minute);
      if (next.isBefore(now)) {
        next = next.add(const Duration(days: 1));
      }
      return next;
    } catch (_) {
      return null;
    }
  }
}

// Top-level convenience wrappers
String formatDateTime(DateTime dt) => HavenDateUtils.formatDateTime(dt);
String formatTime(DateTime dt) => HavenDateUtils.formatTime(dt);
String formatDate(DateTime dt) => HavenDateUtils.formatDate(dt);
String formatRelativeTime(DateTime dt) => HavenDateUtils.formatRelativeTime(dt);
