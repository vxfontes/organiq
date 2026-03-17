import 'package:organiq/modules/reminders/data/models/reminder_list_output.dart';
import 'package:organiq/modules/reminders/domain/repositories/i_reminder_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/oq_usecase.dart';

class GetRemindersUsecase extends OQUsecase {
  final IReminderRepository _repository;

  GetRemindersUsecase(this._repository);

  UsecaseResponse<Failure, ReminderListOutput> call({
    int? limit,
    String? cursor,
  }) {
    return _repository.fetchReminders(limit: limit, cursor: cursor);
  }
}
