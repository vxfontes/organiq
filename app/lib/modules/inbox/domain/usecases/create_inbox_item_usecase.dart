import 'package:organiq/modules/inbox/data/models/inbox_create_input.dart';
import 'package:organiq/modules/inbox/data/models/inbox_item_output.dart';
import 'package:organiq/modules/inbox/domain/repositories/i_inbox_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/oq_usecase.dart';

class CreateInboxItemUsecase extends OQUsecase {
  CreateInboxItemUsecase(this._repository);

  final IInboxRepository _repository;

  UsecaseResponse<Failure, InboxItemOutput> call(InboxCreateInput input) {
    return _repository.createInboxItem(input);
  }
}
