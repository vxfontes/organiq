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
    DateTime? now,
  }) {
    final base = (now ?? DateTime.now()).toLocal();
    final dayStart = DateTime(base.year, base.month, base.day, 8);
    final dayEnd = DateTime(base.year, base.month, base.day, 22);
    final from = base.isAfter(dayStart) ? base : dayStart;

    if (!from.isBefore(dayEnd)) {
      return const DayInsight(
        title: 'Dia encerrando',
        summary: 'Sem janela relevante para hoje.',
        footer: 'Sugestao: planeje o primeiro bloco de amanha.',
        isFocus: false,
      );
    }

    final ranges = _buildRanges(slots, from: from, until: dayEnd);
    final best = _findLargestGap(ranges, from: from, until: dayEnd);
    final hasAgenda = commitmentsCount > 0;

    if (!hasAgenda) {
      final minutes = best.duration.inMinutes;
      return DayInsight(
        title: 'Janela mais livre',
        summary:
            '${_time(best.start)}-${_time(best.end)} ($minutes min livres).',
        footer:
            'Sugestao: bloco de foco de 60 min a partir de ${_time(best.start)}.',
        isFocus: true,
      );
    }

    if (best.duration.inMinutes >= 120) {
      return DayInsight(
        title: 'Janela forte',
        summary:
            '${_time(best.start)}-${_time(best.end)} para tarefa profunda.',
        footer: 'Sugestão: reserve 90 min sem interrupcoes nesse intervalo.',
        isFocus: true,
      );
    }

    if (best.duration.inMinutes >= 45) {
      return DayInsight(
        title: 'Boa janela livre',
        summary:
            '${_time(best.start)}-${_time(best.end)} para avancar pendencias.',
        footer: 'Sugestao: bloco rapido de 45 min em ${_time(best.start)}.',
        isFocus: true,
      );
    }

    return DayInsight(
      title: 'Dia mais distribuido',
      summary:
          'A maior janela livre hoje e ${_time(best.start)}-${_time(best.end)}.',
      footer: 'Sugestao: use microblocos de 20 min entre compromissos.',
      isFocus: false,
    );
  }

  static String _time(DateTime date) => TextUtils.formatHourMinute(date);

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
    var best = _Range(start: from, end: until);

    if (busyRanges.isEmpty) return best;

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
