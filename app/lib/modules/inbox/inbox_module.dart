import 'package:organiq/modules/inbox/data/repositories/inbox_repository.dart';
import 'package:organiq/modules/inbox/domain/repositories/i_inbox_repository.dart';
import 'package:organiq/modules/inbox/domain/usecases/confirm_inbox_item_usecase.dart';
import 'package:organiq/modules/inbox/domain/usecases/create_inbox_item_usecase.dart';
import 'package:organiq/modules/inbox/domain/usecases/reprocess_inbox_item_usecase.dart';

class InboxModule {
  static void binds(i) {
    i.addLazySingleton<IInboxRepository>(InboxRepository.new);
    i.addLazySingleton<CreateInboxItemUsecase>(CreateInboxItemUsecase.new);
    i.addLazySingleton<ReprocessInboxItemUsecase>(
      ReprocessInboxItemUsecase.new,
    );
    i.addLazySingleton<ConfirmInboxItemUsecase>(ConfirmInboxItemUsecase.new);
  }
}
