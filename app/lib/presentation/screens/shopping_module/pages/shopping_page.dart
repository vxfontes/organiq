import 'package:flutter/material.dart';

import 'package:inbota/modules/shopping/data/models/shopping_item_output.dart';
import 'package:inbota/modules/shopping/data/models/shopping_list_output.dart';
import 'package:inbota/presentation/screens/shopping_module/components/create_shopping_item_bottom_sheet.dart';
import 'package:inbota/presentation/screens/shopping_module/components/create_shopping_list_bottom_sheet.dart';
import 'package:inbota/presentation/screens/shopping_module/controller/shopping_controller.dart';
import 'package:inbota/shared/components/ib_lib/index.dart';
import 'package:inbota/shared/state/ib_state.dart';
import 'package:inbota/shared/theme/app_colors.dart';
import 'package:inbota/shared/utils/text_utils.dart';

class ShoppingPage extends StatefulWidget {
  const ShoppingPage({super.key});

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends IBState<ShoppingPage, ShoppingController> {
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
    return AnimatedBuilder(
      animation: Listenable.merge([
        controller.loading,
        controller.visibleShoppingLists,
        controller.itemsByList,
      ]),
      builder: (context, _) {
        final loading = controller.loading.value;
        final shoppingLists = controller.visibleShoppingLists.value;
        final itemsByList = controller.itemsByList.value;

        final showFullLoading = loading && shoppingLists.isEmpty;

        return Stack(
          children: [
            ColoredBox(
              color: AppColors.background,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 18),
                  if (shoppingLists.isEmpty)
                    const IBCard(
                      child: IBEmptyState(
                        title: 'Sem listas de compras',
                        subtitle:
                            'Quando você confirmar uma lista pelo inbox, ela aparecerá aqui.',
                        icon: IBHugeIcon.shoppingBag,
                      ),
                    )
                  else
                    ...shoppingLists.map((shoppingList) {
                      final items = itemsByList[shoppingList.id] ?? const [];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Dismissible(
                          key: ValueKey('shopping-list-${shoppingList.id}'),
                          direction: DismissDirection.endToStart,
                          background: _buildDeleteBackground(),
                          confirmDismiss: (_) =>
                              controller.deleteShoppingList(shoppingList.id),
                          child: _buildShoppingListCard(
                            context,
                            shoppingList: shoppingList,
                            items: items,
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
            if (showFullLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: AppColors.background,
                  child: Center(
                    child: IBLoader(label: 'Carregando listas de compras...'),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IBText('Compras', context: context).titulo.build(),
              const SizedBox(height: 6),
              IBText(
                'Todas as suas listas e itens para comprar em um só lugar.',
                context: context,
              ).muted.build(),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Criar lista',
          onPressed: _openCreateShoppingListSheet,
          icon: const IBIcon(
            IBIcon.addRounded,
            color: AppColors.primary700,
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildShoppingListCard(
    BuildContext context, {
    required ShoppingListOutput shoppingList,
    required List<ShoppingItemOutput> items,
  }) {
    final doneCount = items.where((item) => item.isDone).length;
    final pendingCount = items.length - doneCount;
    final canConclude =
        !shoppingList.isDone && items.isNotEmpty && pendingCount == 0;
    final subtitle =
        '${TextUtils.countLabel(pendingCount, 'pendente', 'pendentes')} de ${TextUtils.countLabel(items.length, 'item', 'itens')}';

    return IBTodoList(
      title: shoppingList.title,
      subtitle: subtitle,
      action: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCompactActionButton(
            tooltip: 'Adicionar item',
            onPressed: () => _openCreateShoppingItemSheet(shoppingList),
            icon: const IBIcon(
              IBIcon.addRounded,
              color: AppColors.primary700,
              size: 18,
            ),
          ),
          if (canConclude)
            _buildCompactActionButton(
              tooltip: 'Concluir',
              onPressed: () => controller.concludeList(shoppingList.id),
              icon: const IBIcon(
                IBIcon.checkRounded,
                color: AppColors.primary700,
                size: 18,
              ),
            ),
        ],
      ),
      items: items
          .map(
            (item) => IBTodoItemData(
              id: item.id,
              title: item.title,
              subtitle: _itemSubtitle(item),
              done: item.isDone,
            ),
          )
          .toList(),
      emptyLabel: 'Nenhum item nesta lista.',
      onToggle: (index, done) {
        controller.toggleItemAt(shoppingList.id, index, done);
      },
      onDelete: (index) => controller.deleteItemAt(shoppingList.id, index),
    );
  }

  String? _itemSubtitle(ShoppingItemOutput item) {
    final quantity = item.quantity?.trim();
    if (quantity == null || quantity.isEmpty) return null;
    return 'Adicional: $quantity';
  }

  Widget _buildCompactActionButton({
    required String tooltip,
    required VoidCallback onPressed,
    required Widget icon,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: icon,
      padding: EdgeInsets.zero,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
      constraints: const BoxConstraints.tightFor(width: 30, height: 30),
      splashRadius: 18,
    );
  }

  Future<void> _openCreateShoppingListSheet() async {
    if (!mounted) return;

    await IBBottomSheet.show<void>(
      context: context,
      isFitWithContent: true,
      child: CreateShoppingListBottomSheet(
        loadingListenable: controller.loading,
        errorListenable: controller.error,
        onCreateList: controller.createShoppingList,
      ),
    );
  }

  Future<void> _openCreateShoppingItemSheet(ShoppingListOutput list) async {
    if (!mounted) return;

    await IBBottomSheet.show<void>(
      context: context,
      isFitWithContent: true,
      child: CreateShoppingItemBottomSheet(
        listTitle: list.title,
        loadingListenable: controller.loading,
        errorListenable: controller.error,
        onCreateItem: ({required title, quantity}) {
          return controller.createShoppingItem(
            listId: list.id,
            title: title,
            quantity: quantity,
          );
        },
      ),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.danger600,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const IBIcon(
        IBIcon.deleteOutlineRounded,
        color: AppColors.surface,
        size: 22,
      ),
    );
  }
}
