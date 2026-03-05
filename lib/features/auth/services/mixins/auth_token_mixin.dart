import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/services/password_hasher.dart';
import '../../../../services/validation_service.dart';
import '../../../admin/panel/services/activity_log_service.dart';

mixin AuthTokenMixin {
  // Bu mixin'de getUserId ve loadCurrentUser metodlarına ihtiyaç var
  // Bu metodlar AuthLoginMixin'de tanımlı
  Future<int?> getUserId();
  Future<Map<String, dynamic>?> loadCurrentUser();
  String? validateUsername(String username);
  Future<String?> checkUsernameAvailability(String username);
  Future<String?> checkEmailAvailability(String email);

  final _activityLogService = ActivityLogService();

  /// Şifre değiştirme
  Future<String?> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final userId = await getUserId();
    if (userId == null) return 'Oturum açmanız gerekiyor.';

    try {
      final result = await Supabase.instance.client
          .from('users')
          .select('password_hash')
          .eq('id', userId)
          .single();

      final storedHash = result['password_hash'] as String;
      final passwordHasher = PasswordHasher.instance;

      // Mevcut şifreyi doğrula
      bool isCurrentPasswordValid;
      if (passwordHasher.isValidHash(storedHash)) {
        // Hash'lenmiş şifre - bcrypt ile doğrula
        isCurrentPasswordValid = await passwordHasher.verifyPassword(
          currentPassword,
          storedHash,
        );
      } else {
        // Plain text şifre (eski kullanıcılar için)
        isCurrentPasswordValid = currentPassword == storedHash;
      }

      if (!isCurrentPasswordValid) {
        return 'Mevcut şifre yanlış.';
      }

      // Yeni şifreyi hash'le
      final newHashedPassword = await passwordHasher.hashPassword(newPassword);

      await Supabase.instance.client
          .from('users')
          .update({'password_hash': newHashedPassword})
          .eq('id', userId);

      // Aktivite logu kaydet
      final currentUser = await loadCurrentUser();
      if (currentUser != null) {
        await _activityLogService.logActivity(
          adminId: userId,
          adminUsername: currentUser['username'] ?? '',
          actionType: 'password_changed',
          targetUserId: userId,
          targetUsername: currentUser['username'],
        );
      }

      return null;
    } catch (e) {
      debugPrint('Şifre değiştirme hatası: $e');
      return 'Şifre değiştirilirken bir hata oluştu.';
    }
  }

  /// Profil güncelleme
  Future<String?> updateProfile(
    String firstName,
    String lastName,
    String jobTitle, {
    String? email,
  }) async {
    final userId = await getUserId();
    if (userId == null) return 'Oturum açmanız gerekiyor.';

    try {
      // Email kontrolü
      if (email != null && email.isNotEmpty) {
        // Mevcut kullanıcının email'ini al
        final currentUser = await loadCurrentUser();
        final currentEmail = currentUser?['email'] as String?;

        // Email değiştiyse kontrol et
        if (currentEmail?.toLowerCase() != email.toLowerCase()) {
          // Kendi ID'sini hariç tutarak kontrol et
          final emailAvailability = await ValidationService.instance
              .checkEmailAvailability(email, excludeUserId: userId);
          if (emailAvailability != null) {
            return emailAvailability;
          }
        }
      }

      final updateData = {
        'first_name': firstName,
        'last_name': lastName,
        'job_title': jobTitle,
      };

      // Email varsa ekle
      if (email != null && email.isNotEmpty) {
        updateData['email'] = email.toLowerCase();
      }

      await Supabase.instance.client
          .from('users')
          .update(updateData)
          .eq('id', userId);

      await loadCurrentUser();

      // Aktivite logu kaydet
      final currentUser = await loadCurrentUser();
      if (currentUser != null) {
        await _activityLogService.logActivity(
          adminId: userId,
          adminUsername: currentUser['username'] ?? '',
          actionType: 'profile_updated',
          targetUserId: userId,
          targetUsername: currentUser['username'],
          details: {
            'first_name': firstName,
            'last_name': lastName,
            'job_title': jobTitle,
            if (email != null && email.isNotEmpty) 'email': email,
          },
        );
      }

      return null;
    } catch (e) {
      debugPrint('Profil güncelleme hatası: $e');
      if (e is PostgrestException && e.code == '23505') {
        return 'Bu e-posta adresi zaten kullanılıyor.';
      }
      return 'Profil güncellenirken bir hata oluştu.';
    }
  }

  /// Kullanıcı adı güncelleme
  Future<String?> updateUsername(String newUsername) async {
    final userId = await getUserId();
    if (userId == null) return 'Oturum açmanız gerekiyor.';

    final lowercaseUsername = newUsername.toLowerCase();

    final usernameError = validateUsername(lowercaseUsername);
    if (usernameError != null) {
      return usernameError;
    }

    try {
      // Kendi ID'sini hariç tutarak kontrol et
      final usernameAvailability = await ValidationService.instance
          .checkUsernameAvailability(lowercaseUsername, excludeUserId: userId);
      if (usernameAvailability != null) {
        return usernameAvailability;
      }

      await Supabase.instance.client
          .from('users')
          .update({'username': lowercaseUsername})
          .eq('id', userId);

      await loadCurrentUser();
      return null;
    } catch (e) {
      debugPrint('Kullanıcı adı güncelleme hatası: $e');
      if (e is PostgrestException && e.code == 'P0001') {
        return 'Bu kullanıcı adı zaten kullanılıyor.';
      }
      return 'Kullanıcı adı güncellenirken bir hata oluştu.';
    }
  }

  /// Admin kontrolü
  Future<bool> isAdmin() async {
    try {
      final user = await loadCurrentUser();
      if (user == null) {
        debugPrint('isAdmin: Kullanıcı bilgisi bulunamadı');
        return false;
      }

      debugPrint('isAdmin: Kullanıcı verileri: ${user.toString()}');

      final dynamic isAdminValue = user['is_admin'];
      final String username = (user['username'] as String).toLowerCase();

      debugPrint(
        'isAdmin: is_admin değeri: $isAdminValue (${isAdminValue.runtimeType})',
      );
      debugPrint('isAdmin: username değeri: $username');

      bool isAdmin = false;

      if (isAdminValue is int) {
        isAdmin = isAdminValue == 1;
      } else if (isAdminValue is bool) {
        isAdmin = isAdminValue;
      }

      if (username == 'admin') {
        isAdmin = true;
      }

      debugPrint('isAdmin: Sonuç: $isAdmin');
      return isAdmin;
    } catch (e) {
      debugPrint('isAdmin: Hata: $e');
      return false;
    }
  }

  /// Tüm kullanıcıları getir
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final result = await Supabase.instance.client
          .from('users')
          .select()
          .order('id', ascending: false);
      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('Kullanıcılar getirilirken hata: $e');
      return [];
    }
  }

  /// Kullanıcı silme
  Future<String?> deleteUser(int userId) async {
    try {
      // Kullanıcı bilgilerini al
      final targetUser = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      await Supabase.instance.client.from('users').delete().eq('id', userId);

      // Aktivite logu kaydet
      final currentUser = await loadCurrentUser();
      if (currentUser != null) {
        await _activityLogService.logActivity(
          adminId: currentUser['id'],
          adminUsername: currentUser['username'] ?? '',
          actionType: 'user_deleted',
          targetUserId: userId,
          targetUsername: targetUser['username'],
        );
      }

      return null;
    } catch (e) {
      debugPrint('Kullanıcı silme hatası: $e');
      return 'Kullanıcı silinirken bir hata oluştu';
    }
  }

  /// Kullanıcı güncelleme
  Future<String?> updateUser({
    required int userId,
    required String username,
    required String firstName,
    required String lastName,
    required String jobTitle,
    required bool isAdmin,
    String? email,
  }) async {
    try {
      final lowercaseUsername = username.toLowerCase();

      // Eski kullanıcı bilgilerini al
      final oldUserData = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      final oldIsAdmin =
          oldUserData['is_admin'] == 1 || oldUserData['is_admin'] == true;

      // Users tablosunda kontrol et (kendi ID'si hariç)
      final existingUsers = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('username', lowercaseUsername)
          .neq('id', userId)
          .maybeSingle();

      if (existingUsers != null) {
        return 'Bu kullanıcı adı zaten kullanılıyor';
      }

      // Workers tablosunda da kontrol et
      final existingWorkers = await Supabase.instance.client
          .from('workers')
          .select('id')
          .eq('username', lowercaseUsername)
          .maybeSingle();

      if (existingWorkers != null) {
        return 'Bu kullanıcı adı zaten kullanılıyor';
      }

      // Email kontrolü (eğer email varsa)
      if (email != null && email.isNotEmpty) {
        final oldEmail = oldUserData['email'] as String?;

        // Email değiştiyse kontrol et
        if (oldEmail?.toLowerCase() != email.toLowerCase()) {
          final emailAvailability = await checkEmailAvailability(email);
          if (emailAvailability != null) {
            return emailAvailability;
          }
        }
      }

      final updateData = {
        'username': lowercaseUsername,
        'first_name': firstName,
        'last_name': lastName,
        'job_title': jobTitle,
        'is_admin': isAdmin ? 1 : 0, // Boolean'ı integer'a çevir
      };

      // Email varsa ekle
      if (email != null && email.isNotEmpty) {
        updateData['email'] = email.toLowerCase();
      }

      await Supabase.instance.client
          .from('users')
          .update(updateData)
          .eq('id', userId);

      debugPrint(
        '✅ Kullanıcı güncellendi: $lowercaseUsername, is_admin: ${isAdmin ? 1 : 0}',
      );

      // Aktivite logu kaydet
      final currentUser = await loadCurrentUser();
      if (currentUser != null) {
        await _activityLogService.logActivity(
          adminId: currentUser['id'],
          adminUsername: currentUser['username'] ?? '',
          actionType: 'user_updated',
          targetUserId: userId,
          targetUsername: lowercaseUsername,
          details: {
            'username': lowercaseUsername,
            'first_name': firstName,
            'last_name': lastName,
            'job_title': jobTitle,
            'is_admin': isAdmin,
          },
        );

        // Admin yetkisi değiştiyse ayrı log
        if (oldIsAdmin != isAdmin) {
          await _activityLogService.logActivity(
            adminId: currentUser['id'],
            adminUsername: currentUser['username'] ?? '',
            actionType: isAdmin ? 'admin_granted' : 'admin_revoked',
            targetUserId: userId,
            targetUsername: lowercaseUsername,
          );
        }
      }

      return null;
    } catch (e) {
      debugPrint('Kullanıcı güncelleme hatası: $e');
      return 'Kullanıcı güncellenirken bir hata oluştu';
    }
  }

  /// Kullanıcı blok durumu güncelleme
  Future<String?> updateUserBlockedStatus(int userId, bool isBlocked) async {
    try {
      // Kullanıcı bilgilerini al
      final targetUser = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      await Supabase.instance.client
          .from('users')
          .update({'is_blocked': isBlocked})
          .eq('id', userId);

      // Aktivite logu kaydet
      final currentUser = await loadCurrentUser();
      if (currentUser != null) {
        await _activityLogService.logActivity(
          adminId: currentUser['id'],
          adminUsername: currentUser['username'] ?? '',
          actionType: isBlocked ? 'user_blocked' : 'user_unblocked',
          targetUserId: userId,
          targetUsername: targetUser['username'],
        );
      }

      return null;
    } catch (e) {
      debugPrint('Kullanıcı blok durumu güncelleme hatası: $e');
      return 'Kullanıcı durumu güncellenirken bir hata oluştu';
    }
  }

  /// Kullanıcı profil güncelleme (admin tarafından)
  Future<String?> updateUserProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required String jobTitle,
  }) async {
    try {
      await Supabase.instance.client
          .from('users')
          .update({
            'first_name': firstName,
            'last_name': lastName,
            'job_title': jobTitle,
          })
          .eq('id', int.parse(userId));

      return null;
    } catch (e) {
      debugPrint('Kullanıcı profil güncelleme hatası: $e');
      return 'Profil güncellenirken bir hata oluştu';
    }
  }

  /// Kullanıcı blok durumu değiştirme
  Future<String?> toggleUserBlockStatus(String userId, bool isBlocked) async {
    try {
      await Supabase.instance.client
          .from('users')
          .update({'is_blocked': isBlocked})
          .eq('id', int.parse(userId));

      return null;
    } catch (e) {
      debugPrint('Kullanıcı blok durumu değiştirme hatası: $e');
      return 'Kullanıcı durumu değiştirilirken bir hata oluştu';
    }
  }

  /// Admin yetkisi değiştirme
  Future<String?> toggleUserAdminStatus(String userId, bool isAdmin) async {
    try {
      await Supabase.instance.client
          .from('users')
          .update({'is_admin': isAdmin})
          .eq('id', int.parse(userId));

      return null;
    } catch (e) {
      debugPrint('Admin yetkisi değiştirme hatası: $e');
      return 'Admin yetkisi değiştirilirken bir hata oluştu';
    }
  }

  /// System Administrator kontrolü
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
