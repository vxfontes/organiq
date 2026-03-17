import 'package:dartz/dartz.dart';

import 'package:organiq/modules/flags/data/models/flag_create_input.dart';
import 'package:organiq/modules/flags/data/models/flag_list_output.dart';
import 'package:organiq/modules/flags/data/models/flag_output.dart';
import 'package:organiq/modules/flags/data/models/flag_update_input.dart';
import 'package:organiq/modules/flags/data/models/subflag_create_input.dart';
import 'package:organiq/modules/flags/data/models/subflag_list_output.dart';
import 'package:organiq/modules/flags/data/models/subflag_output.dart';
import 'package:organiq/modules/flags/data/models/subflag_update_input.dart';
import 'package:organiq/shared/errors/failures.dart';

abstract class IFlagRepository {
  Future<Either<Failure, FlagListOutput>> fetchFlags({
    int? limit,
    String? cursor,
  });

  Future<Either<Failure, FlagOutput>> createFlag(FlagCreateInput input);

  Future<Either<Failure, FlagOutput>> updateFlag(FlagUpdateInput input);

  Future<Either<Failure, Unit>> deleteFlag(String id);

  Future<Either<Failure, SubflagListOutput>> fetchSubflagsByFlag({
    required String flagId,
    int? limit,
    String? cursor,
  });

  Future<Either<Failure, SubflagOutput>> createSubflag(
    SubflagCreateInput input,
  );

  Future<Either<Failure, SubflagOutput>> updateSubflag(
    SubflagUpdateInput input,
  );

  Future<Either<Failure, Unit>> deleteSubflag(String id);
}
