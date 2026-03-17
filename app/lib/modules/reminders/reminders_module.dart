import 'package:flutter_modular/flutter_modular.dart';
import 'package:organiq/modules/reminders/data/repositories/reminder_repository.dart';
import 'package:organiq/modules/reminders/domain/repositories/i_reminder_repository.dart';
import 'package:organiq/modules/reminders/domain/usecases/create_reminder_usecase.dart';
import 'package:organiq/modules/reminders/domain/usecases/delete_reminder_usecase.dart';
import 'package:organiq/modules/reminders/domain/usecases/get_reminders_usecase.dart';
import 'package:organiq/modules/reminders/domain/usecases/update_reminder_usecase.dart';

class RemindersModule {
  static void binds(Injector i) {
    // repository
    i.addLazySingleton<IReminderRepository>(ReminderRepository.new);

    // usecases
    i.addLazySingleton<CreateReminderUsecase>(CreateReminderUsecase.new);
    i.addLazySingleton<DeleteReminderUsecase>(DeleteReminderUsecase.new);
    i.addLazySingleton<GetRemindersUsecase>(GetRemindersUsecase.new);
    i.addLazySingleton<UpdateReminderUsecase>(UpdateReminderUsecase.new);
  }
}
