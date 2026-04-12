import 'package:dartz/dartz.dart';

import 'package:organiq/modules/flags/data/models/flag_create_input.dart';
import 'package:organiq/modules/flags/data/models/flag_list_output.dart';
import 'package:organiq/modules/flags/data/models/flag_output.dart';
import 'package:organiq/modules/flags/data/models/flag_update_input.dart';
import 'package:organiq/modules/flags/data/models/subflag_create_input.dart';
import 'package:organiq/modules/flags/data/models/subflag_list_output.dart';
import 'package:organiq/modules/flags/data/models/subflag_output.dart';
import 'package:organiq/modules/flags/data/models/subflag_update_input.dart';
import 'package:organiq/modules/flags/domain/repositories/i_flag_repository.dart';
import 'package:organiq/shared/errors/api_error_mapper.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/services/cache/cache_service.dart';
import 'package:organiq/shared/services/connectivity/connectivity_service.dart';
import 'package:organiq/shared/services/http/app_path.dart';
import 'package:organiq/shared/services/http/http_client.dart';

const _cacheKeyFlags = 'cache:${AppPath.flags}';
const _flagsTtl = Duration(minutes: 15);

String _cacheKeySubflags(String flagId) =>
    'cache:${AppPath.flags}/$flagId/subflags';

class FlagRepository implements IFlagRepository {
  FlagRepository(this._httpClient, this._cache, this._connectivity);

  final IHttpClient _httpClient;
  final ICacheService _cache;
  final IConnectivityService _connectivity;

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  // -------------------------------------------------------------------------
  // fetchFlags — estratégia cache-first com TTL de 15min
  //
  // Flags mudam raramente; TTL longo reduz tráfego de rede sem impactar UX.
  // 1. Tem cursor (paginação): vai direto à API.
  // 2. Sem cursor e cache válido: retorna cache.
  // 3. Sem cursor, cache ausente/expirado, offline: retorna NetworkFailure.
  // 4. Sem cursor, cache ausente/expirado, online: busca API, atualiza cache.
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, FlagListOutput>> fetchFlags({
    int? limit,
    String? cursor,
  }) async {
    if (cursor != null) {
      return _fetchFlagsFromApi(limit: limit, cursor: cursor);
    }

    final cached = await _cache.get(_cacheKeyFlags);
    if (cached != null) {
      try {
        return Right(FlagListOutput.fromDynamic(cached));
      } catch (_) {
        await _cache.invalidate(_cacheKeyFlags);
      }
    }

    final online = await _connectivity.isOnline();
    if (!online) {
      return Left(
        NetworkFailure(
          message: 'Sem conexão. Conecte-se à internet para carregar suas flags.',
        ),
      );
    }

    return _fetchFlagsFromApi(limit: limit);
  }

  Future<Either<Failure, FlagListOutput>> _fetchFlagsFromApi({
    int? limit,
    String? cursor,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (limit != null) query['limit'] = limit;
      if (cursor != null) query['cursor'] = cursor;

      final response = await _httpClient.get(
        AppPath.flags,
        queryParameters: query.isEmpty ? null : query,
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        final output = FlagListOutput.fromDynamic(response.data);
        if (cursor == null) {
          final data = response.data;
          if (data is Map<String, dynamic>) {
            await _cache.set(_cacheKeyFlags, data, ttl: _flagsTtl);
          }
        }
        return Right(output);
      }

      return Left(
        GetListFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao carregar flags.',
          ),
        ),
      );
    } catch (err) {
      return Left(GetListFailure(message: err.toString()));
    }
  }

  // -------------------------------------------------------------------------
  // createFlag — invalida cache de flags após sucesso
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, FlagOutput>> createFlag(FlagCreateInput input) async {
    try {
      final response = await _httpClient.post(
        AppPath.flags,
        data: input.toJson(),
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        await _cache.invalidate(_cacheKeyFlags);
        return Right(FlagOutput.fromDynamic(response.data));
      }

      return Left(
        SaveFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao criar flag.',
          ),
        ),
      );
    } catch (err) {
      return Left(SaveFailure(message: err.toString()));
    }
  }

  // -------------------------------------------------------------------------
  // updateFlag — invalida cache de flags após sucesso
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, FlagOutput>> updateFlag(FlagUpdateInput input) async {
    try {
      final response = await _httpClient.patch(
        AppPath.flagById(input.id),
        data: input.toJson(),
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        await _cache.invalidate(_cacheKeyFlags);
        return Right(FlagOutput.fromDynamic(response.data));
      }

      return Left(
        UpdateFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao atualizar flag.',
          ),
        ),
      );
    } catch (err) {
      return Left(UpdateFailure(message: err.toString()));
    }
  }

  // -------------------------------------------------------------------------
  // deleteFlag — invalida cache de flags após sucesso
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, Unit>> deleteFlag(String id) async {
    try {
      final response = await _httpClient.delete(AppPath.flagById(id));

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        await _cache.invalidate(_cacheKeyFlags);
        return const Right(unit);
      }

      return Left(
        DeleteFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao excluir flag.',
          ),
        ),
      );
    } catch (err) {
      return Left(DeleteFailure(message: err.toString()));
    }
  }

  // -------------------------------------------------------------------------
  // fetchSubflagsByFlag — estratégia cache-first com TTL de 15min
  //
  // Chave inclui flagId para evitar colisões entre flags distintas.
  // 1. Tem cursor (paginação): vai direto à API.
  // 2. Sem cursor e cache válido: retorna cache.
  // 3. Sem cursor, cache ausente/expirado, offline: retorna NetworkFailure.
  // 4. Sem cursor, cache ausente/expirado, online: busca API, atualiza cache.
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, SubflagListOutput>> fetchSubflagsByFlag({
    required String flagId,
    int? limit,
    String? cursor,
  }) async {
    final cacheKey = _cacheKeySubflags(flagId);

    if (cursor != null) {
      return _fetchSubflagsFromApi(
        flagId: flagId,
        limit: limit,
        cursor: cursor,
      );
    }

    final cached = await _cache.get(cacheKey);
    if (cached != null) {
      try {
        return Right(SubflagListOutput.fromDynamic(cached));
      } catch (_) {
        await _cache.invalidate(cacheKey);
      }
    }

    final online = await _connectivity.isOnline();
    if (!online) {
      return Left(
        NetworkFailure(
          message:
              'Sem conexão. Conecte-se à internet para carregar as subflags.',
        ),
      );
    }

    return _fetchSubflagsFromApi(flagId: flagId, limit: limit);
  }

  Future<Either<Failure, SubflagListOutput>> _fetchSubflagsFromApi({
    required String flagId,
    int? limit,
    String? cursor,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (limit != null) query['limit'] = limit;
      if (cursor != null) query['cursor'] = cursor;

      final response = await _httpClient.get(
        AppPath.flagSubflags(flagId),
        queryParameters: query.isEmpty ? null : query,
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        final output = SubflagListOutput.fromDynamic(response.data);
        if (cursor == null) {
          final data = response.data;
          if (data is Map<String, dynamic>) {
            await _cache.set(
              _cacheKeySubflags(flagId),
              data,
              ttl: _flagsTtl,
            );
          }
        }
        return Right(output);
      }

      return Left(
        GetListFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao carregar subflags.',
          ),
        ),
      );
    } catch (err) {
      return Left(GetListFailure(message: err.toString()));
    }
  }

  // -------------------------------------------------------------------------
  // createSubflag — invalida cache de subflags da flag após sucesso
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, SubflagOutput>> createSubflag(
    SubflagCreateInput input,
  ) async {
    try {
      final response = await _httpClient.post(
        AppPath.flagSubflags(input.flagId),
        data: input.toJson(),
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        await _cache.invalidate(_cacheKeySubflags(input.flagId));
        return Right(SubflagOutput.fromDynamic(response.data));
      }

      return Left(
        SaveFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao criar subflag.',
          ),
        ),
      );
    } catch (err) {
      return Left(SaveFailure(message: err.toString()));
    }
  }

  // -------------------------------------------------------------------------
  // updateSubflag — invalida cache da flag pai após sucesso
  //
  // SubflagUpdateInput não carrega flagId; a invalidação de cache de subflags
  // por flag não é possível aqui sem alterar a interface. O TTL de 15min
  // trata a consistência eventual neste caso específico.
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, SubflagOutput>> updateSubflag(
    SubflagUpdateInput input,
  ) async {
    try {
      final response = await _httpClient.patch(
        AppPath.subflagById(input.id),
        data: input.toJson(),
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        return Right(SubflagOutput.fromDynamic(response.data));
      }

      return Left(
        UpdateFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao atualizar subflag.',
          ),
        ),
      );
    } catch (err) {
      return Left(UpdateFailure(message: err.toString()));
    }
  }

  // -------------------------------------------------------------------------
  // deleteSubflag — sem invalidação por flagId (id do item, não da flag)
  //
  // Mesma razão de updateSubflag: o parâmetro é o id da subflag, não o flagId.
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, Unit>> deleteSubflag(String id) async {
    try {
      final response = await _httpClient.delete(AppPath.subflagById(id));

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        return const Right(unit);
      }

      return Left(
        DeleteFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao excluir subflag.',
          ),
        ),
      );
    } catch (err) {
      return Left(DeleteFailure(message: err.toString()));
    }
  }
}
