import 'package:json_annotation/json_annotation.dart';

part 'home_shopping_preview_output.g.dart';

@JsonSerializable()
class HomeShoppingPreviewOutput {
  const HomeShoppingPreviewOutput({
    required this.id,
    required this.title,
    required this.totalItems,
    required this.pendingItems,
    required this.previewItems,
  });

  @JsonKey(fromJson: _stringFromJson, defaultValue: '')
  final String id;
  @JsonKey(fromJson: _stringFromJson, defaultValue: '')
  final String title;
  @JsonKey(name: 'total_items', fromJson: _intFromJson, defaultValue: 0)
  final int totalItems;
  @JsonKey(name: 'pending_items', fromJson: _intFromJson, defaultValue: 0)
  final int pendingItems;
  @JsonKey(
    name: 'preview_items',
    fromJson: _previewItemsFromJson,
    defaultValue: <String>[],
  )
  final List<String> previewItems;

  factory HomeShoppingPreviewOutput.fromJson(Map<String, dynamic> json) {
    return _$HomeShoppingPreviewOutputFromJson(json);
  }

  factory HomeShoppingPreviewOutput.fromDynamic(dynamic value) {
    try {
      return HomeShoppingPreviewOutput.fromJson(_asMap(value));
    } catch (_) {
      return const HomeShoppingPreviewOutput(
        id: '',
        title: '',
        totalItems: 0,
        pendingItems: 0,
        previewItems: [],
      );
    }
  }

  Map<String, dynamic> toJson() => _$HomeShoppingPreviewOutputToJson(this);

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return <String, dynamic>{};
  }

  static String _stringFromJson(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static int _intFromJson(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static List<String> _previewItemsFromJson(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList();
  }
}
