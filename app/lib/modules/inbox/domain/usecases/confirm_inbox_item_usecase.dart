import 'package:organiq/modules/inbox/data/models/inbox_confirm_input.dart';
import 'package:organiq/modules/inbox/data/models/inbox_confirm_output.dart';
import 'package:organiq/modules/inbox/domain/repositories/i_inbox_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/ib_usecase.dart';

class ConfirmInboxItemUsecase extends IBUsecase {
  ConfirmInboxItemUsecase(this._repository);

  final IInboxRepository _repository;

  UsecaseResponse<Failure, InboxConfirmOutput> call(InboxConfirmInput input) {
    return _repository.confirmInboxItem(input);
  }
}
