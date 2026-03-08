import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../../core/user_data_notifier.dart';
import '../../../../core/di/service_locator.dart';
import 'auth_login/handlers/sign_in_handler.dart';
import 'auth_login/handlers/sign_out_handler.dart';
import 'auth_login/managers/session_manager.dart';
import 'auth_login/managers/user_cache_manager.dart';
import 'auth_login/validators/user_validator.dart';

/// Kullanıcı giriş/çıkış işlemlerini koordine eden mixin
mixin AuthLoginMixin {
  final SignInHandler _signInHandler = SignInHandler();
  final SignOutHandler _signOutHandler = SignOutHandler();
  late final SessionManager _sessionManager = SessionManager(
    validator: UserValidator(getIt<SupabaseClient>()),
  );
  final UserCacheManager _cacheManager = UserCacheManager();
  late final UserValidator _validator = UserValidator(getIt<SupabaseClient>());

  /// Giriş yapma işlemi
  Future<String?> signIn(String username, String password) async {
    return await _signInHandler.signIn(username, password);
  }

  /// Çıkış yapma işlemi
  Future<void> signOut() async {
    await _signOutHandler.signOut(loadCurrentUser);
  }

  /// Kullanıcı ID'sini alır
  Future<int?> getUserId() async {
    return await _sessionManager.getUserId();
  }

  /// Kullanıcı ID'sini kaydeder
  Future<void> setLoggedInUserId(int id) async {
    await _sessionManager.setUserId(id);
  }

  /// Oturum bilgilerini temizler
  Future<void> clearSessionData() async {
    await _sessionManager.clearSession();
  }

  /// Kullanıcının veritabanında var olup olmadığını kontrol eder
  Future<bool> checkUserExists(int userId) async {
    return await _validator.checkUserExists(userId);
  }

  /// Mevcut kullanıcı bilgilerini yükler
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
        await _cacheManager.cacheUserData(result);

        return result;
      } catch (e) {
        debugPrint('Kullanıcı bilgileri alınırken hata: $e');

        if (e is SocketException ||
            e is http.ClientException ||
            e is PostgrestException) {
          debugPrint('Veritabanına erişilemiyor, cache\'den yükleniyor...');
          final userData = await _cacheManager.loadCachedUserData();
          if (userData != null) {
            userDataNotifier.value = userData;
            return userData;
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

  /// Kullanıcının bloklu olup olmadığını kontrol eder
  Future<bool> isUserBlocked() async {
    try {
      final userId = await getUserId();
      if (userId == null) {
        return false;
      }

      return await _validator.isUserBlocked(userId);
    } catch (e) {
      debugPrint('Kullanıcı blok durumu kontrolü hatası: $e');
      return false;
    }
  }
}
