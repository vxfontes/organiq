class TextUtils {
  TextUtils._();

  static String? normalize(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  static String countLabel(int count, String singular, String plural) {
    final label = count == 1 ? singular : plural;
    return '$count $label';
  }

  static String greetingWithOptionalName(String greeting, {String? name}) {
    final normalizedName = normalize(name);
    if (normalizedName == null) return '$greeting!';
    return '$greeting, $normalizedName!';
  }

  static String formatHourMinute(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String formatHourRange(DateTime start, {DateTime? end}) {
    final startLocal = start.toLocal();
    final startLabel = formatHourMinute(startLocal);
    final endLocal = end?.toLocal();
    if (endLocal == null || !endLocal.isAfter(startLocal)) {
      return startLabel;
    }
    return '$startLabel-${formatHourMinute(endLocal)}';
  }
}
