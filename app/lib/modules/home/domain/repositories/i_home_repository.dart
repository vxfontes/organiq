import 'package:dartz/dartz.dart';
import 'package:organiq/modules/home/data/models/home_dashboard_output.dart';
import 'package:organiq/shared/errors/failures.dart';

abstract class IHomeRepository {
  Future<Either<Failure, HomeDashboardOutput>> fetchDashboard();
}
