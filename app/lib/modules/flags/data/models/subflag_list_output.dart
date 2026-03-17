import 'package:json_annotation/json_annotation.dart';
import 'package:organiq/modules/flags/data/models/subflag_output.dart';

part 'subflag_list_output.g.dart';

@JsonSerializable()
class SubflagListOutput {
  const SubflagListOutput({required this.items, this.nextCursor});

  final List<SubflagOutput> items;
  final String? nextCursor;

  factory SubflagListOutput.fromJson(Map<String, dynamic> json) {
    return _$SubflagListOutputFromJson(json);
  }

  factory SubflagListOutput.fromDynamic(dynamic value) {
    return SubflagListOutput.fromJson(_asMap(value));
  }

  Map<String, dynamic> toJson() => _$SubflagListOutputToJson(this);

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
