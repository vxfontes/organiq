import 'package:dartz/dartz.dart';

import 'package:inbota/modules/home/data/models/home_dashboard_output.dart';
import 'package:inbota/modules/home/domain/repositories/i_home_repository.dart';
import 'package:inbota/shared/errors/api_error_mapper.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/services/http/app_path.dart';
import 'package:inbota/shared/services/http/http_client.dart';

class HomeRepository implements IHomeRepository {
  HomeRepository(this._httpClient);

  final IHttpClient _httpClient;

  @override
  Future<Either<Failure, HomeDashboardOutput>> fetchDashboard() async {
    try {
      final response = await _httpClient.get(AppPath.homeDashboard);
      final statusCode = response.statusCode ?? 0;

      if (_isSuccess(statusCode)) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          return Right(HomeDashboardOutput.fromJson(data));
        }
        if (data is Map) {
          return Right(
            HomeDashboardOutput.fromJson(
              data.map((key, value) => MapEntry(key.toString(), value)),
            ),
          );
        }
        return Left(
          GetFailure(
            message: 'Resposta inválida ao carregar dashboard da Home.',
          ),
        );
      }

      return Left(
        GetFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao carregar dashboard da Home.',
          ),
        ),
      );
    } catch (err) {
      return Left(GetFailure(message: err.toString()));
    }
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;
}
