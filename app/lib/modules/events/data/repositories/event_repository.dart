import 'package:dartz/dartz.dart';

import 'package:organiq/modules/events/data/models/agenda_output.dart';
import 'package:organiq/modules/events/data/models/event_create_input.dart';
import 'package:organiq/modules/events/data/models/event_list_output.dart';
import 'package:organiq/modules/events/data/models/event_output.dart';
import 'package:organiq/modules/events/domain/repositories/i_event_repository.dart';
import 'package:organiq/shared/errors/api_error_mapper.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/services/http/app_path.dart';
import 'package:organiq/shared/services/http/http_client.dart';

class EventRepository implements IEventRepository {
  EventRepository(this._httpClient);

  final IHttpClient _httpClient;

  @override
  Future<Either<Failure, EventListOutput>> fetchEvents({
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

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        return Right(EventListOutput.fromDynamic(response.data));
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
      return Left(GetListFailure(message: err.toString()));
    }
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  @override
  Future<Either<Failure, EventOutput>> createEvent(
    EventCreateInput input,
  ) async {
    try {
      final response = await _httpClient.post(
        AppPath.events,
        data: input.toJson(),
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
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
      return Left(SaveFailure(message: err.toString()));
    }
  }

  @override
  Future<Either<Failure, AgendaOutput>> fetchAgenda({int? limit}) async {
    try {
      final query = <String, dynamic>{};
      if (limit != null) query['limit'] = limit;

      final response = await _httpClient.get(
        AppPath.agenda,
        queryParameters: query.isEmpty ? null : query,
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
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
      return Left(GetListFailure(message: err.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteEvent(String id) async {
    try {
      final response = await _httpClient.delete(AppPath.eventById(id));
      final statusCode = response.statusCode ?? 0;

      if (_isSuccess(statusCode)) {
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
      return Left(DeleteFailure(message: err.toString()));
    }
  }
}
