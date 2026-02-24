import 'package:dartz/dartz.dart';
import 'package:inbota/modules/inbox/data/models/inbox_confirm_input.dart';
import 'package:inbota/modules/inbox/data/models/inbox_confirm_output.dart';
import 'package:inbota/modules/inbox/data/models/inbox_create_input.dart';
import 'package:inbota/modules/inbox/data/models/inbox_item_output.dart';
import 'package:inbota/modules/inbox/domain/repositories/i_inbox_repository.dart';
import 'package:inbota/shared/errors/api_error_mapper.dart';
import 'package:inbota/shared/errors/failures.dart';
import 'package:inbota/shared/services/http/app_path.dart';
import 'package:inbota/shared/services/http/http_client.dart';

class InboxRepository implements IInboxRepository {
  InboxRepository(this._httpClient);

  final IHttpClient _httpClient;

  @override
  Future<Either<Failure, InboxItemOutput>> createInboxItem(
    InboxCreateInput input,
  ) async {
    try {
      final response = await _httpClient.post(
        AppPath.inboxItems,
        data: input.toJson(),
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        return Right(InboxItemOutput.fromDynamic(response.data));
      }

      return Left(
        SaveFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao criar item no inbox.',
          ),
        ),
      );
    } catch (err) {
      return Left(SaveFailure(message: err.toString()));
    }
  }

  @override
  Future<Either<Failure, InboxItemOutput>> reprocessInboxItem(String id) async {
    try {
      final response = await _httpClient.post(AppPath.inboxReprocess(id));

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        return Right(InboxItemOutput.fromDynamic(response.data));
      }

      return Left(
        UpdateFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao processar texto com IA.',
          ),
        ),
      );
    } catch (err) {
      return Left(UpdateFailure(message: err.toString()));
    }
  }

  @override
  Future<Either<Failure, InboxConfirmOutput>> confirmInboxItem(
    InboxConfirmInput input,
  ) async {
    try {
      final response = await _httpClient.post(
        AppPath.inboxConfirm(input.id),
        data: input.toJson(),
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        return Right(InboxConfirmOutput.fromDynamic(response.data));
      }

      return Left(
        SaveFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao confirmar sugestão da IA.',
          ),
        ),
      );
    } catch (err) {
      return Left(SaveFailure(message: err.toString()));
    }
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;
}
