import 'package:inbota/modules/routines/data/models/routine_output.dart';
import 'package:json_annotation/json_annotation.dart';

part 'routine_list_output.g.dart';

@JsonSerializable()
class RoutineListOutput {
  const RoutineListOutput({
    this.items = const [],
    this.nextCursor,
  });

  final List<RoutineOutput> items;
  final String? nextCursor;

  factory RoutineListOutput.fromJson(Map<String, dynamic> json) {
    return _$RoutineListOutputFromJson(json);
  }

  RoutineListOutput copyWith({
    List<RoutineOutput>? items,
    String? nextCursor,
  }) {
    return RoutineListOutput(
      items: items ?? this.items,
      nextCursor: nextCursor ?? this.nextCursor,
    );
  }

  Map<String, dynamic> toJson() => _$RoutineListOutputToJson(this);
}
