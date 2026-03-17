import 'package:flutter_modular/flutter_modular.dart';
import 'package:organiq/modules/flags/data/repositories/flag_repository.dart';
import 'package:organiq/modules/flags/domain/repositories/i_flag_repository.dart';
import 'package:organiq/modules/flags/domain/usecases/create_flag_usecase.dart';
import 'package:organiq/modules/flags/domain/usecases/create_subflag_usecase.dart';
import 'package:organiq/modules/flags/domain/usecases/delete_flag_usecase.dart';
import 'package:organiq/modules/flags/domain/usecases/delete_subflag_usecase.dart';
import 'package:organiq/modules/flags/domain/usecases/get_flags_usecase.dart';
import 'package:organiq/modules/flags/domain/usecases/get_subflags_by_flag_usecase.dart';
import 'package:organiq/modules/flags/domain/usecases/update_flag_usecase.dart';
import 'package:organiq/modules/flags/domain/usecases/update_subflag_usecase.dart';

class FlagsModule {
  static void binds(Injector i) {
    // repository
    i.addLazySingleton<IFlagRepository>(FlagRepository.new);

    // usecases
    i.addLazySingleton<GetFlagsUsecase>(GetFlagsUsecase.new);
    i.addLazySingleton<CreateFlagUsecase>(CreateFlagUsecase.new);
    i.addLazySingleton<UpdateFlagUsecase>(UpdateFlagUsecase.new);
    i.addLazySingleton<DeleteFlagUsecase>(DeleteFlagUsecase.new);
    i.addLazySingleton<GetSubflagsByFlagUsecase>(GetSubflagsByFlagUsecase.new);
    i.addLazySingleton<CreateSubflagUsecase>(CreateSubflagUsecase.new);
    i.addLazySingleton<UpdateSubflagUsecase>(UpdateSubflagUsecase.new);
    i.addLazySingleton<DeleteSubflagUsecase>(DeleteSubflagUsecase.new);
  }
}
