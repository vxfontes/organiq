import 'package:organiq/modules/shopping/data/models/shopping_list_create_input.dart';
import 'package:organiq/modules/shopping/data/models/shopping_list_output.dart';
import 'package:organiq/modules/shopping/domain/repositories/i_shopping_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/ib_usecase.dart';

class CreateShoppingListUsecase extends IBUsecase {
  CreateShoppingListUsecase(this._repository);

  final IShoppingRepository _repository;

  UsecaseResponse<Failure, ShoppingListOutput> call(
    ShoppingListCreateInput input,
  ) {
    return _repository.createShoppingList(input);
  }
}
