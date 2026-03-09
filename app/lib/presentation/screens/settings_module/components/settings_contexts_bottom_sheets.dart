import 'package:flutter/material.dart';
import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';

class SettingsFlagFormData {
  const SettingsFlagFormData({required this.name, required this.color});

  final String name;
  final String color;
}

class SettingsFlagFormBottomSheet extends StatefulWidget {
  const SettingsFlagFormBottomSheet({
    super.key,
    required this.title,
    this.initialName,
    this.initialColor,
  });

  final String title;
  final String? initialName;
  final String? initialColor;

  @override
  State<SettingsFlagFormBottomSheet> createState() =>
      _SettingsFlagFormBottomSheetState();
}

class _SettingsFlagFormBottomSheetState
    extends State<SettingsFlagFormBottomSheet> {
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
          SettingsFlagFormData(
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

class SettingsNameFormBottomSheet extends StatefulWidget {
  const SettingsNameFormBottomSheet({
    super.key,
    required this.title,
    required this.label,
    this.initialValue,
  });

  final String title;
  final String label;
  final String? initialValue;

  @override
  State<SettingsNameFormBottomSheet> createState() =>
      _SettingsNameFormBottomSheetState();
}

class _SettingsNameFormBottomSheetState
    extends State<SettingsNameFormBottomSheet> {
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

class SettingsDeleteConfirmationBottomSheet extends StatelessWidget {
  const SettingsDeleteConfirmationBottomSheet({
    super.key,
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
