import 'package:dio/dio.dart';
import 'package:organiq/shared/services/http/app_service.dart';
import 'package:organiq/shared/storage/auth_token_store.dart';

class AppLogHttpClient {
  AppLogHttpClient(this._tokenStore)
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppService.getBackEndBaseUrl(),
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 15),
          receiveDataWhenStatusError: true,
        ),
      );

  final AuthTokenStore _tokenStore;
  final Dio _dio;

  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    bool attachAuth = true,
  }) async {
    final headers = <String, dynamic>{};
    if (attachAuth) {
      final token = await _tokenStore.readToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return _dio.post(
      path,
      data: data,
      options: Options(headers: headers.isEmpty ? null : headers),
    );
  }
}
