import 'package:dartz/dartz.dart' show Unit;
import 'package:organiq/modules/reminders/domain/repositories/i_reminder_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/ib_usecase.dart';

class DeleteReminderUsecase extends IBUsecase {
  DeleteReminderUsecase(this._repository);

  final IReminderRepository _repository;

  UsecaseResponse<Failure, Unit> call(String id) {
    return _repository.deleteReminder(id);
  }
}
