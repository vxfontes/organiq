import 'package:json_annotation/json_annotation.dart';
import 'package:organiq/modules/flags/data/models/flag_object_output.dart';

part 'subflag_output.g.dart';

@JsonSerializable()
class SubflagOutput {
  const SubflagOutput({
    required this.id,
    this.flag,
    required this.name,
    this.color,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final FlagObjectOutput? flag;
  final String name;
  final String? color;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SubflagOutput.fromJson(Map<String, dynamic> json) {
    return _$SubflagOutputFromJson(json);
  }

  factory SubflagOutput.fromDynamic(dynamic value) {
    return SubflagOutput.fromJson(_asMap(value));
  }

  Map<String, dynamic> toJson() => _$SubflagOutputToJson(this);

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return <String, dynamic>{};
  }
}
