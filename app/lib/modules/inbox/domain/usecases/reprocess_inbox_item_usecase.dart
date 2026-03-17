import 'package:organiq/modules/inbox/data/models/inbox_item_output.dart';
import 'package:organiq/modules/inbox/domain/repositories/i_inbox_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/ib_usecase.dart';

class ReprocessInboxItemUsecase extends IBUsecase {
  ReprocessInboxItemUsecase(this._repository);

  final IInboxRepository _repository;

  UsecaseResponse<Failure, InboxItemOutput> call(String id) {
    return _repository.reprocessInboxItem(id);
  }
}
