import 'package:flutter/material.dart';

import 'package:inbota/modules/shopping/data/models/shopping_item_create_input.dart';
import 'package:inbota/modules/shopping/data/models/shopping_item_output.dart';
import 'package:inbota/modules/shopping/data/models/shopping_item_update_input.dart';
import 'package:inbota/modules/shopping/data/models/shopping_list_create_input.dart';
import 'package:inbota/modules/shopping/data/models/shopping_list_output.dart';
import 'package:inbota/modules/shopping/data/models/shopping_list_update_input.dart';
import 'package:inbota/modules/shopping/domain/usecases/create_shopping_item_usecase.dart';
import 'package:inbota/modules/shopping/domain/usecases/create_shopping_list_usecase.dart';
import 'package:inbota/modules/shopping/domain/usecases/delete_shopping_item_usecase.dart';
import 'package:inbota/modules/shopping/domain/usecases/delete_shopping_list_usecase.dart';
import 'package:inbota/modules/shopping/domain/usecases/get_shopping_items_usecase.dart';
import 'package:inbota/modules/shopping/domain/usecases/get_shopping_lists_usecase.dart';
import 'package:inbota/modules/shopping/domain/usecases/update_shopping_item_usecase.dart';
import 'package:inbota/modules/shopping/domain/usecases/update_shopping_list_usecase.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/state/ib_state.dart';

class ShoppingController implements IBController {
  ShoppingController(
    this._getShoppingListsUsecase,
    this._getShoppingItemsUsecase,
    this._updateShoppingItemUsecase,
    this._createShoppingListUsecase,
    this._updateShoppingListUsecase,
    this._createShoppingItemUsecase,
    this._deleteShoppingListUsecase,
    this._deleteShoppingItemUsecase,
  );

  final GetShoppingListsUsecase _getShoppingListsUsecase;
  final GetShoppingItemsUsecase _getShoppingItemsUsecase;
  final UpdateShoppingItemUsecase _updateShoppingItemUsecase;
  final CreateShoppingListUsecase _createShoppingListUsecase;
  final UpdateShoppingListUsecase _updateShoppingListUsecase;
  final CreateShoppingItemUsecase _createShoppingItemUsecase;
  final DeleteShoppingListUsecase _deleteShoppingListUsecase;
  final DeleteShoppingItemUsecase _deleteShoppingItemUsecase;

  final ValueNotifier<bool> loading = ValueNotifier(false);
  final ValueNotifier<String?> error = ValueNotifier(null);
  final ValueNotifier<List<ShoppingListOutput>> shoppingLists = ValueNotifier(
    const [],
  );
  final ValueNotifier<List<ShoppingListOutput>> visibleShoppingLists =
      ValueNotifier(const []);
  final ValueNotifier<Map<String, List<ShoppingItemOutput>>> itemsByList =
      ValueNotifier(const {});

  final Set<String> _updatingItemIds = <String>{};

  @override
  void dispose() {
    loading.dispose();
    error.dispose();
    shoppingLists.dispose();
    visibleShoppingLists.dispose();
    itemsByList.dispose();
  }

  Future<void> load() async {
    if (loading.value) return;

    loading.value = true;
    error.value = null;

    final listsResult = await _getShoppingListsUsecase.call(limit: 50);

    List<ShoppingListOutput> loadedLists = const [];
    final hasListFailure = listsResult.fold(
      (failure) {
        _setError(
          failure,
          fallback: 'Não foi possível carregar suas listas de compras.',
        );
        return true;
      },
      (data) {
        loadedLists = _safeLists(data.items);
        return false;
      },
    );

    if (hasListFailure) {
      loading.value = false;
      return;
    }

    _setShoppingLists(loadedLists);

    final visibleLists = visibleShoppingLists.value;
    if (visibleLists.isEmpty) {
      itemsByList.value = const {};
      loading.value = false;
      return;
    }

    final nextItemsByList = <String, List<ShoppingItemOutput>>{};

    for (final list in visibleLists) {
      final itemsResult = await _getShoppingItemsUsecase.call(
        listId: list.id,
        limit: 200,
      );

      itemsResult.fold(
        (failure) {
          _setError(
            failure,
            fallback: 'Não foi possível carregar todos os itens de compras.',
          );
          nextItemsByList[list.id] = const [];
        },
        (output) {
          nextItemsByList[list.id] = _safeItems(output.items);
        },
      );
    }

    itemsByList.value = nextItemsByList;
    loading.value = false;
  }

  Future<bool> toggleItemAt(String listId, int index, bool checked) async {
    final currentListItems = itemsByList.value[listId];
    if (currentListItems == null) return false;
    if (index < 0 || index >= currentListItems.length) return false;

    final currentItem = currentListItems[index];
    if (_updatingItemIds.contains(currentItem.id)) return false;

    _updatingItemIds.add(currentItem.id);

    final result = await _updateShoppingItemUsecase.call(
      ShoppingItemUpdateInput(id: currentItem.id, checked: checked),
    );

    _updatingItemIds.remove(currentItem.id);

    return result.fold(
      (failure) {
        _setError(failure, fallback: 'Não foi possível atualizar o item.');
        _refreshItemsForList(listId);
        return false;
      },
      (updatedItem) {
        final nextMap = Map<String, List<ShoppingItemOutput>>.from(
          itemsByList.value,
        );
        final nextList = List<ShoppingItemOutput>.from(
          nextMap[listId] ?? const [],
        );

        final updatedIndex = nextList.indexWhere(
          (item) => item.id == updatedItem.id,
        );

        if (updatedIndex != -1) {
          nextList[updatedIndex] = updatedItem;
          nextMap[listId] = nextList;
          itemsByList.value = nextMap;
        }

        return true;
      },
    );
  }

  Future<bool> deleteItemAt(String listId, int index) async {
    final currentListItems = itemsByList.value[listId];
    if (currentListItems == null) return false;
    if (index < 0 || index >= currentListItems.length) return false;
    return deleteItemById(listId, currentListItems[index].id);
  }

  Future<bool> deleteItemById(String listId, String itemId) async {
    if (_updatingItemIds.contains(itemId)) return false;
    _updatingItemIds.add(itemId);

    final result = await _deleteShoppingItemUsecase.call(itemId);
    _updatingItemIds.remove(itemId);

    return result.fold(
      (failure) {
        _setError(failure, fallback: 'Não foi possível excluir o item.');
        return false;
      },
      (_) {
        final nextMap = Map<String, List<ShoppingItemOutput>>.from(
          itemsByList.value,
        );
        final nextList = List<ShoppingItemOutput>.from(
          nextMap[listId] ?? const [],
        )..removeWhere((item) => item.id == itemId);
        nextMap[listId] = nextList;
        itemsByList.value = nextMap;
        return true;
      },
    );
  }

  bool canConcludeList(String listId) {
    final items = itemsByList.value[listId] ?? const [];
    if (items.isEmpty) return false;
    return items.every((item) => item.isDone);
  }

  Future<bool> concludeList(String listId) async {
    if (!canConcludeList(listId)) {
      error.value = 'Marque todos os itens como comprados antes de concluir.';
      return false;
    }

    final result = await _updateShoppingListUsecase.call(
      ShoppingListUpdateInput(id: listId, status: 'DONE'),
    );

    return result.fold(
      (failure) {
        _setError(failure, fallback: 'Não foi possível concluir a lista.');
        return false;
      },
      (updatedList) {
        final nextLists = List<ShoppingListOutput>.from(shoppingLists.value);
        final listIndex = nextLists.indexWhere(
          (list) => list.id == updatedList.id,
        );

        if (listIndex != -1) {
          nextLists[listIndex] = updatedList;
          _setShoppingLists(nextLists);
        }

        final nextMap = Map<String, List<ShoppingItemOutput>>.from(
          itemsByList.value,
        );
        nextMap.remove(listId);
        itemsByList.value = nextMap;

        return true;
      },
    );
  }

  Future<bool> deleteShoppingList(String listId) async {
    final result = await _deleteShoppingListUsecase.call(listId);
    return result.fold(
      (failure) {
        _setError(failure, fallback: 'Não foi possível excluir a lista.');
        return false;
      },
      (_) {
        final nextLists = List<ShoppingListOutput>.from(shoppingLists.value)
          ..removeWhere((list) => list.id == listId);
        _setShoppingLists(nextLists);

        final nextMap = Map<String, List<ShoppingItemOutput>>.from(
          itemsByList.value,
        )..remove(listId);
        itemsByList.value = nextMap;
        return true;
      },
    );
  }

  Future<bool> createShoppingList({required String title}) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      error.value = 'Informe um titulo para a lista.';
      return false;
    }

    loading.value = true;
    error.value = null;

    final result = await _createShoppingListUsecase.call(
      ShoppingListCreateInput(title: trimmedTitle, status: 'OPEN'),
    );

    loading.value = false;

    return result.fold(
      (failure) {
        _setError(failure, fallback: 'Não foi possível criar a lista.');
        return false;
      },
      (createdList) {
        final nextLists = List<ShoppingListOutput>.from(shoppingLists.value);
        nextLists.insert(0, createdList);
        _setShoppingLists(nextLists);

        final nextMap = Map<String, List<ShoppingItemOutput>>.from(
          itemsByList.value,
        );
        nextMap.putIfAbsent(createdList.id, () => const []);
        itemsByList.value = nextMap;

        return true;
      },
    );
  }

  Future<bool> createShoppingItem({
    required String listId,
    required String title,
    String? quantity,
  }) async {
    final trimmedTitle = title.trim();
    final trimmedQuantity = quantity?.trim();

    if (trimmedTitle.isEmpty) {
      error.value = 'Informe um titulo para o item.';
      return false;
    }

    loading.value = true;
    error.value = null;

    final result = await _createShoppingItemUsecase.call(
      ShoppingItemCreateInput(
        listId: listId,
        title: trimmedTitle,
        quantity: trimmedQuantity == null || trimmedQuantity.isEmpty
            ? null
            : trimmedQuantity,
        checked: false,
      ),
    );

    loading.value = false;

    return result.fold(
      (failure) {
        _setError(failure, fallback: 'Não foi possível criar o item.');
        return false;
      },
      (createdItem) {
        final nextMap = Map<String, List<ShoppingItemOutput>>.from(
          itemsByList.value,
        );
        final list = List<ShoppingItemOutput>.from(nextMap[listId] ?? const []);
        list.add(createdItem);
        nextMap[listId] = list;
        itemsByList.value = nextMap;

        return true;
      },
    );
  }

  Future<void> _refreshItemsForList(String listId) async {
    final result = await _getShoppingItemsUsecase.call(
      listId: listId,
      limit: 200,
    );

    result.fold((_) {}, (output) {
      final nextMap = Map<String, List<ShoppingItemOutput>>.from(
        itemsByList.value,
      );
      nextMap[listId] = _safeItems(output.items);
      itemsByList.value = nextMap;
    });
  }

  void _setShoppingLists(List<ShoppingListOutput> lists) {
    shoppingLists.value = lists;
    visibleShoppingLists.value = lists
        .where((list) => !list.isDone && !list.isArchived)
        .toList(growable: false);
  }

  List<ShoppingListOutput> _safeLists(List<ShoppingListOutput> items) {
    return items.where((item) => item.id.isNotEmpty).toList(growable: false);
  }

  List<ShoppingItemOutput> _safeItems(List<ShoppingItemOutput> items) {
    return items.where((item) => item.id.isNotEmpty).toList(growable: false);
  }

  void _setError(Failure failure, {required String fallback}) {
    final message = failure.message?.trim();
    if (message != null && message.isNotEmpty) {
      error.value = message;
      return;
    }

    if (error.value == null || error.value!.isEmpty) {
      error.value = fallback;
    }
  }
}
