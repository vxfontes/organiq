import 'package:dartz/dartz.dart';

import 'package:organiq/modules/events/data/models/agenda_output.dart';
import 'package:organiq/modules/events/data/models/event_create_input.dart';
import 'package:organiq/modules/events/data/models/event_list_output.dart';
import 'package:organiq/modules/events/data/models/event_output.dart';
import 'package:organiq/modules/events/domain/repositories/i_event_repository.dart';
import 'package:organiq/shared/errors/api_error_mapper.dart';
import 'package:organiq/shared/errors/exception_mapper.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/extensions/response_model_extensions.dart';
import 'package:organiq/shared/services/cache/cache_service.dart';
import 'package:organiq/shared/services/connectivity/connectivity_service.dart';
import 'package:organiq/shared/services/http/app_path.dart';
import 'package:organiq/shared/services/http/http_client.dart';

const _cacheKeyEvents = 'cache:${AppPath.events}';
const _cacheKeyAgenda = 'cache:${AppPath.agenda}';

class EventRepository implements IEventRepository {
  EventRepository(this._httpClient, this._cache, this._connectivity);

  final IHttpClient _httpClient;
  final ICacheService _cache;
  final IConnectivityService _connectivity;

  // -------------------------------------------------------------------------
  // fetchEvents — estratégia cache-first
  //
  // 1. Tem cursor (paginação): vai direto à API.
  // 2. Sem cursor e cache válido: retorna cache.
  // 3. Sem cursor, cache ausente/expirado, offline: retorna NetworkFailure.
  // 4. Sem cursor, cache ausente/expirado, online: busca API, atualiza cache.
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, EventListOutput>> fetchEvents({
    int? limit,
    String? cursor,
  }) async {
    if (cursor != null) {
      return _fetchEventsFromApi(limit: limit, cursor: cursor);
    }

    final cached = await _cache.get(_cacheKeyEvents);
    if (cached != null) {
      try {
        return Right(EventListOutput.fromDynamic(cached));
      } catch (_) {
        await _cache.invalidate(_cacheKeyEvents);
      }
    }

    final online = await _connectivity.isOnline();
    if (!online) {
      return Left(
        NetworkFailure(
          message:
              'Sem conexão. Conecte-se à internet para carregar seus eventos.',
        ),
      );
    }

    return _fetchEventsFromApi(limit: limit);
  }

  Future<Either<Failure, EventListOutput>> _fetchEventsFromApi({
    int? limit,
    String? cursor,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (limit != null) query['limit'] = limit;
      if (cursor != null) query['cursor'] = cursor;

      final response = await _httpClient.get(
        AppPath.events,
        queryParameters: query.isEmpty ? null : query,
      );

      if (response.isSuccess) {
        final output = EventListOutput.fromDynamic(response.data);
        if (cursor == null) {
          await _cache.set(_cacheKeyEvents, response.asMap());
        }
        return Right(output);
      }

      return Left(
        GetListFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao carregar eventos.',
          ),
        ),
      );
    } catch (err) {
      return Left(
        ExceptionMapper.toFailure(
          err,
          fallbackMessage: 'Erro ao carregar eventos.',
          failureFactory: (msg) => GetListFailure(message: msg),
        ),
      );
    }
  }

  // -------------------------------------------------------------------------
  // fetchAgenda — estratégia cache-first (sem paginação por cursor)
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, AgendaOutput>> fetchAgenda({int? limit}) async {
    final cached = await _cache.get(_cacheKeyAgenda);
    if (cached != null) {
      try {
        return Right(AgendaOutput.fromDynamic(cached));
      } catch (_) {
        await _cache.invalidate(_cacheKeyAgenda);
      }
    }

    final online = await _connectivity.isOnline();
    if (!online) {
      return Left(
        NetworkFailure(
          message:
              'Sem conexão. Conecte-se à internet para carregar sua agenda.',
        ),
      );
    }

    return _fetchAgendaFromApi(limit: limit);
  }

  Future<Either<Failure, AgendaOutput>> _fetchAgendaFromApi({
    int? limit,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (limit != null) query['limit'] = limit;

      final response = await _httpClient.get(
        AppPath.agenda,
        queryParameters: query.isEmpty ? null : query,
      );

      if (response.isSuccess) {
        await _cache.set(_cacheKeyAgenda, response.asMap());
        return Right(AgendaOutput.fromDynamic(response.data));
      }

      return Left(
        GetListFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao carregar agenda.',
          ),
        ),
      );
    } catch (err) {
      return Left(
        ExceptionMapper.toFailure(
          err,
          fallbackMessage: 'Erro ao carregar agenda.',
          failureFactory: (msg) => GetListFailure(message: msg),
        ),
      );
    }
  }

  // -------------------------------------------------------------------------
  // createEvent — invalida cache de events e agenda após sucesso
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, EventOutput>> createEvent(
    EventCreateInput input,
  ) async {
    try {
      final response = await _httpClient.post(
        AppPath.events,
        data: input.toJson(),
      );

      if (response.isSuccess) {
        await _cache.invalidate(_cacheKeyEvents);
        await _cache.invalidate(_cacheKeyAgenda);
        return Right(EventOutput.fromDynamic(response.data));
      }

      return Left(
        SaveFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao criar evento.',
          ),
        ),
      );
    } catch (err) {
      return Left(
        ExceptionMapper.toFailure(
          err,
          fallbackMessage: 'Erro ao criar evento.',
          failureFactory: (msg) => SaveFailure(message: msg),
        ),
      );
    }
  }

  // -------------------------------------------------------------------------
  // deleteEvent — invalida cache de events e agenda após sucesso
  // -------------------------------------------------------------------------
  @override
  Future<Either<Failure, Unit>> deleteEvent(String id) async {
    try {
      final response = await _httpClient.delete(AppPath.eventById(id));

      if (response.isSuccess) {
        await _cache.invalidate(_cacheKeyEvents);
        await _cache.invalidate(_cacheKeyAgenda);
        return const Right(unit);
      }

      return Left(
        DeleteFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao excluir evento.',
          ),
        ),
      );
    } catch (err) {
      return Left(
        ExceptionMapper.toFailure(
          err,
          fallbackMessage: 'Erro ao excluir evento.',
          failureFactory: (msg) => DeleteFailure(message: msg),
        ),
      );
    }
  }
}
