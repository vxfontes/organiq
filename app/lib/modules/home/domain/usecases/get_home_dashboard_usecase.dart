import 'package:organiq/modules/home/data/models/home_dashboard_output.dart';
import 'package:organiq/modules/home/domain/repositories/i_home_repository.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/templates/oq_usecase.dart';

class GetHomeDashboardUsecase extends OQUsecase {
  GetHomeDashboardUsecase(this._repository);

  final IHomeRepository _repository;

  UsecaseResponse<Failure, HomeDashboardOutput> call() {
    return _repository.fetchDashboard();
  }
}
