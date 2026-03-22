import 'package:json_annotation/json_annotation.dart';

part 'accept_block_output.g.dart';

@JsonSerializable()
class AcceptBlockOutput {
  const AcceptBlockOutput({
    required this.type,
    required this.entityId,
    required this.title,
  });

  final String type;
  final String entityId;
  final String title;

  factory AcceptBlockOutput.fromJson(Map<String, dynamic> json) =>
      _$AcceptBlockOutputFromJson(json);

  factory AcceptBlockOutput.fromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) {
      return AcceptBlockOutput.fromJson(value);
    }
    if (value is Map) {
      return AcceptBlockOutput.fromJson(
        value.map((key, val) => MapEntry(key.toString(), val)),
      );
    }
    return const AcceptBlockOutput(type: '', entityId: '', title: '');
  }

  Map<String, dynamic> toJson() => _$AcceptBlockOutputToJson(this);
}
