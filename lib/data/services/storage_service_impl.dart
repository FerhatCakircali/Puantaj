import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/services/i_storage_service.dart';
import '../../core/error_handler.dart';

/// Storage service implementation
/// Implements IStorageService using SharedPreferences.
/// Provides persistent local storage with error handling and logging.
class StorageServiceImpl implements IStorageService {
  SharedPreferences? _prefs;

  @override
  Future<void> initialize() async {
    try {
      ErrorHandler.logInfo('StorageService', 'Başlatılıyor...');
      _prefs = await SharedPreferences.getInstance();
      ErrorHandler.logSuccess('StorageService', 'Başarıyla başlatıldı');
    } catch (e, stackTrace) {
      ErrorHandler.logError('StorageService.initialize', e, stackTrace);
      rethrow;
    }
  }

  /// SharedPreferences instance'ını döndürür
    /// Initialize edilmemişse hata fırlatır
  SharedPreferences get _instance {
    if (_prefs == null) {
      throw StateError(
        'StorageService initialize edilmemiş. Önce initialize() çağırın.',
      );
    }
    return _prefs!;
  }

  @override
  Future<void> setString(String key, String value) async {
    try {
      await _instance.setString(key, value);
      ErrorHandler.logDebug('StorageService.setString', 'Key: $key');
    } catch (e, stackTrace) {
      ErrorHandler.logError('StorageService.setString', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<String?> getString(String key) async {
    try {
      final value = _instance.getString(key);
      ErrorHandler.logDebug('StorageService.getString', 'Key: $key');
      return value;
    } catch (e, stackTrace) {
      ErrorHandler.logError('StorageService.getString', e, stackTrace);
      return null;
    }
  }

  @override
  Future<void> setBool(String key, bool value) async {
    try {
      await _instance.setBool(key, value);
      ErrorHandler.logDebug('StorageService.setBool', 'Key: $key = $value');
    } catch (e, stackTrace) {
      ErrorHandler.logError('StorageService.setBool', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool?> getBool(String key) async {
    try {
      final value = _instance.getBool(key);
      ErrorHandler.logDebug('StorageService.getBool', 'Key: $key');
      return value;
    } catch (e, stackTrace) {
      ErrorHandler.logError('StorageService.getBool', e, stackTrace);
      return null;
    }
  }

  @override
  Future<void> setInt(String key, int value) async {
    try {
      await _instance.setInt(key, value);
      ErrorHandler.logDebug('StorageService.setInt', 'Key: $key = $value');
    } catch (e, stackTrace) {
      ErrorHandler.logError('StorageService.setInt', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<int?> getInt(String key) async {
    try {
      final value = _instance.getInt(key);
      ErrorHandler.logDebug('StorageService.getInt', 'Key: $key');
      return value;
    } catch (e, stackTrace) {
      ErrorHandler.logError('StorageService.getInt', e, stackTrace);
      return null;
    }
  }

  @override
  Future<void> remove(String key) async {
    try {
      await _instance.remove(key);
      ErrorHandler.logDebug('StorageService.remove', 'Key: $key');
    } catch (e, stackTrace) {
      ErrorHandler.logError('StorageService.remove', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _instance.clear();
      ErrorHandler.logWarning('StorageService.clear', 'Tüm storage temizlendi');
    } catch (e, stackTrace) {
      ErrorHandler.logError('StorageService.clear', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    try {
      final exists = _instance.containsKey(key);
      ErrorHandler.logDebug(
        'StorageService.containsKey',
        'Key: $key = $exists',
      );
      return exists;
    } catch (e, stackTrace) {
      ErrorHandler.logError('StorageService.containsKey', e, stackTrace);
      return false;
    }
  }
}
