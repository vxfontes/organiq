// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'flag_list_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FlagListOutput _$FlagListOutputFromJson(Map<String, dynamic> json) =>
    FlagListOutput(
      items: (json['items'] as List<dynamic>)
          .map((e) => FlagOutput.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
    );

Map<String, dynamic> _$FlagListOutputToJson(FlagListOutput instance) =>
    <String, dynamic>{
      'items': instance.items,
      'nextCursor': instance.nextCursor,
    };
