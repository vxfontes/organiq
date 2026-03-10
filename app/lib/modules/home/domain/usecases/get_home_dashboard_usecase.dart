import 'package:inbota/modules/home/data/models/home_dashboard_output.dart';
import 'package:inbota/modules/home/domain/repositories/i_home_repository.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/templates/ib_usecase.dart';

class GetHomeDashboardUsecase extends IBUsecase {
  GetHomeDashboardUsecase(this._repository);

  final IHomeRepository _repository;

  UsecaseResponse<Failure, HomeDashboardOutput> call() {
    return _repository.fetchDashboard();
  }
}
