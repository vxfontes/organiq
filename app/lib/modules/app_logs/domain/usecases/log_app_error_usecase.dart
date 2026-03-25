import 'package:dartz/dartz.dart';
import 'package:organiq/modules/app_logs/data/models/app_error_log_input.dart';
import 'package:organiq/modules/app_logs/domain/repositories/i_app_error_log_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/oq_usecase.dart';

class LogAppErrorUsecase extends OQUsecase {
  LogAppErrorUsecase(this._repository);

  final IAppErrorLogRepository _repository;

  UsecaseResponse<Failure, Unit> call(AppErrorLogInput input) {
    return _repository.create(input);
  }
}
