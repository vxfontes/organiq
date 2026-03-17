import 'package:organiq/modules/splash/data/models/health_status_output.dart';
import 'package:organiq/modules/splash/domain/repositories/i_splash_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/oq_usecase.dart';

class CheckHealthUsecase extends OQUsecase {
  final ISplashRepository _repository;

  CheckHealthUsecase(this._repository);

  UsecaseResponse<Failure, HealthStatusOutput> call() {
    return _repository.checkHealth();
  }
}
