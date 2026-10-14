import 'dart:js_interop';
import 'dart:js_interop_unsafe';

class StorageBackend {
  final Map<String, String> _memoryFallback = {};
  bool _inMemoryOnly = false;

  static Future<StorageBackend> init({bool inMemoryForTests = false}) async {
    final backend = StorageBackend();
    backend._inMemoryOnly = inMemoryForTests;
    return backend;
  }

  JSObject? get _localStorage {
    if (_inMemoryOnly) return null;
    try {
      final ls = globalContext.getProperty('localStorage'.toJS);
      if (ls.isUndefinedOrNull) return null;
      return ls as JSObject;
    } catch (_) {
      return null;
    }
  }

  String? getString(String key) {
    final ls = _localStorage;
    if (ls != null) {
      try {
        final res = ls.callMethod('getItem'.toJS, key.toJS);
        if (!res.isUndefinedOrNull) {
          return (res as JSString).toDart;
        }
        return null;
      } catch (_) {}
    }
    return _memoryFallback[key];
  }

  Future<void> setString(String key, String value) async {
    _memoryFallback[key] = value;
    final ls = _localStorage;
    if (ls != null) {
      try {
        ls.callMethod('setItem'.toJS, key.toJS, value.toJS);
      } catch (_) {}
    }
  }

  bool? getBool(String key) {
    final v = getString(key);
    if (v == null) return null;
    return v == 'true';
  }

  Future<void> setBool(String key, bool value) async {
    await setString(key, value ? 'true' : 'false');
  }
}
