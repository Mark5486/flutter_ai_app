import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract interface class LocalStorageService {
  Future<void> setString(String key, String value);

  Future<void> setBool(String key, bool value);

  Future<void> setInt(String key, int value);

  Future<void> setDouble(String key, double value);

  Future<void> setJson(String key, Map<String, dynamic> value);

  String? getString(String key);

  bool? getBool(String key);

  int? getInt(String key);

  double? getDouble(String key);

  Map<String, dynamic>? getJson(String key);

  Future<void> remove(String key);

  Future<void> clear();

  bool contains(String key);
}

class LocalStorageServiceImpl implements LocalStorageService {
  final SharedPreferences _preferences;

  const LocalStorageServiceImpl(this._preferences);

  @override
  Future<void> setString(String key, String value) async {
    await _preferences.setString(key, value);
  }

  @override
  Future<void> setBool(String key, bool value) async {
    await _preferences.setBool(key, value);
  }

  @override
  Future<void> setInt(String key, int value) async {
    await _preferences.setInt(key, value);
  }

  @override
  Future<void> setDouble(String key, double value) async {
    await _preferences.setDouble(key, value);
  }

  @override
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    await _preferences.setString(key, jsonEncode(value));
  }

  @override
  String? getString(String key) {
    return _preferences.getString(key);
  }

  @override
  bool? getBool(String key) {
    return _preferences.getBool(key);
  }

  @override
  int? getInt(String key) {
    return _preferences.getInt(key);
  }

  @override
  double? getDouble(String key) {
    return _preferences.getDouble(key);
  }

  @override
  Map<String, dynamic>? getJson(String key) {
    final value = _preferences.getString(key);

    if (value == null || value.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(value);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> remove(String key) async {
    await _preferences.remove(key);
  }

  @override
  Future<void> clear() async {
    await _preferences.clear();
  }

  @override
  bool contains(String key) {
    return _preferences.containsKey(key);
  }
}
