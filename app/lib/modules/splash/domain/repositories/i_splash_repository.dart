import 'package:dartz/dartz.dart';
import 'package:organiq/modules/splash/data/models/health_status_output.dart';
import 'package:organiq/shared/errors/failures.dart';

abstract class ISplashRepository {
  Future<Either<Failure, HealthStatusOutput>> checkHealth();
}
