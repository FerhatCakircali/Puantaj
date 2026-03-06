import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../../core/user_data_notifier.dart';
import '../../../../services/fcm_service.dart';
import '../../../../services/notification_service.dart';
import '../../../../features/worker/services/worker_notification_listener_service.dart';
import '../../../../data/services/local_storage_service.dart';
import '../../../../data/services/password_hasher.dart';
import '../../../admin/panel/services/activity_log_service.dart';

mixin AuthLoginMixin {
  static const String userKey = 'logged_in_user_id';
  final _activityLogService = ActivityLogService();

  /// Giriş yapma işlemi
  Future<String?> signIn(String username, String password) async {
    try {
      final lowercaseUsername = username.toLowerCase();

      final result = await Supabase.instance.client
          .from('users')
          .select('*, is_blocked')
          .eq('username', lowercaseUsername)
          .maybeSingle();

      if (result == null) {
        userDataNotifier.value = null;
        return 'Kullanıcı adı veya şifre yanlış.';
      }

      // Şifre doğrulama (bcrypt ile)
      final storedHash = result['password_hash'] as String;
      final passwordHasher = PasswordHasher.instance;

      bool isPasswordValid;
      if (passwordHasher.isValidHash(storedHash)) {
        // Hash'lenmiş şifre - bcrypt ile doğrula
        isPasswordValid = await passwordHasher.verifyPassword(
          password,
          storedHash,
        );
      } else {
        // Plain text şifre (eski kullanıcılar için) - direkt karşılaştır ve hash'le
        isPasswordValid = password == storedHash;

        if (isPasswordValid) {
          // Şifreyi hash'le ve güncelle
          final newHash = await passwordHasher.hashPassword(password);
          await Supabase.instance.client
              .from('users')
              .update({'password_hash': newHash})
              .eq('id', result['id']);
          debugPrint('✅ Kullanıcı şifresi hash\'lendi: ${result['id']}');
        }
      }

      if (!isPasswordValid) {
        userDataNotifier.value = null;
        return 'Kullanıcı adı veya şifre yanlış.';
      }

      final isBlocked = result['is_blocked'] as bool;
      if (isBlocked) {
        userDataNotifier.value = null;
        return 'Hesabınız yönetici tarafından onaylanana kadar giriş yapamazsınız.';
      }

      // Kullanıcı girişi yapılırken çalışan oturumunu ve bildirim dinleyicisini temizle
      try {
        debugPrint('🧹 Kullanıcı girişi - Çalışan oturumu temizleniyor...');

        // Çalışan bildirim dinleyicisini durdur
        await WorkerNotificationListenerService.instance.stopListening();
        debugPrint('Çalışan bildirim dinleyicisi durduruldu');

        // Çalışan oturumunu temizle
        await LocalStorageService.instance.clearWorkerSession();
        debugPrint('Çalışan oturumu temizlendi');
      } catch (e) {
        debugPrint(
          '⚠️ Çalışan oturumu temizlenirken hata (devam ediliyor): $e',
        );
      }

      final userId = result['id'] as int;
      await setLoggedInUserId(userId);
      await loadCurrentUser();

      // FCM token'ı kaydet
      try {
        debugPrint('💾 FCM token kaydediliyor (User: $userId)...');
        await FCMService.instance.saveTokenForUser(userId);
        debugPrint('FCM token kaydedildi');
      } catch (e) {
        debugPrint('FCM token kaydedilemedi (devam ediliyor): $e');
      }

      // Giriş logu kaydet
      try {
        await _activityLogService.logActivity(
          adminId: userId,
          adminUsername: lowercaseUsername,
          actionType: 'login',
          targetUserId: userId,
          targetUsername: lowercaseUsername,
        );
      } catch (e) {
        debugPrint('Giriş logu kaydedilemedi: $e');
      }

      return null;
    } catch (e) {
      debugPrint('Giriş sırasında hata: $e');

      if (e is SocketException || e is http.ClientException) {
        userDataNotifier.value = null;
        return 'İnternet bağlantınızı kontrol edin ve tekrar deneyin.';
      } else if (e is PostgrestException) {
        debugPrint(
          'PostgrestException detayları: Code=${e.code}, Message=${e.message}, Details=${e.details}',
        );
        if (e.code == '42P01') {
          return 'Veritabanı tabloları oluşturulmamış. Lütfen yöneticinize başvurun.';
        }
        return 'Veritabanı hatası: ${e.message}';
      }

      userDataNotifier.value = null;
      return 'Giriş sırasında bir hata oluştu: ${e.toString()}';
    }
  }

  /// Çıkış yapma işlemi
  Future<void> signOut() async {
    try {
      // Çıkış logu kaydet (önce kullanıcı bilgilerini al)
      try {
        final user = await loadCurrentUser();
        if (user != null) {
          await _activityLogService.logActivity(
            adminId: user['id'],
            adminUsername: user['username'] ?? '',
            actionType: 'logout',
            targetUserId: user['id'],
            targetUsername: user['username'],
          );
        }
      } catch (e) {
        debugPrint('Çıkış logu kaydedilemedi: $e');
      }

      // FCM token'ı sil
      try {
        debugPrint('FCM token siliniyor...');
        await FCMService.instance.deleteToken();
        debugPrint('FCM token silindi');
      } catch (e) {
        debugPrint('FCM token silinemedi (devam ediliyor): $e');
      }

      userDataNotifier.value = null;

      try {
        final notificationService = NotificationService();
        await notificationService.clearAllNotificationsOnLogout();
      } catch (e) {
        debugPrint('Bildirim temizleme hatası: $e');
      }

      await clearSessionData();
    } catch (e) {
      debugPrint('Çıkış sırasında hata: $e');
    }
  }

  /// Kullanıcı ID'sini al
  Future<int?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(userKey);

      debugPrint('🔍 getUserId: SharedPreferences\'tan okunan değer: $userId');

      if (userId == null) {
        debugPrint('getUserId: Kullanıcı ID bulunamadı');
        // Tüm kayıtlı anahtarları göster
        final keys = prefs.getKeys();
        debugPrint('📋 SharedPreferences\'taki tüm anahtarlar: $keys');

        // Eğer cached_user_data varsa, kullanıcı daha önce giriş yapmış demektir
        // Bu durumda oturumu temizleme, user ID'yi kurtarmaya çalış
        final cachedUserData = prefs.getString('cached_user_data');
        if (cachedUserData != null) {
          debugPrint(
            '⚠️ getUserId: logged_in_user_id yok ama cached_user_data var! Oturum kurtarılıyor.',
          );
          try {
            // JSON string'i parse et
            final userData =
                json.decode(cachedUserData) as Map<String, dynamic>;
            final recoveredUserId = userData['id'] as int?;
            if (recoveredUserId != null) {
              // Kullanıcı ID'sini geri kaydet
              await prefs.setInt(userKey, recoveredUserId);
              debugPrint(
                '✅ getUserId: Kullanıcı ID kurtarıldı ve kaydedildi: $recoveredUserId',
              );
              return recoveredUserId;
            }
          } catch (e) {
            debugPrint('getUserId: cached_user_data parse edilemedi: $e');
          }
        }

        return null;
      }

      // Kullanıcı varlık kontrolünü sadece internet bağlantısı varsa yap
      try {
        final userExists = await checkUserExists(userId);
        if (!userExists) {
          debugPrint(
            'getUserId: Kullanıcı veritabanında bulunamadı, oturum temizleniyor',
          );
          await clearSessionData();
          return null;
        }
        debugPrint('getUserId: Kullanıcı ID başarıyla alındı: $userId');
        return userId;
      } catch (e) {
        // İnternet bağlantısı yoksa veya Supabase'e erişilemiyorsa
        // kullanıcıyı çıkış yaptırma, local ID'yi kullan
        debugPrint(
          '⚠️ getUserId: Kullanıcı varlık kontrolü başarısız (internet bağlantısı?), local ID kullanılıyor: $e',
        );
        // Local ID'yi döndür, oturumu temizleme
        return userId;
      }
    } catch (e) {
      debugPrint('getUserId hatası: $e');
      return null;
    }
  }

  /// Kullanıcı ID'sini kaydet
  Future<void> setLoggedInUserId(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(userKey, id);

      // Doğrulama: Gerçekten kaydedildi mi?
      final savedId = prefs.getInt(userKey);
      if (savedId == id) {
        debugPrint('Kullanıcı ID başarıyla kaydedildi ve doğrulandı: $id');
      } else {
        debugPrint(
          '⚠️ Kullanıcı ID kaydedildi ama doğrulanamadı! Beklenen: $id, Okunan: $savedId',
        );
      }
    } catch (e) {
      debugPrint('Kullanıcı ID kaydedilemedi: $e');
      rethrow;
    }
  }

  /// Oturum bilgilerini temizle
  Future<void> clearSessionData() async {
    try {
      debugPrint('Oturum bilgileri temizleniyor...');
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(userKey);
      await prefs.remove('cached_user_data');
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

  /// Kullanıcının veritabanında var olup olmadığını kontrol et
  /// Hata durumunda exception fırlatır (internet yoksa vs.)
  Future<bool> checkUserExists(int userId) async {
    final result = await Supabase.instance.client
        .from('users')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    return result != null;
  }

  /// Mevcut kullanıcı bilgilerini yükle
  Future<Map<String, dynamic>?> loadCurrentUser() async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        userDataNotifier.value = null;
        return null;
      }

      try {
        final result = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', userId)
            .single();

        userDataNotifier.value = result;

        // Kullanıcı bilgilerini JSON olarak cache'le
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cached_user_data', jsonEncode(result));
          debugPrint('✅ Kullanıcı bilgileri cache\'lendi');
        } catch (e) {
          debugPrint('⚠️ Kullanıcı bilgileri cache\'lenemedi: $e');
        }

        return result;
      } catch (e) {
        debugPrint('Kullanıcı bilgileri alınırken hata: $e');

        // İnternet bağlantısı yoksa cache'den yükle
        if (e is SocketException ||
            e is http.ClientException ||
            e is PostgrestException) {
          debugPrint('⚠️ Veritabanına erişilemiyor, cache\'den yükleniyor...');
          try {
            final prefs = await SharedPreferences.getInstance();
            final cachedData = prefs.getString('cached_user_data');
            if (cachedData != null) {
              final userData = jsonDecode(cachedData) as Map<String, dynamic>;
              userDataNotifier.value = userData;
              debugPrint(
                '✅ Cache\'den kullanıcı bilgileri yüklendi: ${userData['username']}',
              );
              return userData;
            } else {
              debugPrint('⚠️ Cache\'de kullanıcı bilgisi bulunamadı');
            }
          } catch (cacheError) {
            debugPrint('⚠️ Cache\'den yükleme hatası: $cacheError');
          }
        }

        userDataNotifier.value = null;
        return null;
      }
    } catch (e) {
      debugPrint('loadCurrentUser erişiminde hata: $e');
      return null;
    }
  }

  /// Kullanıcının bloklu olup olmadığını kontrol et
  Future<bool> isUserBlocked() async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        return false;
      }

      final result = await Supabase.instance.client
          .from('users')
          .select('is_blocked')
          .eq('id', userId)
          .maybeSingle();

      if (result == null) {
        return false;
      }

      return result['is_blocked'] as bool? ?? false;
    } catch (e) {
      debugPrint('Kullanıcı blok durumu kontrolü hatası: $e');
      return false;
    }
  }
}
