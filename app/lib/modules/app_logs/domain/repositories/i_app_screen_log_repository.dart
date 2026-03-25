import 'package:dartz/dartz.dart';
import 'package:organiq/modules/app_logs/data/models/screen_log_input.dart';
import 'package:organiq/shared/errors/failures.dart';

abstract class IAppScreenLogRepository {
  Future<Either<Failure, Unit>> create(ScreenLogInput input);
}
