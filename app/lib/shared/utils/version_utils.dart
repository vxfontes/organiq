class VersionUtils {
  static int compare(String v1, String v2) {
    final v1Parts = _getParts(v1);
    final v2Parts = _getParts(v2);

    final maxLength = v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;

    for (var i = 0; i < maxLength; i++) {
      final p1 = i < v1Parts.length ? v1Parts[i] : 0;
      final p2 = i < v2Parts.length ? v2Parts[i] : 0;

      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }

    return 0;
  }

  static List<int> _getParts(String version) {
    // Remove metadata and prerelease info for simple comparison
    final clean = version.split('+').first.split('-').first;
    return clean.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  }
}
