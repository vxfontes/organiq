import 'package:organiq/modules/shopping/data/models/shopping_list_list_output.dart';
import 'package:organiq/modules/shopping/domain/repositories/i_shopping_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/ib_usecase.dart';

class GetShoppingListsUsecase extends IBUsecase {
  GetShoppingListsUsecase(this._repository);

  final IShoppingRepository _repository;

  UsecaseResponse<Failure, ShoppingListListOutput> call({
    int? limit,
    String? cursor,
  }) {
    return _repository.fetchShoppingLists(limit: limit, cursor: cursor);
  }
}
