import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../models/performance_mode.dart';
import '../models/system_info.dart';

class DatabaseService {
  static const MethodChannel _channel =
      MethodChannel('com.example.perfomance_booster_and_saver_app/root');

  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  // In-memory cache for ultra-responsive UI
  final Map<String, String> _cache = {};
  bool _isInitialized = false;

  bool _isAndroid() {
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  /// Initializes localdb and loads cached settings
  Future<void> init() async {
    if (_isInitialized) return;
    _cache.clear();

    if (_isAndroid()) {
      try {
        final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('dbGetAllSettings');
        if (result != null) {
          result.forEach((k, v) {
            _cache[k.toString()] = v.toString();
          });
        }
      } catch (_) {}
    } else {
      // Local fallback file storage for non-Android / tests
      try {
        final file = File('local_db.json');
        if (await file.exists()) {
          final content = await file.readAsString();
          final map = jsonDecode(content);
          if (map is Map) {
            map.forEach((k, v) => _cache[k.toString()] = v.toString());
          }
        }
      } catch (_) {}
    }

    // Set defaults if not present
    if (!_cache.containsKey('active_mode')) {
      _cache['active_mode'] = 'balance';
    }
    if (!_cache.containsKey('kill_apps_on_saver')) {
      _cache['kill_apps_on_saver'] = 'true';
    }
    if (!_cache.containsKey('disable_network_on_saver')) {
      _cache['disable_network_on_saver'] = 'false';
    }
    if (!_cache.containsKey('auto_apply_on_launch')) {
      _cache['auto_apply_on_launch'] = 'false';
    }
    if (!_cache.containsKey('custom_apps')) {
      _cache['custom_apps'] =
          'com.whatsapp,com.facebook.katana,org.telegram.messenger,com.instagram.android';
    }

    _isInitialized = true;
  }

  /// Retrieves the current persisted mode option from local database
  Future<PerformanceMode> getActiveMode() async {
    if (!_isInitialized) await init();

    if (_isAndroid()) {
      try {
        final val = await _channel.invokeMethod<String?>('dbGetSetting', {'key': 'active_mode'});
        if (val != null && val.isNotEmpty) {
          _cache['active_mode'] = val;
          return PerformanceMode.fromString(val);
        }
      } catch (_) {}
    }

    return PerformanceMode.fromString(_cache['active_mode'] ?? 'balance');
  }

  /// Persists the selected mode option into local SQLite database
  Future<void> setActiveMode(PerformanceMode mode) async {
    _cache['active_mode'] = mode.id;

    if (_isAndroid()) {
      try {
        await _channel.invokeMethod('dbSetSetting', {
          'key': 'active_mode',
          'value': mode.id,
        });
      } catch (_) {}
    } else {
      _saveLocalFile();
    }
  }

  /// Gets generic setting
  Future<String?> getSetting(String key, {String? defaultValue}) async {
    if (!_isInitialized) await init();

    if (_isAndroid()) {
      try {
        final val = await _channel.invokeMethod<String?>('dbGetSetting', {'key': key});
        if (val != null) {
          _cache[key] = val;
          return val;
        }
      } catch (_) {}
    }

    return _cache[key] ?? defaultValue;
  }

  /// Sets generic setting in SQLite database
  Future<void> setSetting(String key, String value) async {
    _cache[key] = value;

    if (_isAndroid()) {
      try {
        await _channel.invokeMethod('dbSetSetting', {
          'key': key,
          'value': value,
        });
      } catch (_) {}
    } else {
      _saveLocalFile();
    }
  }

  // Convenience getters and setters for app configuration
  bool get killAppsOnSaver => _cache['kill_apps_on_saver'] != 'false';
  set killAppsOnSaver(bool val) => setSetting('kill_apps_on_saver', val.toString());

  bool get disableNetworkOnSaver => _cache['disable_network_on_saver'] == 'true';
  set disableNetworkOnSaver(bool val) =>
      setSetting('disable_network_on_saver', val.toString());

  bool get autoApplyOnLaunch => _cache['auto_apply_on_launch'] == 'true';
  set autoApplyOnLaunch(bool val) =>
      setSetting('auto_apply_on_launch', val.toString());

  List<String> get customAppsToKill {
    final raw = _cache['custom_apps'] ??
        'com.whatsapp,com.facebook.katana,org.telegram.messenger,com.instagram.android';
    return raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  set customAppsToKill(List<String> apps) {
    setSetting('custom_apps', apps.join(','));
  }

  /// Fetches history audit logs from local SQLite DB
  Future<List<HistoryEntry>> getHistory({int limit = 50}) async {
    if (_isAndroid()) {
      try {
        final result = await _channel.invokeMethod<List<dynamic>>(
          'dbGetHistory',
          {'limit': limit},
        );
        if (result != null) {
          final entries = <HistoryEntry>[];
          for (final item in result) {
            if (item is Map) {
              entries.add(HistoryEntry.fromMap(item));
            }
          }
          return entries;
        }
      } catch (_) {}
    }

    return [];
  }

  /// Inserts a new execution record into SQLite DB
  Future<void> insertHistoryEntry({
    required String mode,
    required String governor,
    required String battery,
    required bool success,
    String notes = '',
  }) async {
    if (_isAndroid()) {
      try {
        await _channel.invokeMethod('dbInsertHistory', {
          'mode': mode,
          'governor': governor,
          'battery': battery,
          'timestamp': DateTime.now().toString().split('.').first,
          'success': success,
          'notes': notes,
        });
      } catch (_) {}
    }
  }

  /// Clears the history log table in SQLite DB
  Future<void> clearHistory() async {
    if (_isAndroid()) {
      try {
        await _channel.invokeMethod('dbClearHistory');
      } catch (_) {}
    }
  }

  void _saveLocalFile() {
    try {
      final file = File('local_db.json');
      file.writeAsStringSync(jsonEncode(_cache));
    } catch (_) {}
  }
}
