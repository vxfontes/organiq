import 'package:inbota/modules/events/data/models/event_output.dart';
import 'package:inbota/shared/utils/text_utils.dart';

class DateTimeUtils {
  static DateTime startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static DateTime? parseDensityDay(String raw) {
    final normalized = raw.trim();
    final simpleDate = RegExp(
      r'^(\d{4})-(\d{2})-(\d{2})$',
    ).firstMatch(normalized);
    if (simpleDate != null) {
      final year = int.parse(simpleDate.group(1)!);
      final month = int.parse(simpleDate.group(2)!);
      final day = int.parse(simpleDate.group(3)!);
      return DateTime(year, month, day);
    }

    final parsed = DateTime.tryParse(normalized);
    if (parsed == null) return null;
    return startOfDay(parsed.toLocal());
  }

  static String dateParamYmd(DateTime now) {
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String eventStatus(EventOutput event, {DateTime? now}) {
    final start = event.startAt?.toLocal();
    if (start == null) return 'SEM DATA';

    final base = (now ?? DateTime.now()).toLocal();
    final today = DateTime(base.year, base.month, base.day);
    final eventDay = DateTime(start.year, start.month, start.day);
    final diff = eventDay.difference(today).inDays;

    if (diff == 0) return 'HOJE';
    if (diff == 1) return 'AMANHA';
    return 'AGENDADO';
  }

  static String relativeDateTimeLabel(DateTime? date, {DateTime? now}) {
    if (date == null) return 'Sem horario';
    final local = date.toLocal();
    final base = (now ?? DateTime.now()).toLocal();
    final today = DateTime(base.year, base.month, base.day);
    final target = DateTime(local.year, local.month, local.day);
    final diff = target.difference(today).inDays;

    final time = formatHourMinute(local);
    if (diff == 0) return 'Hoje $time';
    if (diff == 1) return 'Amanha $time';
    if (diff == -1) return 'Ontem $time';

    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    return '$day/$month $time';
  }

  static String eventSubtitle(EventOutput event) {
    final start = event.startAt?.toLocal();
    if (start == null) return 'Sem data definida';

    final day = start.day.toString().padLeft(2, '0');
    final month = start.month.toString().padLeft(2, '0');

    if (event.allDay) {
      return '$day/$month · Dia inteiro';
    }

    final startTime = formatHourMinute(start);
    final end = event.endAt?.toLocal();
    if (end == null) return '$day/$month · $startTime';

    final endTime = formatHourMinute(end);
    return '$day/$month · $startTime - $endTime';
  }

  static String formatHourMinute(DateTime date) {
    return TextUtils.formatHourMinute(date);
  }
}