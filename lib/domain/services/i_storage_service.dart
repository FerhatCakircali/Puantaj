/// Storage service interface
///
/// Defines contract for local storage operations.
/// Implementations handle platform-specific storage (SharedPreferences, etc.).
abstract class IStorageService {
  /// Initialize storage service
  Future<void> initialize();

  /// Save string value
  Future<void> setString(String key, String value);

  /// Get string value
  Future<String?> getString(String key);

  /// Save boolean value
  Future<void> setBool(String key, bool value);

  /// Get boolean value
  Future<bool?> getBool(String key);

  /// Save integer value
  Future<void> setInt(String key, int value);

  /// Get integer value
  Future<int?> getInt(String key);

  /// Remove value by key
  Future<void> remove(String key);

  /// Clear all stored data
  Future<void> clear();

  /// Check if key exists
  Future<bool> containsKey(String key);
}
