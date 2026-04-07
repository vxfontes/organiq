import 'package:organiq/shared/config/app_env.dart';
import 'package:organiq/shared/services/http/app_path.dart';

class AppService {
  static String getBackEndBaseUrl() {
    return 'http://localhost:8080${AppPath.apiPrefix}';
  }
}
