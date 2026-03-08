import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/di/service_locator.dart';
import 'user_cache_manager.dart';
import '../validators/user_validator.dart';

/// Kullanıcı oturum yönetimini sağlayan sınıf
class SessionManager {
  static const String _userKey = 'logged_in_user_id';

  final UserCacheManager _cacheManager;
  final UserValidator _validator;

  SessionManager({UserCacheManager? cacheManager, UserValidator? validator})
    : _cacheManager = cacheManager ?? UserCacheManager(),
      _validator = validator ?? UserValidator(getIt<SupabaseClient>());

  /// Kullanıcı ID'sini alır
  Future<int?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(_userKey);

      debugPrint('getUserId: SharedPreferences\'tan okunan değer: $userId');

      if (userId == null) {
        debugPrint('getUserId: Kullanıcı ID bulunamadı');

        final keys = prefs.getKeys();
        debugPrint('SharedPreferences\'taki tüm anahtarlar: $keys');

        final recoveredUserId = await _cacheManager.recoverUserIdFromCache();
        if (recoveredUserId != null) {
          await setUserId(recoveredUserId);
          debugPrint('Kullanıcı ID kurtarıldı ve kaydedildi: $recoveredUserId');
          return recoveredUserId;
        }

        return null;
      }

      try {
        final userExists = await _validator.checkUserExists(userId);
        if (!userExists) {
          debugPrint('Kullanıcı veritabanında bulunamadı, oturum temizleniyor');
          await clearSession();
          return null;
        }
        debugPrint('Kullanıcı ID başarıyla alındı: $userId');
        return userId;
      } catch (e) {
        debugPrint(
          'Kullanıcı varlık kontrolü başarısız (internet bağlantısı?), local ID kullanılıyor: $e',
        );
        return userId;
      }
    } catch (e) {
      debugPrint('getUserId hatası: $e');
      return null;
    }
  }

  /// Kullanıcı ID'sini kaydeder
  Future<void> setUserId(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_userKey, id);

      final savedId = prefs.getInt(_userKey);
      if (savedId == id) {
        debugPrint('Kullanıcı ID başarıyla kaydedildi ve doğrulandı: $id');
      } else {
        debugPrint(
          'Kullanıcı ID kaydedildi ama doğrulanamadı! Beklenen: $id, Okunan: $savedId',
        );
      }
    } catch (e) {
      debugPrint('Kullanıcı ID kaydedilemedi: $e');
      rethrow;
    }
  }

  /// Oturum bilgilerini temizler
  Future<void> clearSession() async {
    try {
      debugPrint('Oturum bilgileri temizleniyor...');
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_userKey);
      await _cacheManager.clearCache();
      await prefs.remove('launched_from_notification');
      await prefs.remove('last_notification_payload');
      await prefs.remove('notification_needs_handling');

      final now = DateTime.now();
      final todayKey = 'notification_sent_${now.year}_${now.month}_${now.day}';
      await prefs.remove(todayKey);

      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('notification_sent_')) {
          await prefs.remove(key);
        }
      }

      debugPrint('Oturum bilgileri temizlendi');
    } catch (e) {
      debugPrint('Oturum bilgileri temizlenirken hata: $e');
    }
  }
}
