import 'package:flutter/foundation.dart';
import 'package:inbota/shared/utils/text_utils.dart';

class DayScheduleSlot {
  const DayScheduleSlot({required this.start, this.end});

  final DateTime start;
  final DateTime? end;
}

class DayInsight {
  const DayInsight({
    required this.title,
    required this.summary,
    required this.footer,
    required this.isFocus,
  });

  final String title;
  final String summary;
  final String footer;
  final bool isFocus;
}

class HomeInsightsUtils {
  HomeInsightsUtils._();

  static DayInsight buildDailyInsight({
    required List<DayScheduleSlot> slots,
    required int commitmentsCount,
    required int untimedCount,
    bool debugLogs = false,
    DateTime? now,
  }) {
    final base = (now ?? DateTime.now()).toLocal();
    final dayStart = DateTime(base.year, base.month, base.day, 8);
    var dayEnd = DateTime(base.year, base.month, base.day, 22);
    final latestSlotEnd = _latestSlotEnd(slots);
    if (latestSlotEnd != null && latestSlotEnd.isAfter(dayEnd)) {
      dayEnd = latestSlotEnd;
    }
    final from = base.isAfter(dayStart) ? base : dayStart;

    if (debugLogs && kDebugMode) {
      debugPrint(
        '[Insights] now=$base dayStart=$dayStart dayEnd=$dayEnd from=$from commitments=$commitmentsCount untimed=$untimedCount slots=${slots.length}',
      );
    }

    if (!from.isBefore(dayEnd)) {
      return const DayInsight(
        title: 'Dia encerrando',
        summary: 'Hoje já não há muito tempo livre.',
        footer: 'Planeje o começo de amanhã.',
        isFocus: false,
      );
    }

    if (untimedCount > 0 && slots.isEmpty) {
      return DayInsight(
        title: 'Horários pendentes',
        summary: '$untimedCount ainda sem horario.',
        footer: 'Defina os horários para se organizar melhor',
        isFocus: false,
      );
    }

    final ranges = _buildRanges(slots, from: from, until: dayEnd);
    if (debugLogs && kDebugMode) {
      for (final range in ranges) {
        debugPrint('[Insights] busy ${range.start} -> ${range.end}');
      }
    }

    final best = _findLargestGap(ranges, from: from, until: dayEnd);
    if (debugLogs && kDebugMode) {
      debugPrint('[Insights] best ${best.start} -> ${best.end}');
    }
    final hasAgenda = commitmentsCount > 0;
    final hasTimedSlots = slots.isNotEmpty;
    final untimedDominant = untimedCount >= (slots.length + 1);

    if (untimedCount > 0 && (!hasTimedSlots || untimedDominant)) {
      return DayInsight(
        title: 'Faltam horários',
        summary: '$untimedCount compromisso(s) ainda sem horario.',
        footer: 'Defina os horários para organizar melhor.',
        isFocus: false,
      );
    }

    if (!hasAgenda) {
      final minutes = best.duration.inMinutes;
      return DayInsight(
        title: 'Tempo livre',
        summary:
            '${_time(best.start)} – ${_time(best.end)} ($minutes min livres).',
        footer: 'Que tal adiantar algo às ${_time(best.start)}?',
        isFocus: true,
      );
    }

    if (best.duration.inMinutes >= 120) {
      return DayInsight(
        title: 'Melhor momento',
        summary:
            '${_time(best.start)} – ${_time(best.end)} para fazer algo em paz.',
        footer: untimedCount > 0
            ? 'Aproveite e veja $untimedCount tarefa(s) sem horario.'
            : 'Aproveitar tempo com menos interrupções.',
        isFocus: true,
      );
    }

    if (best.duration.inMinutes >= 45) {
      return DayInsight(
        title: 'Bom tempo livre',
        summary: '${_time(best.start)} – ${_time(best.end)} está disponível.',
        footer: 'Dá para resolver algo importante.',
        isFocus: true,
      );
    }

    return DayInsight(
      title: 'Dia mais corrido',
      summary:
          'Maior tempo livre hoje é ${_time(best.start)} – ${_time(best.end)}.',
      footer: 'Tente aproveitar pequenas pausas.',
      isFocus: false,
    );
  }

  static String _time(DateTime date) => TextUtils.formatHourMinute(date);

  static DateTime? _latestSlotEnd(List<DayScheduleSlot> slots) {
    if (slots.isEmpty) return null;
    DateTime? latest;
    for (final slot in slots) {
      final start = slot.start.toLocal();
      final end = (slot.end ?? start.add(const Duration(minutes: 45)))
          .toLocal();
      if (latest == null || end.isAfter(latest)) {
        latest = end;
      }
    }
    return latest;
  }

  static List<_Range> _buildRanges(
    List<DayScheduleSlot> slots, {
    required DateTime from,
    required DateTime until,
  }) {
    final ranges = <_Range>[];

    for (final slot in slots) {
      final start = slot.start.toLocal();
      final defaultEnd = start.add(const Duration(minutes: 45));
      final end = (slot.end ?? defaultEnd).toLocal();

      final clippedStart = start.isBefore(from) ? from : start;
      final clippedEnd = end.isAfter(until) ? until : end;
      if (!clippedEnd.isAfter(clippedStart)) continue;
      ranges.add(_Range(start: clippedStart, end: clippedEnd));
    }

    ranges.sort((a, b) => a.start.compareTo(b.start));
    if (ranges.isEmpty) return const [];

    final merged = <_Range>[ranges.first];
    for (var i = 1; i < ranges.length; i++) {
      final current = ranges[i];
      final last = merged.last;
      if (!current.start.isAfter(last.end)) {
        final mergedEnd = current.end.isAfter(last.end)
            ? current.end
            : last.end;
        merged[merged.length - 1] = _Range(start: last.start, end: mergedEnd);
      } else {
        merged.add(current);
      }
    }

    return merged;
  }

  static _Range _findLargestGap(
    List<_Range> busyRanges, {
    required DateTime from,
    required DateTime until,
  }) {
    var cursor = from;
    // Start with an empty gap. Real gaps found below can replace it.
    var best = _Range(start: from, end: from);

    if (busyRanges.isEmpty) {
      return _Range(start: from, end: until);
    }

    for (final range in busyRanges) {
      if (range.start.isAfter(cursor)) {
        final gap = _Range(start: cursor, end: range.start);
        if (gap.duration > best.duration) {
          best = gap;
        }
      }
      if (range.end.isAfter(cursor)) {
        cursor = range.end;
      }
    }

    if (until.isAfter(cursor)) {
      final tail = _Range(start: cursor, end: until);
      if (tail.duration > best.duration) {
        best = tail;
      }
    }

    return best;
  }
}

class _Range {
  const _Range({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  Duration get duration => end.difference(start);
}
