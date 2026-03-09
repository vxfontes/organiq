import 'package:flutter/material.dart';
import 'package:inbota/modules/flags/data/models/flag_output.dart';
import 'package:inbota/modules/flags/data/models/subflag_output.dart';
import 'package:inbota/presentation/screens/settings_module/components/settings_contexts_bottom_sheets.dart';
import 'package:inbota/presentation/screens/settings_module/components/settings_contexts_empty_state_card.dart';
import 'package:inbota/presentation/screens/settings_module/components/settings_contexts_flag_card.dart';
import 'package:inbota/presentation/screens/settings_module/components/settings_contexts_header_row.dart';
import 'package:inbota/presentation/screens/settings_module/controller/settings_contexts_controller.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/state/ib_state.dart';
import 'package:inbota/shared/theme/app_colors.dart';

class SettingsContextsPage extends StatefulWidget {
  const SettingsContextsPage({super.key});

  @override
  State<SettingsContextsPage> createState() => _SettingsContextsPageState();
}

class _SettingsContextsPageState
    extends IBState<SettingsContextsPage, SettingsContextsController> {
  @override
  void initState() {
    super.initState();
    controller.load();
    controller.error.addListener(_onErrorChanged);
  }

  @override
  void dispose() {
    controller.error.removeListener(_onErrorChanged);
    super.dispose();
  }

  void _onErrorChanged() {
    final error = controller.error.value;
    if (error != null && error.isNotEmpty && mounted) {
      IBSnackBar.error(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const IBLightAppBar(title: 'Flags e subflags'),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          controller.loading,
          controller.saving,
          controller.flags,
          controller.subflagsByFlag,
        ]),
        builder: (context, _) {
          final loading = controller.loading.value;
          final saving = controller.saving.value;
          final flags = controller.flags.value;
          final totalSubflags = flags.fold<int>(
            0,
            (sum, flag) => sum + controller.subflagsOf(flag.id).length,
          );

          if (loading && !controller.hasContent) {
            return const Center(
              child: IBLoader(label: 'Carregando contextos...'),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: [
                SettingsContextsHeaderRow(
                  disabled: saving,
                  onCreateFlag: _onCreateFlagPressed,
                  flagCount: flags.length,
                  subflagCount: totalSubflags,
                ),
                if (saving) ...[
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(minHeight: 2),
                ],
                const SizedBox(height: 16),
                if (flags.isEmpty)
                  SettingsContextsEmptyStateCard(
                    disabled: saving,
                    onCreateFlag: _onCreateFlagPressed,
                  ),
                if (flags.isNotEmpty)
                  ...flags.expand((flag) {
                    return [
                      SettingsContextsFlagCard(
                        flag: flag,
                        subflags: controller.subflagsOf(flag.id),
                        disabled: saving,
                        parseColor: _parseColor,
                        onAddSubflag: () => _onCreateSubflagPressed(flag),
                        onEditFlag: () => _onEditFlagPressed(flag),
                        onDeleteFlag: () => _onDeleteFlagPressed(flag),
                        onEditSubflag: _onEditSubflagPressed,
                        onDeleteSubflag: _onDeleteSubflagPressed,
                      ),
                      const SizedBox(height: 12),
                    ];
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _onCreateFlagPressed() async {
    final form = await _showFlagFormBottomSheet(title: 'Nova flag');
    if (form == null) return;
    await controller.createFlag(name: form.name, color: form.color);
  }

  Future<void> _onEditFlagPressed(FlagOutput flag) async {
    final form = await _showFlagFormBottomSheet(
      title: 'Editar flag',
      initialName: flag.name,
      initialColor: flag.color,
    );
    if (form == null) return;
    await controller.updateFlag(
      id: flag.id,
      name: form.name,
      color: form.color,
    );
  }

  Future<void> _onDeleteFlagPressed(FlagOutput flag) async {
    final confirmed = await _showDeleteConfirmation(
      title: 'Excluir flag',
      body:
          'Essa ação remove "${flag.name}" e suas subflags. Deseja continuar?',
    );
    if (confirmed != true) return;
    await controller.deleteFlag(flag.id);
  }

  Future<void> _onCreateSubflagPressed(FlagOutput flag) async {
    final name = await _showSimpleNameBottomSheet(
      title: 'Nova subflag',
      label: 'Nome da subflag',
    );
    if (name == null) return;
    await controller.createSubflag(flagId: flag.id, name: name);
  }

  Future<void> _onEditSubflagPressed(SubflagOutput subflag) async {
    final name = await _showSimpleNameBottomSheet(
      title: 'Editar subflag',
      label: 'Nome da subflag',
      initialValue: subflag.name,
    );
    if (name == null) return;
    await controller.updateSubflag(id: subflag.id, name: name);
  }

  Future<void> _onDeleteSubflagPressed(SubflagOutput subflag) async {
    final confirmed = await _showDeleteConfirmation(
      title: 'Excluir subflag',
      body: 'Deseja excluir "${subflag.name}"?',
    );
    if (confirmed != true) return;
    await controller.deleteSubflag(subflag.id);
  }

  Future<bool?> _showDeleteConfirmation({
    required String title,
    required String body,
  }) {
    return IBBottomSheet.show<bool>(
      context: context,
      isFitWithContent: true,
      child: SettingsDeleteConfirmationBottomSheet(title: title, body: body),
    );
  }

  Future<SettingsFlagFormData?> _showFlagFormBottomSheet({
    required String title,
    String? initialName,
    String? initialColor,
  }) {
    return IBBottomSheet.show<SettingsFlagFormData>(
      context: context,
      isFitWithContent: true,
      child: SettingsFlagFormBottomSheet(
        title: title,
        initialName: initialName,
        initialColor: initialColor,
      ),
    );
  }

  Future<String?> _showSimpleNameBottomSheet({
    required String title,
    required String label,
    String? initialValue,
  }) {
    return IBBottomSheet.show<String>(
      context: context,
      isFitWithContent: true,
      child: SettingsNameFormBottomSheet(
        title: title,
        label: label,
        initialValue: initialValue,
      ),
    );
  }

  Color _parseColor(String? hexColor) {
    final raw = hexColor?.trim() ?? '';
    if (raw.isEmpty) return AppColors.primary600;

    var hex = raw.toUpperCase().replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return AppColors.primary600;

    final value = int.tryParse(hex, radix: 16);
    if (value == null) return AppColors.primary600;
    return Color(value);
  }
}
