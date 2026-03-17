import 'package:dartz/dartz.dart';

import 'package:organiq/modules/events/data/models/agenda_output.dart';
import 'package:organiq/modules/events/data/models/event_create_input.dart';
import 'package:organiq/modules/events/data/models/event_list_output.dart';
import 'package:organiq/modules/events/data/models/event_output.dart';
import 'package:organiq/shared/errors/failures.dart';

abstract class IEventRepository {
  Future<Either<Failure, EventListOutput>> fetchEvents({
    int? limit,
    String? cursor,
  });

  Future<Either<Failure, EventOutput>> createEvent(EventCreateInput input);
  Future<Either<Failure, AgendaOutput>> fetchAgenda({int? limit});
  Future<Either<Failure, Unit>> deleteEvent(String id);
}
