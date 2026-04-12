import 'dart:io';

import 'package:dio/dio.dart';
import 'package:organiq/shared/errors/api_error_mapper.dart';
import 'package:organiq/shared/errors/failures.dart';

class ExceptionMapper {
  ExceptionMapper._();

  static const _noConnectionMessage =
      'Sem conexão com o servidor. Verifique sua internet e tente novamente.';

  static const _timeoutMessage =
      'A conexão demorou muito para responder. Tente novamente.';

  static Failure toFailure(
    Object err, {
    String fallbackMessage = 'Erro inesperado. Tente novamente.',
    Failure Function(String message)? failureFactory,
  }) {
    final factory = failureFactory ?? (msg) => UnknownFailure(message: msg);

    if (err is DioException) {
      return _fromDioException(err, fallbackMessage, factory);
    }

    if (err is SocketException || err is HandshakeException) {
      return NetworkFailure(message: _noConnectionMessage);
    }

    return factory(fallbackMessage);
  }

  static Failure _fromDioException(
    DioException err,
    String fallbackMessage,
    Failure Function(String) factory,
  ) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return NetworkFailure(message: _timeoutMessage);

      case DioExceptionType.connectionError:
        final inner = err.error;
        if (inner is SocketException || inner is HandshakeException) {
          return NetworkFailure(message: _noConnectionMessage);
        }
        return NetworkFailure(message: _noConnectionMessage);

      case DioExceptionType.badResponse:
        final message = ApiErrorMapper.fromResponseData(
          err.response?.data,
          fallbackMessage: fallbackMessage,
        );
        return factory(message);

      case DioExceptionType.cancel:
        return factory('Requisição cancelada.');

      case DioExceptionType.badCertificate:
        return NetworkFailure(
          message: 'Erro de segurança na conexão. Tente novamente.',
        );

      case DioExceptionType.unknown:
        final inner = err.error;
        if (inner is SocketException || inner is HandshakeException) {
          return NetworkFailure(message: _noConnectionMessage);
        }
        return factory(fallbackMessage);
    }
  }
}
