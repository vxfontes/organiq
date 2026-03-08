import 'package:flutter/material.dart';
import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';

class CreateShoppingItemBottomSheet extends StatefulWidget {
  const CreateShoppingItemBottomSheet({
    super.key,
    required this.listTitle,
    required this.loadingListenable,
    required this.errorListenable,
    required this.onCreateItem,
  });

  final String listTitle;
  final ValueNotifier<bool> loadingListenable;
  final ValueNotifier<String?> errorListenable;
  final Future<bool> Function({required String title, String? quantity})
  onCreateItem;

  @override
  State<CreateShoppingItemBottomSheet> createState() =>
      _CreateShoppingItemBottomSheetState();
}

class _CreateShoppingItemBottomSheetState
    extends State<CreateShoppingItemBottomSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _quantityController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _quantityController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.loadingListenable,
        widget.errorListenable,
      ]),
      builder: (sheetContext, _) {
        final loading = widget.loadingListenable.value;

        return IBBottomSheet(
          title: 'Novo item',
          subtitle: widget.listTitle,
          primaryLabel: 'Adicionar item',
          primaryLoading: loading,
          primaryEnabled: !loading,
          onPrimaryPressed: () async {
            final success = await widget.onCreateItem(
              title: _titleController.text,
              quantity: _quantityController.text,
            );

            if (!mounted || !sheetContext.mounted) return;

            if (success) {
              _closeSheet(sheetContext);
              return;
            }

            final message =
                widget.errorListenable.value ??
                'Não foi possível criar o item.';

            IBSnackBar.error(sheetContext, message);
          },
          secondaryLabel: 'Cancelar',
          secondaryEnabled: !loading,
          onSecondaryPressed: () => _closeSheet(sheetContext),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IBTextField(
                label: 'Item',
                hint: 'Ex: Arroz',
                controller: _titleController,
              ),
              const SizedBox(height: 12),
              IBTextField(
                label: 'Informações adicionais (opcional)',
                hint: 'Ex: 2 pacotes',
                controller: _quantityController,
              ),
            ],
          ),
        );
      },
    );
  }

  void _closeSheet(BuildContext context) {
    AppNavigation.pop(null, context);
  }
}
