import 'package:dartz/dartz.dart';
import 'package:organiq/modules/inbox/data/models/inbox_confirm_input.dart';
import 'package:organiq/modules/inbox/data/models/inbox_confirm_output.dart';
import 'package:organiq/modules/inbox/data/models/inbox_create_input.dart';
import 'package:organiq/modules/inbox/data/models/inbox_item_output.dart';
import 'package:organiq/shared/errors/failures.dart';

abstract class IInboxRepository {
  Future<Either<Failure, InboxItemOutput>> createInboxItem(
    InboxCreateInput input,
  );

  Future<Either<Failure, InboxItemOutput>> reprocessInboxItem(String id);

  Future<Either<Failure, InboxConfirmOutput>> confirmInboxItem(
    InboxConfirmInput input,
  );
}
