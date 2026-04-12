import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:organiq/shared/errors/api_error_mapper.dart';
import 'package:organiq/shared/services/analytics/app_error_reporter.dart';
import 'package:organiq/shared/services/analytics/app_monitoring_service.dart';
import 'package:organiq/shared/services/http/app_service.dart';
import 'package:organiq/shared/services/http/http_client.dart';
import 'package:organiq/shared/storage/auth_token_store.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class DioHttpClient implements IHttpClient {
  DioHttpClient(
    this.profile, {
    AuthTokenStore? tokenStore,
    AppMonitoringService? monitoringService,
  }) : _tokenStore = tokenStore,
       _monitoringService = monitoringService ?? AppMonitoringService.instance {
    _onCreate();
  }

  late Dio _instance;
  final Profile profile;
  final AuthTokenStore? _tokenStore;
  final AppMonitoringService _monitoringService;

  @override
  Future<ResponseModel> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extra,
    ResponseType responseType = ResponseType.json,
  }) async {
    final options = await _buildOptions(
      extra: extra,
      responseType: responseType,
    );
    return _request(
      () => _instance.get(
        path,
        queryParameters: queryParameters,
        options: options,
      ),
      method: 'GET',
      path: path,
    );
  }

  @override
  Future<ResponseModel> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extra,
  }) async {
    final options = await _buildOptions(
      extra: extra,
      responseType: ResponseType.json,
    );
    return _request(
      () => _instance.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      method: 'POST',
      path: path,
      requestData: data,
    );
  }

  @override
  Future<ResponseModel> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extra,
  }) async {
    final options = await _buildOptions(
      extra: extra,
      responseType: ResponseType.json,
    );
    return _request(
      () => _instance.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      method: 'PUT',
      path: path,
      requestData: data,
    );
  }

  @override
  Future<ResponseModel> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extra,
  }) async {
    final options = await _buildOptions(
      extra: extra,
      responseType: ResponseType.json,
    );
    return _request(
      () => _instance.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      method: 'DELETE',
      path: path,
      requestData: data,
    );
  }

  @override
  Future<ResponseModel> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extra,
  }) async {
    final options = await _buildOptions(
      extra: extra,
      responseType: ResponseType.json,
    );
    return _request(
      () => _instance.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      method: 'PATCH',
      path: path,
      requestData: data,
    );
  }

  Future<ResponseModel> _request(
    Future<Response<dynamic>> Function() call, {
    required String method,
    required String path,
    dynamic requestData,
  }) async {
    final metric = _startHttpMetric(
      path: path,
      method: method,
      requestData: requestData,
    );

    try {
      final response = await call();
      await _monitoringService.stopHttpMetric(
        metric,
        statusCode: response.statusCode,
        responseContentType: response.headers.value(Headers.contentTypeHeader),
        responsePayloadSize: _payloadSize(response.data),
      );

      return ResponseModel(
        data: response.data,
        statusCode: response.statusCode,
      );
    } on DioException catch (err) {
      final statusCode = err.response?.statusCode;
      await _monitoringService.stopHttpMetric(
        metric,
        statusCode: statusCode,
        responseContentType: err.response?.headers.value(
          Headers.contentTypeHeader,
        ),
        responsePayloadSize: _payloadSize(err.response?.data),
      );
      await _monitoringService.recordError(
        err,
        err.stackTrace,
        reason: 'http_request_failed',
        parameters: <String, Object?>{
          'method': method,
          'path': path,
          if (statusCode != null) 'status_code': statusCode,
          'dio_type': err.type.name,
        },
      );
      final data = err.response?.data ?? {'error': _mapDioError(err)};
      return ResponseModel(data: data, statusCode: statusCode);
    } catch (err, stackTrace) {
      await _monitoringService.stopHttpMetric(metric);
      await _monitoringService.recordError(
        err,
        stackTrace,
        reason: 'http_request_unexpected_failure',
        parameters: <String, Object?>{'method': method, 'path': path},
      );
      rethrow;
    }
  }

  String _mapDioError(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'timeout';
      case DioExceptionType.connectionError:
        return 'connection_refused';
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
        return err.message ?? 'unknown_error';
    }
  }

  Future<Options> _buildOptions({
    Map<String, dynamic>? extra,
    ResponseType responseType = ResponseType.json,
  }) async {
    final headers = <String, dynamic>{};
    final extraMap = extra ?? <String, dynamic>{};

    if (extraMap['headers'] is Map<String, dynamic>) {
      headers.addAll(extraMap['headers'] as Map<String, dynamic>);
    }

    final authFlag = extraMap['auth'];
    final shouldAttachToken = authFlag == null || authFlag == true;
    if (shouldAttachToken && _tokenStore != null) {
      final token = await _tokenStore.readToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return Options(
      extra: extraMap,
      headers: headers.isEmpty ? null : headers,
      responseType: responseType,
    );
  }

  void _onCreate() {
    final options = BaseOptions(
      baseUrl: AppService.getBackEndBaseUrl(),
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: _timeoutByProfile(profile),
      sendTimeout: _timeoutByProfile(profile),
      receiveDataWhenStatusError: true,
    );
    _instance = Dio(options);

    _instance.interceptors.addAll([
      // JWTInterceptor(profile),
      // LoggerInterceptor(profile, compact: true, request: true, requestBody: true, requestHeader: true),
      // CryptoInterceptor(profile: profile, bodyCrypto: true),
      // LoggerInterceptor(profile, compact: true, error: true, responseBody: true),
      // RetryInterceptor(dio: _instance, options: const RetryOptions(retryInterval: Duration(seconds: 2))),
      // ErrorInterceptor(profile),
      // PerformanceInterceptor(profile),
    ]);
    _instance.interceptors.add(
      InterceptorsWrapper(
        onError: (err, handler) async {
          _reportHttpError(err);
          if (err.response?.statusCode == 401) {
            final authFlag = err.requestOptions.extra['auth'];
            final isUnauthenticatedRequest = authFlag == false;
            if (!isUnauthenticatedRequest) {
              await _tokenStore?.clearToken();
              Modular.to.navigate('/auth/');
            }
          }
          handler.next(err);
        },
      ),
    );

    if (profile == Profile.DEV && !kReleaseMode) {
      _instance.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }
  }

  Duration _timeoutByProfile(Profile profile) {
    switch (profile) {
      case Profile.HML:
        return const Duration(seconds: 60);
      case Profile.PRD:
        return const Duration(seconds: 60);
      case Profile.DEV:
        return const Duration(seconds: 180);
    }
  }

  Dio get dio => _instance;

  HttpMetric? _startHttpMetric({
    required String path,
    required String method,
    dynamic requestData,
  }) {
    final baseUri = Uri.parse(_instance.options.baseUrl);
    final uri = baseUri.resolve(path);
    final metric = _monitoringService.newHttpMetric(url: uri, method: method);
    unawaited(
      _monitoringService.startHttpMetric(
        metric,
        requestPayloadSize: _payloadSize(requestData),
      ),
    );
    return metric;
  }

  int? _payloadSize(dynamic data) {
    if (data == null) return null;
    if (data is String) return data.length;
    if (data is List<int>) return data.length;
    return null;
  }

  void _reportHttpError(DioException err) {
    final path = err.requestOptions.path.trim();
    if (path.startsWith('/app-logs/')) {
      return;
    }

    final errorCode = _mapDioError(err);
    final message = ApiErrorMapper.fromResponseData(
      err.response?.data,
      fallbackMessage: err.message ?? errorCode,
    );

    AppErrorReporter.report(
      AppErrorReportPayload(
        source: 'dio',
        errorCode: errorCode,
        message: message,
        stackTrace: err.stackTrace.toString(),
        requestId: _extractRequestId(err),
        requestPath: path,
        requestMethod: err.requestOptions.method,
        httpStatus: err.response?.statusCode,
        metadata: <String, dynamic>{
          'dio_type': err.type.name,
          if (err.requestOptions.queryParameters.isNotEmpty)
            'has_query_parameters': true,
        },
      ),
    );
  }

  String? _extractRequestId(DioException err) {
    final responseData = err.response?.data;
    if (responseData is Map && responseData['requestId'] != null) {
      return responseData['requestId'].toString();
    }

    final headerValue = err.response?.headers.value('x-request-id');
    if (headerValue == null || headerValue.trim().isEmpty) {
      return null;
    }
    return headerValue.trim();
  }
}
