// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_shopping_preview_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeShoppingPreviewOutput _$HomeShoppingPreviewOutputFromJson(
  Map<String, dynamic> json,
) => HomeShoppingPreviewOutput(
  id: json['id'] == null
      ? ''
      : HomeShoppingPreviewOutput._stringFromJson(json['id']),
  title: json['title'] == null
      ? ''
      : HomeShoppingPreviewOutput._stringFromJson(json['title']),
  totalItems: json['total_items'] == null
      ? 0
      : HomeShoppingPreviewOutput._intFromJson(json['total_items']),
  pendingItems: json['pending_items'] == null
      ? 0
      : HomeShoppingPreviewOutput._intFromJson(json['pending_items']),
  previewItems: json['preview_items'] == null
      ? []
      : HomeShoppingPreviewOutput._previewItemsFromJson(json['preview_items']),
);

Map<String, dynamic> _$HomeShoppingPreviewOutputToJson(
  HomeShoppingPreviewOutput instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'total_items': instance.totalItems,
  'pending_items': instance.pendingItems,
  'preview_items': instance.previewItems,
};
