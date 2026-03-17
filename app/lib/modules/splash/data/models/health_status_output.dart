import 'package:json_annotation/json_annotation.dart';

part 'health_status_output.g.dart';

@JsonSerializable()
class HealthStatusOutput {
  const HealthStatusOutput({required this.status, this.time});

  final String status;
  final DateTime? time;

  factory HealthStatusOutput.fromJson(Map<String, dynamic> json) =>
      _$HealthStatusOutputFromJson(json);

  Map<String, dynamic> toJson() => _$HealthStatusOutputToJson(this);
}
