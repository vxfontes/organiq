class GlobalShareValue {
  GlobalShareValue(this.value, this.expireTime);

  final dynamic value;
  final DateTime? expireTime;
}

class GlobalShare {
  static final Map<String, GlobalShareValue> _stores =
      <String, GlobalShareValue>{};

  static void setValue(String key, dynamic value, {Duration? ttl}) {
    if (ttl != null) {
      _stores[key] = GlobalShareValue(value, DateTime.now().add(ttl));
      return;
    }
    _stores[key] = GlobalShareValue(value, null);
  }

  static T? getValue<T>(String key, {dynamic defaultValue}) {
    if (_stores.containsKey(key)) {
      if (_stores[key]?.expireTime?.isBefore(DateTime.now()) ?? false) {
        _stores.remove(key);
        return defaultValue;
      }
      return _stores[key]!.value as T? ?? defaultValue;
    }
    return defaultValue;
  }

  static void clearValue(String key) {
    _stores[key] = GlobalShareValue(null, null);
  }

  static void removeValue(String key) {
    _stores.remove(key);
  }

  static void clearGlobalValues({required List<String> keyValuesToKeep}) {
    final preserved = <String, GlobalShareValue>{};

    for (final key in keyValuesToKeep) {
      final value = _stores[key];
      if (value != null) {
        preserved[key] = value;
      }
    }

    _stores
      ..clear()
      ..addAll(preserved);
  }
}
