import 'package:organiq/shared/services/http/http_client.dart';

extension ResponseModelX on ResponseModel {
  bool get isSuccess {
    final code = statusCode ?? 0;
    return code >= 200 && code < 300;
  }

  Map<String, dynamic> asMap() {
    final data = this.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
