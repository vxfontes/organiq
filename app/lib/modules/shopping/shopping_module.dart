import 'package:flutter_modular/flutter_modular.dart';
import 'package:organiq/modules/shopping/data/repositories/shopping_repository.dart';
import 'package:organiq/modules/shopping/domain/repositories/i_shopping_repository.dart';
import 'package:organiq/modules/shopping/domain/usecases/create_shopping_item_usecase.dart';
import 'package:organiq/modules/shopping/domain/usecases/create_shopping_list_usecase.dart';
import 'package:organiq/modules/shopping/domain/usecases/delete_shopping_item_usecase.dart';
import 'package:organiq/modules/shopping/domain/usecases/delete_shopping_list_usecase.dart';
import 'package:organiq/modules/shopping/domain/usecases/get_shopping_items_usecase.dart';
import 'package:organiq/modules/shopping/domain/usecases/get_shopping_lists_usecase.dart';
import 'package:organiq/modules/shopping/domain/usecases/update_shopping_item_usecase.dart';
import 'package:organiq/modules/shopping/domain/usecases/update_shopping_list_usecase.dart';
import 'package:organiq/shared/services/cache/cache_service.dart';
import 'package:organiq/shared/services/connectivity/connectivity_service.dart';
import 'package:organiq/shared/services/http/http_client.dart';

class ShoppingModule {
  static void binds(Injector i) {
    i.addLazySingleton<IShoppingRepository>(
      () => ShoppingRepository(
        i.get<IHttpClient>(),
        i.get<ICacheService>(),
        i.get<IConnectivityService>(),
      ),
    );

    i.addLazySingleton<GetShoppingListsUsecase>(GetShoppingListsUsecase.new);
    i.addLazySingleton<GetShoppingItemsUsecase>(GetShoppingItemsUsecase.new);
    i.addLazySingleton<UpdateShoppingItemUsecase>(
      UpdateShoppingItemUsecase.new,
    );
    i.addLazySingleton<CreateShoppingListUsecase>(
      CreateShoppingListUsecase.new,
    );
    i.addLazySingleton<UpdateShoppingListUsecase>(
      UpdateShoppingListUsecase.new,
    );
    i.addLazySingleton<CreateShoppingItemUsecase>(
      CreateShoppingItemUsecase.new,
    );
    i.addLazySingleton<DeleteShoppingListUsecase>(
      DeleteShoppingListUsecase.new,
    );
    i.addLazySingleton<DeleteShoppingItemUsecase>(
      DeleteShoppingItemUsecase.new,
    );
  }
}
