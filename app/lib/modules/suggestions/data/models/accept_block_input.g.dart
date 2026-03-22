// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accept_block_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$AcceptBlockInputToJson(AcceptBlockInput instance) {
  final val = <String, dynamic>{
    'type': instance.type,
    'title': instance.title,
    'weekdays': instance.weekdays,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('rationale', instance.rationale);
  writeNotNull('startsAt', _dateToUtcIso(instance.startsAt));
  writeNotNull('endsAt', _dateToUtcIso(instance.endsAt));
  writeNotNull('recurrenceType', instance.recurrenceType);
  writeNotNull('flagId', instance.flagId);
  writeNotNull('subflagId', instance.subflagId);

  return val;
}
