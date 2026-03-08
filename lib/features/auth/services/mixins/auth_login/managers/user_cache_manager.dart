import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kullanıcı verilerinin cache yönetimini sağlayan sınıf
class UserCacheManager {
  static const String _cacheKey = 'cached_user_data';

  /// Kullanıcı verilerini cache'e kaydeder
  Future<void> cacheUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(userData));
      debugPrint('Kullanıcı bilgileri cache\'lendi');
    } catch (e) {
      debugPrint('Kullanıcı bilgileri cache\'lenemedi: $e');
    }
  }

  /// Cache'den kullanıcı verilerini yükler
  Future<Map<String, dynamic>?> loadCachedUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);

      if (cachedData != null) {
        final userData = jsonDecode(cachedData) as Map<String, dynamic>;
        debugPrint(
          'Cache\'den kullanıcı bilgileri yüklendi: ${userData['username']}',
        );
        return userData;
      }

      debugPrint('Cache\'de kullanıcı bilgisi bulunamadı');
      return null;
    } catch (e) {
      debugPrint('Cache\'den yükleme hatası: $e');
      return null;
    }
  }

  /// Cache'i temizler
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (e) {
      debugPrint('Cache temizlenirken hata: $e');
    }
  }

  /// Cache'den user ID'yi kurtarmaya çalışır
  Future<int?> recoverUserIdFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedUserData = prefs.getString(_cacheKey);

      if (cachedUserData != null) {
        debugPrint(
          'logged_in_user_id yok ama cached_user_data var! Oturum kurtarılıyor.',
        );
        final userData = json.decode(cachedUserData) as Map<String, dynamic>;
        final recoveredUserId = userData['id'] as int?;

        if (recoveredUserId != null) {
          debugPrint('Kullanıcı ID kurtarıldı: $recoveredUserId');
          return recoveredUserId;
        }
      }

      return null;
    } catch (e) {
      debugPrint('cached_user_data parse edilemedi: $e');
      return null;
    }
  }
}
