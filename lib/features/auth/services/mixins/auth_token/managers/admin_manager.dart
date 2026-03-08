import 'package:flutter/foundation.dart';

/// Admin yönetim sınıfı
///
/// Admin yetki kontrollerini yönetir.
class AdminManager {
  final Future<Map<String, dynamic>?> Function() loadCurrentUser;

  AdminManager({required this.loadCurrentUser});

  /// Admin kontrolü
  ///
  /// Kullanıcının admin yetkisi olup olmadığını kontrol eder.
  Future<bool> isAdmin() async {
    try {
      final user = await loadCurrentUser();
      if (user == null) {
        debugPrint('Admin kontrolü: Kullanıcı bilgisi bulunamadı');
        return false;
      }

      final dynamic isAdminValue = user['is_admin'];
      final String username = (user['username'] as String).toLowerCase();

      bool isAdmin = false;

      if (isAdminValue is int) {
        isAdmin = isAdminValue == 1;
      } else if (isAdminValue is bool) {
        isAdmin = isAdminValue;
      }

      if (username == 'admin') {
        isAdmin = true;
      }

      return isAdmin;
    } catch (e) {
      debugPrint('Admin kontrolü hatası: $e');
      return false;
    }
  }

  /// System Administrator kontrolü
  ///
  /// Kullanıcının sistem yöneticisi olup olmadığını kontrol eder.
  bool isSystemAdmin(Map<String, dynamic> user) {
    final userId = user['id'];
    final username = user['username']?.toString().toLowerCase();
    return userId == 1 || username == 'admin';
  }

  /// Mevcut kullanıcının system admin olup olmadığını kontrol et
  Future<bool> isCurrentUserSystemAdmin() async {
    try {
      final user = await loadCurrentUser();
      if (user == null) return false;
      return isSystemAdmin(user);
    } catch (e) {
      debugPrint('System admin kontrolü hatası: $e');
      return false;
    }
  }
}
