import 'package:flutter/material.dart';
import 'package:inbota/modules/flags/data/models/flag_output.dart';
import 'package:inbota/modules/flags/data/models/subflag_output.dart';
import 'package:inbota/presentation/routes/app_navigation.dart';
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
                Row(
                  children: [
                    Expanded(
                      child: IBText(
                        'Organize as partes da sua vida.',
                        context: context,
                      ).muted.build(),
                    ),
                    const SizedBox(width: 12),
                    _buildAddFlagButton(saving),
                  ],
                ),
                if (saving) ...[
                  const SizedBox(height: 10),
                  const LinearProgressIndicator(minHeight: 2),
                ],
                const SizedBox(height: 16),
                if (flags.isEmpty) _buildEmptyState(context, saving),
                if (flags.isNotEmpty)
                  ...flags.expand(
                    (flag) => [
                      _buildFlagCard(context, flag, saving),
                      const SizedBox(height: 12),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddFlagButton(bool disabled) {
    return SizedBox(
      width: 92,
      child: IBButton(
        label: 'Nova flag',
        variant: IBButtonVariant.ghost,
        onPressed: disabled ? null : _onCreateFlagPressed,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool disabled) {
    return IBCard(
      child: Column(
        children: [
          const IBEmptyState(
            title: 'Sem contextos ainda',
            subtitle:
                'Crie sua primeira flag para organizar tarefas e eventos.',
            icon: IBHugeIcon.home,
          ),
          const SizedBox(height: 14),
          IBButton(
            label: 'Criar primeira flag',
            onPressed: disabled ? null : _onCreateFlagPressed,
          ),
        ],
      ),
    );
  }

  Widget _buildFlagCard(BuildContext context, FlagOutput flag, bool disabled) {
    final subflags = controller.subflagsOf(flag.id);

    return IBCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _parseColor(flag.color),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IBText(
                      flag.name,
                      context: context,
                    ).subtitulo.maxLines(2).build(),
                    const SizedBox(height: 4),
                    IBText(
                      '${subflags.length} subflag(s)',
                      context: context,
                    ).caption.build(),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Adicionar subflag',
                onPressed: disabled
                    ? null
                    : () => _onCreateSubflagPressed(flag),
                icon: const IBIcon(
                  IBIcon.addRounded,
                  color: AppColors.primary700,
                ),
              ),
              IconButton(
                tooltip: 'Editar flag',
                onPressed: disabled ? null : () => _onEditFlagPressed(flag),
                icon: const IBIcon(
                  IBIcon.editOutlineRounded,
                  color: AppColors.textMuted,
                ),
              ),
              IconButton(
                tooltip: 'Excluir flag',
                onPressed: disabled ? null : () => _onDeleteFlagPressed(flag),
                icon: const IBIcon(
                  IBIcon.deleteOutlineRounded,
                  color: AppColors.danger600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (subflags.isEmpty)
            IBText(
              'Sem subflags. Adicione para detalhar esse contexto.',
              context: context,
            ).muted.build(),
          if (subflags.isNotEmpty)
            ...subflags.expand(
              (item) => [
                _buildSubflagRow(context, flag, item, disabled),
                const SizedBox(height: 8),
              ],
            ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: IBButton(
              label: 'Adicionar subflag',
              variant: IBButtonVariant.ghost,
              onPressed: disabled ? null : () => _onCreateSubflagPressed(flag),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubflagRow(
    BuildContext context,
    FlagOutput flag,
    SubflagOutput subflag,
    bool disabled,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _parseColor(subflag.color ?? flag.color),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: IBText(
              subflag.name,
              context: context,
            ).body.maxLines(2).build(),
          ),
          IconButton(
            tooltip: 'Editar subflag',
            onPressed: disabled ? null : () => _onEditSubflagPressed(subflag),
            icon: const IBIcon(
              IBIcon.editOutlineRounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ),
          IconButton(
            tooltip: 'Excluir subflag',
            onPressed: disabled ? null : () => _onDeleteSubflagPressed(subflag),
            icon: const IBIcon(
              IBIcon.deleteOutlineRounded,
              size: 20,
              color: AppColors.danger600,
            ),
          ),
        ],
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
      child: _DeleteConfirmationBottomSheet(title: title, body: body),
    );
  }

  Future<_FlagFormData?> _showFlagFormBottomSheet({
    required String title,
    String? initialName,
    String? initialColor,
  }) {
    return IBBottomSheet.show<_FlagFormData>(
      context: context,
      isFitWithContent: true,
      child: _FlagFormBottomSheet(
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
      child: _NameFormBottomSheet(
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

class _FlagFormData {
  const _FlagFormData({required this.name, required this.color});

  final String name;
  final String color;
}

class _FlagFormBottomSheet extends StatefulWidget {
  const _FlagFormBottomSheet({
    required this.title,
    this.initialName,
    this.initialColor,
  });

  final String title;
  final String? initialName;
  final String? initialColor;

  @override
  State<_FlagFormBottomSheet> createState() => _FlagFormBottomSheetState();
}

class _FlagFormBottomSheetState extends State<_FlagFormBottomSheet> {
  late final TextEditingController _nameController;
  String? _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _selectedColor = IBColorPicker.normalizeHex(widget.initialColor);
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _onNameChanged() => setState(() {});

  bool get _canSubmit => _nameController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return IBBottomSheet(
      title: widget.title,
      primaryLabel: 'Salvar',
      primaryEnabled: _canSubmit,
      onPrimaryPressed: () {
        if (!_canSubmit) return;
        AppNavigation.pop(
          _FlagFormData(
            name: _nameController.text,
            color: _selectedColor ?? '',
          ),
          context,
        );
      },
      secondaryLabel: 'Cancelar',
      onSecondaryPressed: () => AppNavigation.pop(null, context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          IBTextField(label: 'Nome da flag', controller: _nameController),
          const SizedBox(height: 14),
          IBColorPicker(
            label: 'Escolha uma cor',
            selectedColor: _selectedColor,
            onChanged: (value) => setState(() => _selectedColor = value),
          ),
        ],
      ),
    );
  }
}

class _NameFormBottomSheet extends StatefulWidget {
  const _NameFormBottomSheet({
    required this.title,
    required this.label,
    this.initialValue,
  });

  final String title;
  final String label;
  final String? initialValue;

  @override
  State<_NameFormBottomSheet> createState() => _NameFormBottomSheetState();
}

class _NameFormBottomSheetState extends State<_NameFormBottomSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _canSubmit => _controller.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return IBBottomSheet(
      title: widget.title,
      primaryLabel: 'Salvar',
      primaryEnabled: _canSubmit,
      onPrimaryPressed: () {
        if (!_canSubmit) return;
        AppNavigation.pop(_controller.text.trim(), context);
      },
      secondaryLabel: 'Cancelar',
      onSecondaryPressed: () => AppNavigation.pop(null, context),
      child: IBTextField(label: widget.label, controller: _controller),
    );
  }
}

class _DeleteConfirmationBottomSheet extends StatelessWidget {
  const _DeleteConfirmationBottomSheet({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return IBBottomSheet(
      title: title,
      primaryLabel: 'Excluir',
      onPrimaryPressed: () => AppNavigation.pop(true, context),
      secondaryLabel: 'Cancelar',
      onSecondaryPressed: () => AppNavigation.pop(false, context),
      child: IBText(body, context: context).body.build(),
    );
  }
}
