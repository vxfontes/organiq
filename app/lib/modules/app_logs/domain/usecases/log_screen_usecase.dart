import 'package:dartz/dartz.dart';
import 'package:organiq/modules/app_logs/data/models/screen_log_input.dart';
import 'package:organiq/modules/app_logs/domain/repositories/i_app_screen_log_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/oq_usecase.dart';

class LogScreenUsecase extends OQUsecase {
  LogScreenUsecase(this._repository);

  final IAppScreenLogRepository _repository;

  UsecaseResponse<Failure, Unit> call(ScreenLogInput input) {
    return _repository.create(input);
  }
}
