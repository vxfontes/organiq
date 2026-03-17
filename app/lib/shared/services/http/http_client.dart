import 'package:dio/dio.dart';

abstract class IHttpClient {
  Future<ResponseModel> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extra,
    ResponseType responseType = ResponseType.json,
  });

  Future<ResponseModel> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extra,
  });

  Future<ResponseModel> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extra,
  });

  Future<ResponseModel> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extra,
  });

  Future<ResponseModel> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? extra,
  });

  // Future<ResponseModel> download(String path,
  //     {dynamic data, Map<String, dynamic> queryParameters, Map<String, dynamic>? extra});
}

enum Profile { DEV, HML, PRD }

class ResponseModel {
  final int? statusCode;
  final dynamic data;

  ResponseModel({this.data, this.statusCode});
}
