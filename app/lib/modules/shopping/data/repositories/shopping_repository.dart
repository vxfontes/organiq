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
import 'package:organiq/shared/services/http/app_path.dart';
import 'package:organiq/shared/services/http/http_client.dart';

class ShoppingRepository implements IShoppingRepository {
  ShoppingRepository(this._httpClient);

  final IHttpClient _httpClient;

  @override
  Future<Either<Failure, ShoppingListListOutput>> fetchShoppingLists({
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
        return Right(ShoppingListListOutput.fromDynamic(response.data));
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

  @override
  Future<Either<Failure, ShoppingItemListOutput>> fetchShoppingItems({
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
        return Right(ShoppingItemListOutput.fromDynamic(response.data));
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

  @override
  Future<Either<Failure, Unit>> deleteShoppingList(String id) async {
    try {
      final response = await _httpClient.delete(AppPath.shoppingListById(id));
      final statusCode = response.statusCode ?? 0;

      if (_isSuccess(statusCode)) {
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

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;
}
