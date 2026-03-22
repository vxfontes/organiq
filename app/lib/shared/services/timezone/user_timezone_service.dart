class UserTimezoneService {
  UserTimezoneService._();

  static final UserTimezoneService instance = UserTimezoneService._();

  String? _timezone;
  int? _offsetMinutes;

  String? get timezone => _timezone;

  void setTimezone(String? rawTimezone) {
    final normalized = rawTimezone?.trim();
    if (normalized == null || normalized.isEmpty) {
      clear();
      return;
    }
    _timezone = normalized;
    _offsetMinutes = _parseOffsetMinutes(normalized);
  }

  void clear() {
    _timezone = null;
    _offsetMinutes = null;
  }

  DateTime now() {
    final offset = _offsetMinutes;
    if (offset == null) return DateTime.now();

    final shifted = DateTime.now().toUtc().add(Duration(minutes: offset));
    return DateTime(
      shifted.year,
      shifted.month,
      shifted.day,
      shifted.hour,
      shifted.minute,
      shifted.second,
      shifted.millisecond,
      shifted.microsecond,
    );
  }

  DateTime toUserTimezone(DateTime value) {
    final offset = _offsetMinutes;
    if (offset == null) return value.toLocal();

    final shifted = value.toUtc().add(Duration(minutes: offset));
    return DateTime(
      shifted.year,
      shifted.month,
      shifted.day,
      shifted.hour,
      shifted.minute,
      shifted.second,
      shifted.millisecond,
      shifted.microsecond,
    );
  }

  int? _parseOffsetMinutes(String value) {
    final normalized = value.trim();
    final upper = normalized.toUpperCase();

    const aliases = <String, int>{
      'UTC': 0,
      'GMT': 0,
      'ETC/UTC': 0,
      'BRT': -180,
      'AMERICA/BAHIA': -180,
      'AMERICA/BELEM': -180,
      'AMERICA/FORTALEZA': -180,
      'AMERICA/MACEIO': -180,
      'AMERICA/RECIFE': -180,
      'AMERICA/SAO_PAULO': -180,
      'AMERICA/ARAGUAINA': -180,
      'AMERICA/CUIABA': -240,
      'AMERICA/MANAUS': -240,
      'AMERICA/CAMPO_GRANDE': -240,
      'AMERICA/PORTO_VELHO': -240,
      'AMERICA/BOA_VISTA': -240,
      'AMERICA/RIO_BRANCO': -300,
    };
    final aliasOffset = aliases[upper];
    if (aliasOffset != null) return aliasOffset;

    final utcMatch = RegExp(
      r'^(?:UTC|GMT)\s*([+-])\s*(\d{1,2})(?::?(\d{2}))?$',
    ).firstMatch(upper);
    if (utcMatch != null) {
      final sign = utcMatch.group(1) == '-' ? -1 : 1;
      final hour = int.parse(utcMatch.group(2)!);
      final minute = int.parse(utcMatch.group(3) ?? '0');
      return sign * ((hour * 60) + minute);
    }

    final compactMatch = RegExp(
      r'^([+-])(\d{1,2})(?::?(\d{2}))?$',
    ).firstMatch(normalized);
    if (compactMatch != null) {
      final sign = compactMatch.group(1) == '-' ? -1 : 1;
      final hour = int.parse(compactMatch.group(2)!);
      final minute = int.parse(compactMatch.group(3) ?? '0');
      return sign * ((hour * 60) + minute);
    }

    return null;
  }
}
