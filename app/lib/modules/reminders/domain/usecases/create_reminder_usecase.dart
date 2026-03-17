import 'package:organiq/modules/reminders/data/models/reminder_create_input.dart';
import 'package:organiq/modules/reminders/data/models/reminder_output.dart';
import 'package:organiq/modules/reminders/domain/repositories/i_reminder_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/ib_usecase.dart';

class CreateReminderUsecase extends IBUsecase {
  CreateReminderUsecase(this._repository);

  final IReminderRepository _repository;

  UsecaseResponse<Failure, ReminderOutput> call(ReminderCreateInput input) {
    return _repository.createReminder(input);
  }
}
