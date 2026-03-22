import 'package:dartz/dartz.dart';
import 'package:organiq/modules/suggestions/data/models/accept_block_input.dart';
import 'package:organiq/modules/suggestions/data/models/accept_block_output.dart';
import 'package:organiq/modules/suggestions/data/models/suggestion_conversation_output.dart';
import 'package:organiq/modules/suggestions/data/models/suggestion_message_input.dart';
import 'package:organiq/modules/suggestions/data/models/suggestion_message_output.dart';
import 'package:organiq/modules/suggestions/domain/repositories/i_suggestion_repository.dart';
import 'package:organiq/shared/errors/api_error_mapper.dart';
import 'package:organiq/shared/errors/failures.dart';
import 'package:organiq/shared/services/http/app_path.dart';
import 'package:organiq/shared/services/http/http_client.dart';

class SuggestionRepository implements ISuggestionRepository {
  SuggestionRepository(this._httpClient);

  final IHttpClient _httpClient;

  @override
  Future<Either<Failure, SuggestionMessageOutput>> sendMessage(
    SuggestionMessageInput input,
  ) async {
    try {
      final response = await _httpClient.post(
        AppPath.suggestionsChat,
        data: input.toJson(),
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        return Right(SuggestionMessageOutput.fromDynamic(response.data));
      }

      return Left(
        SaveFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao enviar mensagem para assistente.',
          ),
        ),
      );
    } catch (err) {
      return Left(SaveFailure(message: err.toString()));
    }
  }

  @override
  Future<Either<Failure, AcceptBlockOutput>> acceptBlock(
    AcceptBlockInput input,
  ) async {
    try {
      final response = await _httpClient.post(
        AppPath.suggestionsAccept,
        data: input.toJson(),
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        return Right(AcceptBlockOutput.fromDynamic(response.data));
      }

      return Left(
        SaveFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao criar item da sugestão.',
          ),
        ),
      );
    } catch (err) {
      return Left(SaveFailure(message: err.toString()));
    }
  }

  @override
  Future<Either<Failure, SuggestionConversationOutput>> getConversation(
    String id,
  ) async {
    try {
      final response = await _httpClient.get(
        AppPath.suggestionsConversationById(id),
      );

      final statusCode = response.statusCode ?? 0;
      if (_isSuccess(statusCode)) {
        return Right(SuggestionConversationOutput.fromDynamic(response.data));
      }

      return Left(
        GetFailure(
          message: ApiErrorMapper.fromResponseData(
            response.data,
            fallbackMessage: 'Erro ao carregar conversa.',
          ),
        ),
      );
    } catch (err) {
      return Left(GetFailure(message: err.toString()));
    }
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;
}
