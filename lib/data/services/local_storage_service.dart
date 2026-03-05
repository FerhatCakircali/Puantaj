import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/app_exception.dart';

/// Local storage service - Singleton pattern
///
/// Manages worker session persistence using SharedPreferences.
/// Follows Singleton pattern to ensure single instance across the app.
///
/// Session data includes:
/// - Worker ID
/// - Username
/// - Full name
/// - Login timestamp
///
/// Usage:
/// ```dart
/// final storage = LocalStorageService.instance;
/// await storage.saveWorkerSession(workerId, username, fullName);
/// final session = await storage.getWorkerSession();
/// ```
class LocalStorageService {
  LocalStorageService._();

  static final LocalStorageService _instance = LocalStorageService._();

  /// Singleton instance
  static LocalStorageService get instance => _instance;

  SharedPreferences? _prefs;

  // Storage keys
  static const String _keyWorkerId = 'worker_id';
  static const String _keyUserId = 'user_id';
  static const String _keyUsername = 'worker_username';
  static const String _keyFullName = 'worker_full_name';
  static const String _keyLoginTimestamp = 'worker_login_timestamp';

  // Session validity duration (365 days - 1 year)
  static const Duration _sessionDuration = Duration(days: 365);

  /// Initializes SharedPreferences
  ///
  /// Should be called once at app startup
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Gets SharedPreferences instance
  ///
  /// Throws [StorageException] if not initialized
  SharedPreferences get _preferences {
    if (_prefs == null) {
      throw StorageException('LocalStorageService not initialized');
    }
    return _prefs!;
  }

  /// Saves worker session data
  ///
  /// Stores worker ID, user ID, username, full name, and login timestamp.
  /// Session is valid for 365 days (1 year) from login time.
  Future<void> saveWorkerSession({
    required String workerId,
    required String username,
    required String fullName,
    String? userId,
  }) async {
    try {
      final timestamp = DateTime.now().toIso8601String();

      final futures = [
        _preferences.setString(_keyWorkerId, workerId),
        _preferences.setString(_keyUsername, username),
        _preferences.setString(_keyFullName, fullName),
        _preferences.setString(_keyLoginTimestamp, timestamp),
      ];

      if (userId != null) {
        futures.add(_preferences.setString(_keyUserId, userId));
      }

      await Future.wait(futures);
    } catch (e) {
      throw StorageException('Failed to save worker session: $e');
    }
  }

  /// Gets worker session data
  ///
  /// Returns a map with worker data if session exists and is valid.
  /// Returns null if no session or session expired.
  ///
  /// Map keys: 'workerId', 'userId', 'username', 'fullName', 'loginTimestamp'
  Future<Map<String, String>?> getWorkerSession() async {
    try {
      final workerId = _preferences.getString(_keyWorkerId);
      final userId = _preferences.getString(_keyUserId);
      final username = _preferences.getString(_keyUsername);
      final fullName = _preferences.getString(_keyFullName);
      final timestamp = _preferences.getString(_keyLoginTimestamp);

      // Check if all required data exists
      if (workerId == null ||
          username == null ||
          fullName == null ||
          timestamp == null) {
        return null;
      }

      // Check if session is still valid
      if (!isSessionValid()) {
        await clearSession();
        return null;
      }

      final session = {
        'workerId': workerId,
        'username': username,
        'fullName': fullName,
        'loginTimestamp': timestamp,
      };

      if (userId != null) {
        session['userId'] = userId;
      }

      return session;
    } catch (e) {
      throw StorageException('Failed to get worker session: $e');
    }
  }

  /// Checks if current session is valid
  ///
  /// Session is valid if:
  /// - Login timestamp exists
  /// - Less than 365 days have passed since login
  bool isSessionValid() {
    try {
      final timestamp = _preferences.getString(_keyLoginTimestamp);
      if (timestamp == null) return false;

      final loginTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(loginTime);

      return difference < _sessionDuration;
    } catch (e) {
      return false;
    }
  }

  /// Clears worker session data
  ///
  /// Removes all session-related data from storage.
  Future<void> clearSession() async {
    try {
      await Future.wait([
        _preferences.remove(_keyWorkerId),
        _preferences.remove(_keyUserId),
        _preferences.remove(_keyUsername),
        _preferences.remove(_keyFullName),
        _preferences.remove(_keyLoginTimestamp),
      ]);
    } catch (e) {
      throw StorageException('Failed to clear worker session: $e');
    }
  }

  /// Alias for clearSession (for backward compatibility)
  Future<void> clearWorkerSession() async {
    await clearSession();
  }

  /// Gets worker ID from session
  ///
  /// Returns null if no session exists
  String? getWorkerId() {
    return _preferences.getString(_keyWorkerId);
  }

  /// Gets username from session
  ///
  /// Returns null if no session exists
  String? getUsername() {
    return _preferences.getString(_keyUsername);
  }

  /// Checks if worker is logged in
  ///
  /// Returns true if valid session exists
  bool isLoggedIn() {
    return getWorkerId() != null && isSessionValid();
  }

  /// Clears all app data (for testing/debugging)
  Future<void> clearAll() async {
    await _preferences.clear();
  }
}
