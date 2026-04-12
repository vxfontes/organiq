import 'package:dartz/dartz.dart';

import 'package:organiq/modules/shopping/data/models/shopping_item_create_input.dart';
import 'package:organiq/modules/shopping/data/models/shopping_item_list_output.dart';
import 'package:organiq/modules/shopping/data/models/shopping_item_output.dart';
import 'package:organiq/modules/shopping/data/models/shopping_item_update_input.dart';
import 'package:organiq/modules/shopping/data/models/shopping_list_create_input.dart';
import 'package:organiq/modules/shopping/data/models/shopping_list_list_output.dart';
import 'package:organiq/modules/shopping/data/models/shopping_list_output.dart';
import 'package:organiq/modules/shopping/data/models/shopping_list_update_input.dart';
import 'package:organiq/modules/shopping/domain/repositories/i_shopping_repository.dart';
import 'package:organiq/shared/errors/api_error_mapper.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/services/cache/cache_service.dart';
import 'package:organiq/shared/services/connectivity/connectivity_service.dart';
import 'package:organiq/shared/services/http/app_path.dart';
import 'package:organiq/shared/services/http/http_client.dart';

const _cacheKeyShoppingLists = 'cache:${AppPath.shoppingLists}';

String _cacheKeyShoppingItems(String listId) =>
    'cache:${AppPath.shoppingListItems(listId)}';

class ShoppingRepository implements IShoppingRepository {
  ShoppingRepository(this._httpClient, this._cache, this._connectivity);

  final IHttpClient _httpClient;
  final ICacheService _cache;
  final IConnectivityService _connectivity;

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  // -------------------------------------------------------------------------
  // fetchShoppingLists — estratégia cache-first com TTL de 5min
  //
  // 1. Tem cursor (paginação): vai direto à API.
  // 2. Sem cursor e cache válido: retorna cache.
  // 3. Sem cursor, cache ausente/expirado, offline: retorna NetworkFailure.
  // 4. Sem cursor, cache ausente/expirado, online: busca API, atualiza cache.
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, ShoppingListListOutput>> fetchShoppingLists({
    int? limit,
    String? cursor,
  }) async {
    if (cursor != null) {
      return _fetchShoppingListsFromApi(limit: limit, cursor: cursor);
    }

    final cached = await _cache.get(_cacheKeyShoppingLists);
    if (cached != null) {
      try {
        return Right(ShoppingListListOutput.fromDynamic(cached));
      } catch (_) {
        await _cache.invalidate(_cacheKeyShoppingLists);
      }
    }

    final online = await _connectivity.isOnline();
    if (!online) {
      return Left(
        NetworkFailure(
          message:
              'Sem conexão. Conecte-se à internet para carregar suas listas de compras.',
        ),
      );
    }

    return _fetchShoppingListsFromApi(limit: limit);
  }

  Future<Either<Failure, ShoppingListListOutput>> _fetchShoppingListsFromApi({
    int? limit,
    String? cursor,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (limit != null) query['limit'] = limit;
      if (cursor != null) query['cursor'] = cursor;

      final response = await _httpClient.get(
        AppPath.shoppingLists,
        queryParameters: query.isEmpty ? null : query,
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        final output = ShoppingListListOutput.fromDynamic(response.data);
        if (cursor == null && response.data is Map<String, dynamic>) {
          await _cache.set(
            _cacheKeyShoppingLists,
            response.data as Map<String, dynamic>,
          );
        }
        return Right(output);
      }

      return Left(
        GetListFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao carregar listas de compras.',
          ),
        ),
      );
    } catch (err) {
      return Left(GetListFailure(message: err.toString()));
    }
  }

  // -------------------------------------------------------------------------
  // fetchShoppingItems — estratégia cache-first com TTL de 5min
  //
  // Chave inclui listId para evitar colisões entre listas distintas.
  // 1. Tem cursor (paginação): vai direto à API.
  // 2. Sem cursor e cache válido: retorna cache.
  // 3. Sem cursor, cache ausente/expirado, offline: retorna NetworkFailure.
  // 4. Sem cursor, cache ausente/expirado, online: busca API, atualiza cache.
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, ShoppingItemListOutput>> fetchShoppingItems({
    required String listId,
    int? limit,
    String? cursor,
  }) async {
    final cacheKey = _cacheKeyShoppingItems(listId);

    if (cursor != null) {
      return _fetchShoppingItemsFromApi(
        listId: listId,
        limit: limit,
        cursor: cursor,
      );
    }

    final cached = await _cache.get(cacheKey);
    if (cached != null) {
      try {
        return Right(ShoppingItemListOutput.fromDynamic(cached));
      } catch (_) {
        await _cache.invalidate(cacheKey);
      }
    }

    final online = await _connectivity.isOnline();
    if (!online) {
      return Left(
        NetworkFailure(
          message:
              'Sem conexão. Conecte-se à internet para carregar os itens da lista.',
        ),
      );
    }

    return _fetchShoppingItemsFromApi(listId: listId, limit: limit);
  }

  Future<Either<Failure, ShoppingItemListOutput>> _fetchShoppingItemsFromApi({
    required String listId,
    int? limit,
    String? cursor,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (limit != null) query['limit'] = limit;
      if (cursor != null) query['cursor'] = cursor;

      final response = await _httpClient.get(
        AppPath.shoppingListItems(listId),
        queryParameters: query.isEmpty ? null : query,
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        final output = ShoppingItemListOutput.fromDynamic(response.data);
        if (cursor == null && response.data is Map<String, dynamic>) {
          await _cache.set(
            _cacheKeyShoppingItems(listId),
            response.data as Map<String, dynamic>,
          );
        }
        return Right(output);
      }

      return Left(
        GetListFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao carregar itens da lista.',
          ),
        ),
      );
    } catch (err) {
      return Left(GetListFailure(message: err.toString()));
    }
  }

  // -------------------------------------------------------------------------
  // createShoppingList — invalida cache de listas após sucesso
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, ShoppingListOutput>> createShoppingList(
    ShoppingListCreateInput input,
  ) async {
    try {
      final response = await _httpClient.post(
        AppPath.shoppingLists,
        data: input.toJson(),
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        await _cache.invalidate(_cacheKeyShoppingLists);
        return Right(ShoppingListOutput.fromDynamic(response.data));
      }

      return Left(
        SaveFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao criar lista de compra.',
          ),
        ),
      );
    } catch (err) {
      return Left(SaveFailure(message: err.toString()));
    }
  }

  // -------------------------------------------------------------------------
  // updateShoppingList — invalida cache de listas após sucesso
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, ShoppingListOutput>> updateShoppingList(
    ShoppingListUpdateInput input,
  ) async {
    try {
      final response = await _httpClient.patch(
        AppPath.shoppingListById(input.id),
        data: input.toJson(),
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        await _cache.invalidate(_cacheKeyShoppingLists);
        return Right(ShoppingListOutput.fromDynamic(response.data));
      }

      return Left(
        UpdateFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao atualizar lista de compra.',
          ),
        ),
      );
    } catch (err) {
      return Left(UpdateFailure(message: err.toString()));
    }
  }

  // -------------------------------------------------------------------------
  // deleteShoppingList — invalida cache de listas após sucesso
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, Unit>> deleteShoppingList(String id) async {
    try {
      final response = await _httpClient.delete(AppPath.shoppingListById(id));
      final statusCode = response.statusCode ?? 0;

      if (_isSuccess(statusCode)) {
        await _cache.invalidate(_cacheKeyShoppingLists);
        return const Right(unit);
      }

      return Left(
        DeleteFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao excluir lista de compras.',
          ),
        ),
      );
    } catch (err) {
      return Left(DeleteFailure(message: err.toString()));
    }
  }

  // -------------------------------------------------------------------------
  // createShoppingItem — invalida cache de itens da lista após sucesso
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, ShoppingItemOutput>> createShoppingItem(
    ShoppingItemCreateInput input,
  ) async {
    try {
      final response = await _httpClient.post(
        AppPath.shoppingListItems(input.listId),
        data: input.toJson(),
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        await _cache.invalidate(_cacheKeyShoppingItems(input.listId));
        return Right(ShoppingItemOutput.fromDynamic(response.data));
      }

      return Left(
        SaveFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao criar item da lista.',
          ),
        ),
      );
    } catch (err) {
      return Left(SaveFailure(message: err.toString()));
    }
  }

  // -------------------------------------------------------------------------
  // updateShoppingItem — ShoppingItemUpdateInput não carrega listId;
  // a invalidação por listId não é possível sem alterar a interface.
  // O TTL de 5min trata a consistência eventual neste caso.
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, ShoppingItemOutput>> updateShoppingItem(
    ShoppingItemUpdateInput input,
  ) async {
    try {
      final response = await _httpClient.patch(
        AppPath.shoppingItemById(input.id),
        data: input.toJson(),
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        return Right(ShoppingItemOutput.fromDynamic(response.data));
      }

      return Left(
        UpdateFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao atualizar item de compra.',
          ),
        ),
      );
    } catch (err) {
      return Left(UpdateFailure(message: err.toString()));
    }
  }

  // -------------------------------------------------------------------------
  // deleteShoppingItem — parâmetro é o id do item, não o listId;
  // a invalidação por listId não é possível sem alterar a interface.
  // O TTL de 5min trata a consistência eventual neste caso.
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, Unit>> deleteShoppingItem(String id) async {
    try {
      final response = await _httpClient.delete(AppPath.shoppingItemById(id));
      final statusCode = response.statusCode ?? 0;

      if (_isSuccess(statusCode)) {
        return const Right(unit);
      }

      return Left(
        DeleteFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao excluir item de compra.',
          ),
        ),
      );
    } catch (err) {
      return Left(DeleteFailure(message: err.toString()));
    }
  }
}
