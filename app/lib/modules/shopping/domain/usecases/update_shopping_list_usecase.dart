import 'package:organiq/modules/shopping/data/models/shopping_list_output.dart';
import 'package:organiq/modules/shopping/data/models/shopping_list_update_input.dart';
import 'package:organiq/modules/shopping/domain/repositories/i_shopping_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/ib_usecase.dart';

class UpdateShoppingListUsecase extends IBUsecase {
  UpdateShoppingListUsecase(this._repository);

  final IShoppingRepository _repository;

  UsecaseResponse<Failure, ShoppingListOutput> call(
    ShoppingListUpdateInput input,
  ) {
    return _repository.updateShoppingList(input);
  }
}
