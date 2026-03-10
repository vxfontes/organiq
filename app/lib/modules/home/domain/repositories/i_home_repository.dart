import 'package:dartz/dartz.dart';
import 'package:inbota/modules/home/data/models/home_dashboard_output.dart';
import 'package:inbota/shared/errors/failures.dart';

abstract class IHomeRepository {
  Future<Either<Failure, HomeDashboardOutput>> fetchDashboard();
}
