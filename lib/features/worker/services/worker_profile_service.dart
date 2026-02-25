import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Çalışan profil servisi
///
/// SQL fonksiyonları:
/// - change_worker_password: Şifre değiştirme
/// - UPDATE workers: Profil güncelleme
class WorkerProfileService {
  SupabaseClient get supabase => Supabase.instance.client;

  /// Çalışan bilgilerini getir
  Future<Map<String, dynamic>?> getWorkerProfile(int workerId) async {
    try {
      final response = await supabase
          .from('workers')
          .select()
          .eq('id', workerId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('❌ getWorkerProfile hata: $e');
      return null;
    }
  }

  /// Profil bilgilerini güncelle
  ///
  /// SQL: UPDATE workers SET username = ?, full_name = ?, title = ?, phone = ?
  /// WHERE id = ?
  Future<bool> updateProfile({
    required int workerId,
    required String username,
    required String fullName,
    String? title,
    String? phone,
  }) async {
    try {
      await supabase
          .from('workers')
          .update({
            'username': username,
            'full_name': fullName,
            'title': title,
            'phone': phone,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', workerId);

      debugPrint('✅ Profil güncellendi');
      return true;
    } catch (e) {
      debugPrint('❌ updateProfile hata: $e');
      return false;
    }
  }

  /// Şifre değiştir
  ///
  /// SQL: SELECT change_worker_password(worker_id, old_hash, new_hash)
  Future<bool> changePassword({
    required int workerId,
    required String oldPasswordHash,
    required String newPasswordHash,
  }) async {
    try {
      final response = await supabase.rpc(
        'change_worker_password',
        params: {
          'worker_id_param': workerId,
          'old_password_hash': oldPasswordHash,
          'new_password_hash': newPasswordHash,
        },
      );

      final success = response as bool;
      if (success) {
        debugPrint('✅ Şifre değiştirildi');
      } else {
        debugPrint('❌ Eski şifre yanlış');
      }

      return success;
    } catch (e) {
      debugPrint('❌ changePassword hata: $e');
      return false;
    }
  }

  /// Son giriş zamanını güncelle
  Future<bool> updateLastLogin(int workerId) async {
    try {
      await supabase
          .from('workers')
          .update({'last_login': DateTime.now().toIso8601String()})
          .eq('id', workerId);

      return true;
    } catch (e) {
      debugPrint('❌ updateLastLogin hata: $e');
      return false;
    }
  }
}
