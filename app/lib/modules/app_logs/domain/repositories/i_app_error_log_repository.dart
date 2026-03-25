import 'package:dartz/dartz.dart';
import 'package:organiq/modules/app_logs/data/models/app_error_log_input.dart';
import 'package:organiq/shared/errors/failures.dart';

abstract class IAppErrorLogRepository {
  Future<Either<Failure, Unit>> create(AppErrorLogInput input);
}
