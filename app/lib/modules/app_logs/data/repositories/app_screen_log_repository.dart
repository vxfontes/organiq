import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:organiq/modules/app_logs/data/models/screen_log_input.dart';
import 'package:organiq/modules/app_logs/domain/repositories/i_app_screen_log_repository.dart';
import 'package:organiq/shared/errors/api_error_mapper.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/services/http/app_log_http_client.dart';
import 'package:organiq/shared/services/http/app_path.dart';

class AppScreenLogRepository implements IAppScreenLogRepository {
  AppScreenLogRepository(this._httpClient);

  final AppLogHttpClient _httpClient;

  @override
  Future<Either<Failure, Unit>> create(ScreenLogInput input) async {
    try {
      final response = await _httpClient.post(
        AppPath.appLogsScreens,
        data: input.toJson(),
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        return const Right(unit);
      }

      return Left(
        SaveFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao registrar log de tela.',
          ),
        ),
      );
    } on DioException catch (err) {
      return Left(
        SaveFailure(
          message: ApiErrorMapper.fromResponseData(
            err.response?.data,
            fallbackMessage: err.message ?? 'Erro ao registrar log de tela.',
          ),
        ),
      );
    } catch (err) {
      return Left(SaveFailure(message: err.toString()));
    }
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;
}
