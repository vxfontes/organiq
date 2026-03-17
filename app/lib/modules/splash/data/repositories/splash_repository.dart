import 'package:dartz/dartz.dart';
import 'package:organiq/modules/splash/data/models/health_status_output.dart';
import 'package:organiq/modules/splash/domain/repositories/i_splash_repository.dart';
import 'package:organiq/shared/errors/api_error_mapper.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/services/http/app_path.dart';
import 'package:organiq/shared/services/http/http_client.dart';

class SplashRepository implements ISplashRepository {
  SplashRepository(this._httpClient);

  final IHttpClient _httpClient;

  @override
  Future<Either<Failure, HealthStatusOutput>> checkHealth() async {
    try {
      final response = await _httpClient.get(
        AppPath.healthz,
        extra: const {'auth': false},
      );
      final statusCode = response.statusCode ?? 0;

      if (_isSuccess(statusCode)) {
        return Right(HealthStatusOutput.fromJson(_asMap(response.data)));
      }

      return Left(
        GetFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Servidor indisponivel.',
            codeOverrides: const {
              'connection_refused':
                  'Servidor indisponivel. Verifique a rede local.',
            },
          ),
        ),
      );
    } catch (err) {
      return Left(GetFailure(message: err.toString()));
    }
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
