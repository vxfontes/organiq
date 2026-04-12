import 'package:dartz/dartz.dart';

import 'package:organiq/modules/home/data/models/home_dashboard_output.dart';
import 'package:organiq/modules/home/domain/repositories/i_home_repository.dart';
import 'package:organiq/shared/errors/api_error_mapper.dart';
import 'package:organiq/shared/errors/exception_mapper.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/extensions/response_model_extensions.dart';
import 'package:organiq/shared/services/cache/cache_service.dart';
import 'package:organiq/shared/services/connectivity/connectivity_service.dart';
import 'package:organiq/shared/services/http/app_path.dart';
import 'package:organiq/shared/services/http/http_client.dart';

const _cacheKeyDashboard = 'cache:${AppPath.homeDashboard}';
const _dashboardTtl = Duration(minutes: 2);

class HomeRepository implements IHomeRepository {
  HomeRepository(this._httpClient, this._cache, this._connectivity);

  final IHttpClient _httpClient;
  final ICacheService _cache;
  final IConnectivityService _connectivity;

  // -------------------------------------------------------------------------
  // fetchDashboard — estratégia cache-first com TTL de 2min
  //
  // Dashboard agrega dados dinâmicos de resumo; TTL curto garante que o
  // usuário raramente verá dados muito desatualizados.
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, HomeDashboardOutput>> fetchDashboard({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _cache.get(_cacheKeyDashboard);
      if (cached != null) {
        try {
          return Right(HomeDashboardOutput.fromJson(cached));
        } catch (_) {
          await _cache.invalidate(_cacheKeyDashboard);
        }
      }
    }

    final online = await _connectivity.isOnline();
    if (!online) {
      return Left(
        NetworkFailure(
          message:
              'Sem conexão. Conecte-se à internet para carregar o dashboard.',
        ),
      );
    }

    return _fetchDashboardFromApi();
  }

  Future<Either<Failure, HomeDashboardOutput>> _fetchDashboardFromApi() async {
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
        await _cache.set(_cacheKeyDashboard, map, ttl: _dashboardTtl);
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
