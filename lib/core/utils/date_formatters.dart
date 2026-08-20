import 'package:qr_scanner/core/l10n/app_strings.dart';

abstract final class DateFormatters {
  static String relative(DateTime at, AppStrings s) {
    final now = DateTime.now();
    final diff = now.difference(at);
    if (diff.inMinutes < 1) return s.justNow;
    if (diff.inHours < 1) return s.minutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return s.hoursAgo(diff.inHours);
    if (diff.inDays < 7) return s.daysAgo(diff.inDays);
    final d = at.day.toString().padLeft(2, '0');
    final m = at.month.toString().padLeft(2, '0');
    return '$d.$m.${at.year}';
  }

  static String absolute(DateTime at) {
    final d = at.day.toString().padLeft(2, '0');
    final m = at.month.toString().padLeft(2, '0');
    final h = at.hour.toString().padLeft(2, '0');
    final min = at.minute.toString().padLeft(2, '0');
    return '$d.$m.${at.year} · $h:$min';
  }

  static HistoryGroup groupFor(DateTime at, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(at.year, at.month, at.day);
    final diff = today.difference(date).inDays;
    if (diff == 0) return HistoryGroup.today;
    if (diff == 1) return HistoryGroup.yesterday;
    if (diff < 7) return HistoryGroup.thisWeek;
    return HistoryGroup.older;
  }
}

enum HistoryGroup { today, yesterday, thisWeek, older }
