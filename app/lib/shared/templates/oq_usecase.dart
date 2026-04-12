import 'package:dartz/dartz.dart';

typedef UsecaseResponse<E, T> = Future<Either<E, T>>;

/// Base class for all use cases.
///
/// Subclasses must implement a [call] method returning
/// [UsecaseResponse<Failure, R>] (i.e. [Future<Either<Failure, R>>]).
/// The parameter signature of [call] is left to each subclass because
/// use cases range from no-arg calls to named/optional parameters.
abstract class OQUsecase {}
