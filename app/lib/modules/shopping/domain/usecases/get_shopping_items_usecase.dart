import 'package:organiq/modules/shopping/data/models/shopping_item_list_output.dart';
import 'package:organiq/modules/shopping/domain/repositories/i_shopping_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/oq_usecase.dart';

class GetShoppingItemsUsecase extends OQUsecase {
  GetShoppingItemsUsecase(this._repository);

  final IShoppingRepository _repository;

  UsecaseResponse<Failure, ShoppingItemListOutput> call({
    required String listId,
    int? limit,
    String? cursor,
  }) {
    return _repository.fetchShoppingItems(
      listId: listId,
      limit: limit,
      cursor: cursor,
    );
  }
}
