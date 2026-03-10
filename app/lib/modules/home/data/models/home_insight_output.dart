import 'package:json_annotation/json_annotation.dart';

part 'home_insight_output.g.dart';

@JsonSerializable()
class HomeInsightOutput {
  const HomeInsightOutput({
    required this.title,
    required this.summary,
    required this.footer,
    required this.isFocus,
  });

  final String title;
  final String summary;
  final String footer;
  @JsonKey(name: 'is_focus')
  final bool isFocus;

  factory HomeInsightOutput.fromJson(Map<String, dynamic> json) {
    return _$HomeInsightOutputFromJson(json);
  }

  factory HomeInsightOutput.fromDynamic(dynamic value) {
    try {
      return HomeInsightOutput.fromJson(_asMap(value));
    } catch (_) {
      return const HomeInsightOutput(
        title: '',
        summary: '',
        footer: '',
        isFocus: false,
      );
    }
  }

  Map<String, dynamic> toJson() => _$HomeInsightOutputToJson(this);

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }
}
