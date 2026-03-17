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
import 'package:organiq/shared/services/http/app_path.dart';
import 'package:organiq/shared/services/http/http_client.dart';

class FlagRepository implements IFlagRepository {
  FlagRepository(this._httpClient);

  final IHttpClient _httpClient;

  @override
  Future<Either<Failure, FlagListOutput>> fetchFlags({
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
        return Right(FlagListOutput.fromDynamic(response.data));
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

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  @override
  Future<Either<Failure, FlagOutput>> createFlag(FlagCreateInput input) async {
    try {
      final response = await _httpClient.post(
        AppPath.flags,
        data: input.toJson(),
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
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

  @override
  Future<Either<Failure, FlagOutput>> updateFlag(FlagUpdateInput input) async {
    try {
      final response = await _httpClient.patch(
        AppPath.flagById(input.id),
        data: input.toJson(),
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
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

  @override
  Future<Either<Failure, Unit>> deleteFlag(String id) async {
    try {
      final response = await _httpClient.delete(AppPath.flagById(id));

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
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

  @override
  Future<Either<Failure, SubflagListOutput>> fetchSubflagsByFlag({
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
        return Right(SubflagListOutput.fromDynamic(response.data));
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
