import 'package:organiq/modules/shopping/data/models/shopping_item_create_input.dart';
import 'package:organiq/modules/shopping/data/models/shopping_item_output.dart';
import 'package:organiq/modules/shopping/domain/repositories/i_shopping_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/oq_usecase.dart';

class CreateShoppingItemUsecase extends OQUsecase {
  CreateShoppingItemUsecase(this._repository);

  final IShoppingRepository _repository;

  UsecaseResponse<Failure, ShoppingItemOutput> call(
    ShoppingItemCreateInput input,
  ) {
    return _repository.createShoppingItem(input);
  }
}
