import 'package:dartz/dartz.dart';

import 'package:organiq/modules/home/data/models/home_dashboard_output.dart';
import 'package:organiq/modules/home/domain/repositories/i_home_repository.dart';
import 'package:organiq/shared/errors/api_error_mapper.dart';
import 'package:organiq/shared/errors/exception_mapper.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/extensions/response_model_extensions.dart';
import 'package:organiq/shared/services/http/app_path.dart';
import 'package:organiq/shared/services/http/http_client.dart';

class HomeRepository implements IHomeRepository {
  HomeRepository(this._httpClient);

  final IHttpClient _httpClient;

  @override
  Future<Either<Failure, HomeDashboardOutput>> fetchDashboard() async {
    try {
      final response = await _httpClient.get(AppPath.homeDashboard);

      if (response.isSuccess) {
        final map = response.asMap();
        if (map.isEmpty && response.data != null) {
          return Left(
            GetFailure(
              message: 'Resposta inválida ao carregar dashboard da Home.',
            ),
          );
        }
        return Right(HomeDashboardOutput.fromJson(map));
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
      return Left(
        ExceptionMapper.toFailure(
          err,
          fallbackMessage: 'Erro ao carregar dashboard da Home.',
          failureFactory: (msg) => GetFailure(message: msg),
        ),
      );
    }
  }
}
