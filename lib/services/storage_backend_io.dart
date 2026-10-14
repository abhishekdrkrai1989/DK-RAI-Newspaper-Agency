import 'dart:convert';
import 'dart:io';

class StorageBackend {
  final Map<String, String> _cache = {};
  File? _storageFile;
  bool _inMemoryOnly = false;

  static Future<StorageBackend> init({bool inMemoryForTests = false}) async {
    final backend = StorageBackend();
    backend._inMemoryOnly = inMemoryForTests;
    if (!inMemoryForTests) {
      await backend._loadFromDisk();
    }
    return backend;
  }

  Future<File?> _resolveStorageFile() async {
    if (_storageFile != null) return _storageFile;

    // 1. Android persistent app-private internal storage paths
    const androidDirs = [
      '/data/user/0/com.example.newspaper_delivery_app/files',
      '/data/data/com.example.newspaper_delivery_app/files',
    ];
    for (final dirPath in androidDirs) {
      try {
        final dir = Directory(dirPath);
        if (await dir.parent.exists()) {
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          _storageFile = File('$dirPath/newspaper_app_storage_v1.json');
          return _storageFile;
        }
      } catch (_) {
        // Continue to fallback
      }
    }

    // 2. Desktop / fallback persistent storage directory
    try {
      final home = Platform.environment['USERPROFILE'] ??
          Platform.environment['HOME'] ??
          Directory.systemTemp.path;
      final dir = Directory('$home/.newspaper_delivery_app');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _storageFile = File('${dir.path}/newspaper_app_storage_v1.json');
      return _storageFile;
    } catch (_) {
      _storageFile =
          File('${Directory.systemTemp.path}/newspaper_app_storage_v1.json');
      return _storageFile;
    }
  }

  Future<void> _loadFromDisk() async {
    try {
      final file = await _resolveStorageFile();
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final decoded = jsonDecode(content) as Map<String, dynamic>;
          decoded.forEach((key, value) {
            if (value != null) {
              _cache[key] = value.toString();
            }
          });
        }
      }
    } catch (_) {
      // Ignore corrupt or inaccessible initial file
    }
  }

  Future<void> _flushToDisk() async {
    if (_inMemoryOnly) return;
    try {
      final file = await _resolveStorageFile();
      if (file != null) {
        await file.writeAsString(jsonEncode(_cache), flush: true);
      }
    } catch (_) {
      // Ignore write errors in restricted environments
    }
  }

  String? getString(String key) => _cache[key];

  Future<void> setString(String key, String value) async {
    _cache[key] = value;
    await _flushToDisk();
  }

  bool? getBool(String key) {
    final v = _cache[key];
    if (v == null) return null;
    return v == 'true';
  }

  Future<void> setBool(String key, bool value) async {
    _cache[key] = value ? 'true' : 'false';
    await _flushToDisk();
  }
}
