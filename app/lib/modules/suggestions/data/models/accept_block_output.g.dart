// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accept_block_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AcceptBlockOutput _$AcceptBlockOutputFromJson(Map<String, dynamic> json) =>
    AcceptBlockOutput(
      type: json['type'] as String,
      entityId: json['entityId'] as String,
      title: json['title'] as String,
    );

Map<String, dynamic> _$AcceptBlockOutputToJson(AcceptBlockOutput instance) =>
    <String, dynamic>{
      'type': instance.type,
      'entityId': instance.entityId,
      'title': instance.title,
    };
