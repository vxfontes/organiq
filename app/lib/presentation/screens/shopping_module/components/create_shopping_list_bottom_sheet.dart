import 'package:flutter/material.dart';
import 'package:inbota/presentation/routes/app_navigation.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';

class CreateShoppingListBottomSheet extends StatefulWidget {
  const CreateShoppingListBottomSheet({
    super.key,
    required this.loadingListenable,
    required this.errorListenable,
    required this.onCreateList,
  });

  final ValueNotifier<bool> loadingListenable;
  final ValueNotifier<String?> errorListenable;
  final Future<bool> Function({required String title}) onCreateList;

  @override
  State<CreateShoppingListBottomSheet> createState() =>
      _CreateShoppingListBottomSheetState();
}

class _CreateShoppingListBottomSheetState
    extends State<CreateShoppingListBottomSheet> {
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
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
          title: 'Nova lista de compras',
          primaryLabel: 'Criar lista',
          primaryLoading: loading,
          primaryEnabled: !loading,
          onPrimaryPressed: () async {
            final success = await widget.onCreateList(
              title: _titleController.text,
            );

            if (!mounted || !sheetContext.mounted) return;

            if (success) {
              _closeSheet(sheetContext);
              return;
            }

            final message =
                widget.errorListenable.value ??
                'Não foi possível criar a lista.';

            ScaffoldMessenger.of(
              sheetContext,
            ).showSnackBar(SnackBar(content: Text(message)));
          },
          secondaryLabel: 'Cancelar',
          secondaryEnabled: !loading,
          onSecondaryPressed: () => _closeSheet(sheetContext),
          child: IBTextField(
            label: 'Nome da lista',
            hint: 'Ex: Compras da semana',
            controller: _titleController,
          ),
        );
      },
    );
  }

  void _closeSheet(BuildContext context) {
    AppNavigation.pop(null, context);
  }
}
