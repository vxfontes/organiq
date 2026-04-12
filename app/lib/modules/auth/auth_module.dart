import 'package:organiq/modules/auth/data/repositories/auth_repository.dart';
import 'package:organiq/modules/auth/domain/repositories/i_auth_repository.dart';
import 'package:organiq/modules/auth/domain/usecases/get_me_usecase.dart';
import 'package:organiq/modules/auth/domain/usecases/login_usecase.dart';
import 'package:organiq/modules/auth/domain/usecases/logout_usecase.dart';
import 'package:organiq/modules/auth/domain/usecases/signup_usecase.dart';
import 'package:organiq/shared/services/analytics/app_session_service.dart';
import 'package:organiq/shared/services/cache/cache_service.dart';
import 'package:organiq/shared/services/http/http_client.dart';
import 'package:organiq/shared/storage/auth_token_store.dart';

class AuthModule {
  static void binds(i) {
    // repository
    i.addLazySingleton<IAuthRepository>(
      () => AuthRepository(
        i.get<IHttpClient>(),
        i.get<AuthTokenStore>(),
        i.get<AppSessionService>(),
        i.get<ICacheService>(),
      ),
    );

    // usecases
    i.addLazySingleton<GetMeUsecase>(GetMeUsecase.new);
    i.addLazySingleton<LoginUsecase>(LoginUsecase.new);
    i.addLazySingleton<SignupUsecase>(SignupUsecase.new);
    i.addLazySingleton<LogoutUsecase>(LogoutUsecase.new);
  }
}
