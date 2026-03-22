import 'package:flutter/material.dart';
import 'package:organiq/modules/suggestions/data/models/suggestion_block.dart';
import 'package:organiq/shared/components/oq_lib/index.dart';
import 'package:organiq/shared/theme/app_colors.dart';
import 'package:organiq/shared/utils/date_time.dart';

class SuggestionBlockCard extends StatelessWidget {
  const SuggestionBlockCard({
    super.key,
    required this.block,
    required this.accepted,
    required this.loading,
    required this.onAccept,
  });

  final SuggestionBlock block;
  final bool accepted;
  final bool loading;
  final VoidCallback? onAccept;

  @override
  Widget build(BuildContext context) {
    final icon = _iconForType(block.type);
    final schedule = _scheduleText(block);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accepted ? AppColors.success600 : AppColors.ai300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: OQText(
                  block.title,
                  context: context,
                ).subtitulo.color(AppColors.text).build(),
              ),
            ],
          ),
          if (schedule.isNotEmpty) ...[
            const SizedBox(height: 4),
            OQText(
              schedule,
              context: context,
            ).caption.color(AppColors.textMuted).build(),
          ],
          if (block.rationale != null &&
              block.rationale!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            OQText(
              block.rationale!,
              context: context,
            ).caption.color(AppColors.textMuted).build(),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: accepted || loading ? null : onAccept,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: accepted ? AppColors.success600 : AppColors.ai600,
                ),
                foregroundColor: accepted
                    ? AppColors.success600
                    : AppColors.ai600,
                minimumSize: const Size.fromHeight(40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : OQText(accepted ? 'Criado ✓' : '✚ Criar', context: context)
                        .label
                        .color(
                          accepted ? AppColors.success600 : AppColors.ai600,
                        )
                        .build(),
            ),
          ),
        ],
      ),
    );
  }

  String _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'task':
        return '📋';
      case 'event':
        return '📅';
      case 'routine':
        return '🔄';
      default:
        return '✨';
    }
  }

  String _scheduleText(SuggestionBlock block) {
    if (block.isRoutine) {
      final weekdays = block.weekdays.map(_weekdayLabel).join(', ');
      final startAt = block.startsAt == null
          ? null
          : DateTimeUtils.toUserTimezone(block.startsAt!);
      final endAt = block.endsAt == null
          ? null
          : DateTimeUtils.toUserTimezone(block.endsAt!);
      final start = startAt != null ? _hhmm(startAt) : null;
      final end = endAt != null ? _hhmm(endAt) : null;
      final hourText = switch ((start, end)) {
        (String s, String e) => '$s - $e',
        (String s, null) => s,
        _ => '',
      };
      if (weekdays.isEmpty && hourText.isEmpty) return '';
      if (weekdays.isEmpty) return hourText;
      if (hourText.isEmpty) return weekdays;
      return '$weekdays • $hourText';
    }

    final start = block.startsAt == null
        ? null
        : DateTimeUtils.toUserTimezone(block.startsAt!);
    final end = block.endsAt == null
        ? null
        : DateTimeUtils.toUserTimezone(block.endsAt!);
    if (start == null && end == null) return '';
    if (start != null && end != null) {
      return '${_dateLabel(start)} ${_hhmm(start)} - ${_hhmm(end)}';
    }
    if (start != null) {
      return '${_dateLabel(start)} ${_hhmm(start)}';
    }
    return '${_dateLabel(end!)} ${_hhmm(end)}';
  }

  String _dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  String _hhmm(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _weekdayLabel(int weekday) {
    return switch (weekday) {
      0 => 'Dom',
      1 => 'Seg',
      2 => 'Ter',
      3 => 'Qua',
      4 => 'Qui',
      5 => 'Sex',
      6 => 'Sáb',
      _ => '',
    };
  }
}
