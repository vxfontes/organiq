// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_insight_output.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeInsightOutput _$HomeInsightOutputFromJson(Map<String, dynamic> json) =>
    HomeInsightOutput(
      title: json['title'] as String,
      summary: json['summary'] as String,
      footer: json['footer'] as String,
      isFocus: json['is_focus'] as bool,
    );

Map<String, dynamic> _$HomeInsightOutputToJson(HomeInsightOutput instance) =>
    <String, dynamic>{
      'title': instance.title,
      'summary': instance.summary,
      'footer': instance.footer,
      'is_focus': instance.isFocus,
    };
