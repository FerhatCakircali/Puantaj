import '../../../../../../core/app_globals.dart';

/// Kimlik doğrulama sistemini izleyen sınıf
class AuthMonitor {
  /// Auth sistemini test eder
  Future<Map<String, dynamic>> checkAuth() async {
    try {
      // Mevcut kullanıcı bilgilerini kontrol et
      final user = supabase.auth.currentUser;

      if (user != null) {
        return {
          'status': 'healthy',
          'message': 'Kimlik doğrulama sistemi normal çalışıyor',
          'user_id': user.id,
          'last_check': DateTime.now().toIso8601String(),
        };
      } else {
        return {
          'status': 'warning',
          'message': 'Kullanıcı oturumu bulunamadı',
          'last_check': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Kimlik doğrulama sistemi hatası: $e',
        'last_check': DateTime.now().toIso8601String(),
      };
    }
  }
}
