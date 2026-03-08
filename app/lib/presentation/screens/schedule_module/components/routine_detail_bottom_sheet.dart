import 'package:flutter/material.dart';
import 'package:inbota/modules/routines/data/models/routine_output.dart';
import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:inbota/presentation/screens/schedule_module/components/create_routine_bottom_sheet.dart';
import 'package:inbota/presentation/screens/schedule_module/controller/schedule_controller.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/theme/app_colors.dart';
import 'package:inbota/shared/utils/reminders_format.dart';

class RoutineDetailBottomSheet extends StatefulWidget {
  const RoutineDetailBottomSheet({
    super.key,
    required this.routine,
    required this.controller,
  });

  final RoutineOutput routine;
  final ScheduleController controller;

  @override
  State<RoutineDetailBottomSheet> createState() => _RoutineDetailBottomSheetState();
}

class _RoutineDetailBottomSheetState extends State<RoutineDetailBottomSheet> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadRoutineDetails(widget.routine.id);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.controller.detailsLoading,
        widget.controller.currentRoutineHistory,
        widget.controller.currentRoutineStreak,
      ]),
      builder: (context, _) {
        final isLoading = widget.controller.detailsLoading.value;
        final history = widget.controller.currentRoutineHistory.value;
        final streak = widget.controller.currentRoutineStreak.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildHeader(context),
              const SizedBox(height: 16),
              _buildInfoGrid(context),
              const SizedBox(height: 16),
              _buildContextSection(context),
              const SizedBox(height: 16),
              _buildHistorySection(context, history, isLoading),
              const SizedBox(height: 12),
              _buildStreakSection(context, streak, isLoading),
              const SizedBox(height: 24),
              _buildActions(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IBText(widget.routine.title, context: context).titulo.build(),
        if (widget.routine.description != null && widget.routine.description!.isNotEmpty) ...[
          const SizedBox(height: 4),
          IBText(widget.routine.description!, context: context).body.color(AppColors.textMuted).build(),
        ],
      ],
    );
  }

  Widget _buildInfoGrid(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildInfoRow(context, 'Horário', widget.routine.timeLabel, IBIcon.alarmOutlined),
          const Divider(height: 24),
          _buildInfoRow(context, 'Dias', widget.routine.weekdaysLabel, IBIcon.calendar),
          const Divider(height: 24),
          _buildInfoRow(context, 'Frequência', widget.routine.recurrenceTypeLabel, IBIcon.repeatRounded),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        IBIcon(icon, size: 18, color: AppColors.primary600),
        const SizedBox(width: 12),
        IBText(label, context: context).label.build(),
        const Spacer(),
        IBText(value, context: context).body.weight(FontWeight.w600).build(),
      ],
    );
  }

  Widget _buildContextSection(BuildContext context) {
    final color = widget.controller.routineTagColor(widget.routine);
    final hasFlag = widget.routine.flagName != null;
    final hasSubflag = widget.routine.subflagName != null;

    if (!hasFlag) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IBText('Contexto', context: context).subtitulo.build(),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            IBChip(
              label: widget.routine.flagName!,
              color: color,
            ),
            if (hasSubflag)
              IBChip(
                label: widget.routine.subflagName!,
                color: color.withValues(alpha: 0.8),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistorySection(BuildContext context, List<dynamic> history, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IBText('Histórico recente', context: context).subtitulo.build(),
        const SizedBox(height: 12),
        if (isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
        else if (history.isEmpty)
          IBText('Nenhuma conclusão registrada ainda.', context: context).body.color(AppColors.textMuted).build()
        else
          ...history.take(5).map((h) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const IBIcon(IBIcon.checkCircleOutlineRounded, color: AppColors.primary600, size: 18),
                const SizedBox(width: 8),
                IBText(_formatHistoryDate(h.completedOn), context: context).body.build(),
              ],
            ),
          )),
      ],
    );
  }

  Widget _buildStreakSection(BuildContext context, dynamic streak, bool isLoading) {
    if (isLoading) return const SizedBox.shrink();
    if (streak == null || streak.currentStreak == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning500.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const IBIcon(Icons.local_fire_department_rounded, size: 32, color: AppColors.warning500),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IBText('${streak.currentStreak} semanas consecutivas', context: context).label.weight(FontWeight.w700).build(),
                IBText('Mandou bem! Continue firme.', context: context).caption.build(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: IBButton(
            label: 'Editar',
            variant: IBButtonVariant.secondary,
            onPressed: () {
              AppNavigation.pop(null, context);
              widget.controller.startEditRoutine(widget.routine);
              _openEditForm();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: IBButton(
            label: widget.routine.isActive ? 'Desativar' : 'Ativar',
            variant: IBButtonVariant.ghost,
            // color: widget.routine.isActive ? AppColors.danger600 : AppColors.success600,
            onPressed: () {
              widget.controller.toggleRoutineActive(widget.routine, !widget.routine.isActive);
              AppNavigation.pop(null, context);
            },
          ),
        ),
      ],
    );
  }

  void _openEditForm() {
    IBBottomSheet.show<void>(
      context: context,
      smallBottomSheet: false,
      child: CreateRoutineBottomSheet(controller: widget.controller),
    );
  }

  String _formatHistoryDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return RemindersFormat.formatDate(date);
    } catch (_) {
      return dateStr;
    }
  }
}
