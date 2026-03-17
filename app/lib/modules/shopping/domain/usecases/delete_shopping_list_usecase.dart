import 'package:dartz/dartz.dart' show Unit;
import 'package:organiq/modules/shopping/domain/repositories/i_shopping_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/ib_usecase.dart';

class DeleteShoppingListUsecase extends IBUsecase {
  DeleteShoppingListUsecase(this._repository);

  final IShoppingRepository _repository;

  UsecaseResponse<Failure, Unit> call(String id) {
    return _repository.deleteShoppingList(id);
  }
}
