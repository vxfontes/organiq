import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:organiq/shared/services/http/app_service.dart';
import 'package:organiq/shared/services/http/http_client.dart';
import 'package:organiq/shared/storage/auth_token_store.dart';

class DioHttpClient implements IHttpClient {
  DioHttpClient(this.profile, {AuthTokenStore? tokenStore})
    : _tokenStore = tokenStore {
    _onCreate();
  }

  late Dio _instance;
  final Profile profile;
  final AuthTokenStore? _tokenStore;

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
    );
  }

  Future<ResponseModel> _request(
    Future<Response<dynamic>> Function() call,
  ) async {
    try {
      final response = await call();
      return ResponseModel(
        data: response.data,
        statusCode: response.statusCode,
      );
    } on DioException catch (err) {
      final statusCode = err.response?.statusCode;
      final data = err.response?.data ?? {'error': _mapDioError(err)};
      return ResponseModel(data: data, statusCode: statusCode);
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
}
