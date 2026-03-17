import 'package:organiq/modules/reminders/data/models/reminder_output.dart';
import 'package:organiq/modules/reminders/data/models/reminder_update_input.dart';
import 'package:organiq/modules/reminders/domain/repositories/i_reminder_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/ib_usecase.dart';

class UpdateReminderUsecase extends IBUsecase {
  final IReminderRepository _repository;

  UpdateReminderUsecase(this._repository);

  UsecaseResponse<Failure, ReminderOutput> call(ReminderUpdateInput input) {
    return _repository.updateReminder(input);
  }
}
