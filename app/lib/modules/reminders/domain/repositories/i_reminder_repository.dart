import 'package:dartz/dartz.dart';

import 'package:organiq/modules/reminders/data/models/reminder_list_output.dart';
import 'package:organiq/modules/reminders/data/models/reminder_output.dart';
import 'package:organiq/modules/reminders/data/models/reminder_create_input.dart';
import 'package:organiq/modules/reminders/data/models/reminder_update_input.dart';
import 'package:organiq/shared/errors/failures.dart';

abstract class IReminderRepository {
  Future<Either<Failure, ReminderListOutput>> fetchReminders({
    int? limit,
    String? cursor,
  });
  Future<Either<Failure, ReminderOutput>> createReminder(
    ReminderCreateInput input,
  );
  Future<Either<Failure, ReminderOutput>> updateReminder(
    ReminderUpdateInput input,
  );
  Future<Either<Failure, Unit>> deleteReminder(String id);
}
