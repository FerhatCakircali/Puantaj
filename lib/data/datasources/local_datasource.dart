import 'package:shared_preferences/shared_preferences.dart';

/// Local data source interface
/// Defines contract for local storage operations.
abstract class LocalDataSource {
  /// Save string data
  Future<void> saveData(String key, String value);

  /// Get string data
  Future<String?> getData(String key);

  /// Save boolean data
  Future<void> saveBool(String key, bool value);

  /// Get boolean data
  Future<bool?> getBool(String key);

  /// Save integer data
  Future<void> saveInt(String key, int value);

  /// Get integer data
  Future<int?> getInt(String key);

  /// Delete data by key
  Future<void> deleteData(String key);

  /// Clear all data
  Future<void> clearAll();

  /// Check if key exists
  Future<bool> containsKey(String key);
}

/// Local data source implementation
/// Uses SharedPreferences directly for local storage operations.
class LocalDataSourceImpl implements LocalDataSource {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  @override
  Future<void> saveData(String key, String value) async {
    try {
      final p = await prefs;
      await p.setString(key, value);
    } catch (e) {
      throw Exception('Save data failed: $e');
    }
  }

  @override
  Future<String?> getData(String key) async {
    try {
      final p = await prefs;
      return p.getString(key);
    } catch (e) {
      throw Exception('Get data failed: $e');
    }
  }

  @override
  Future<void> saveBool(String key, bool value) async {
    try {
      final p = await prefs;
      await p.setBool(key, value);
    } catch (e) {
      throw Exception('Save bool failed: $e');
    }
  }

  @override
  Future<bool?> getBool(String key) async {
    try {
      final p = await prefs;
      return p.getBool(key);
    } catch (e) {
      throw Exception('Get bool failed: $e');
    }
  }

  @override
  Future<void> saveInt(String key, int value) async {
    try {
      final p = await prefs;
      await p.setInt(key, value);
    } catch (e) {
      throw Exception('Save int failed: $e');
    }
  }

  @override
  Future<int?> getInt(String key) async {
    try {
      final p = await prefs;
      return p.getInt(key);
    } catch (e) {
      throw Exception('Get int failed: $e');
    }
  }

  @override
  Future<void> deleteData(String key) async {
    try {
      final p = await prefs;
      await p.remove(key);
    } catch (e) {
      throw Exception('Delete data failed: $e');
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      final p = await prefs;
      await p.clear();
    } catch (e) {
      throw Exception('Clear all failed: $e');
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    try {
      final p = await prefs;
      return p.containsKey(key);
    } catch (e) {
      throw Exception('Contains key check failed: $e');
    }
  }
}
