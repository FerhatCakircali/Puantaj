import 'package:flutter/material.dart';
import '../../../../../../core/app_globals.dart';
import '../../../../../../models/employee_reminder.dart';
import '../../../../../../services/auth_service.dart';
import '../../../../../../core/auth/base_auth_helper.dart';

/// Çalışan hatırlatıcıları için veritabanı CRUD işlemlerini yöneten mixin
mixin ReminderDataMixin {
  late final AuthHelper _authHelper = AuthHelper(AuthService());

  /// Kullanıcının tüm çalışan hatırlatıcılarını getir
  Future<List<EmployeeReminder>> getEmployeeReminders({
    bool includeCompleted = false,
  }) async {
    try {
      return await _authHelper.executeWithUserId((userId) async {
        final query = supabase
            .from('employee_reminders')
            .select()
            .eq('user_id', userId);

        if (!includeCompleted) {
          query.eq('is_completed', 0);
        }

        query.order('reminder_date', ascending: true);

        final List<dynamic> data = await query;

        return data.map((item) => EmployeeReminder.fromMap(item)).toList();
      });
    } catch (e) {
      debugPrint('Çalışan hatırlatıcıları alınırken hata: $e');
      return [];
    }
  }

  /// Belirli bir çalışanın hatırlatıcılarını getir
  Future<List<EmployeeReminder>> getEmployeeRemindersByWorkerId(
    int workerId, {
    bool includeCompleted = false,
  }) async {
    try {
      return await _authHelper.executeWithUserId((userId) async {
        final query = supabase
            .from('employee_reminders')
            .select()
            .eq('user_id', userId)
            .eq('worker_id', workerId);

        if (!includeCompleted) {
          query.eq('is_completed', 0);
        }

        query.order('reminder_date', ascending: true);

        final List<dynamic> data = await query;

        return data.map((item) => EmployeeReminder.fromMap(item)).toList();
      });
    } catch (e) {
      debugPrint('Çalışanın hatırlatıcıları alınırken hata: $e');
      return [];
    }
  }

  /// Hatırlatıcı ekle
  Future<EmployeeReminder?> addEmployeeReminder(
    EmployeeReminder reminder,
  ) async {
    try {
      return await _authHelper.executeWithUserId((userId) async {
        final data = await supabase
            .from('employee_reminders')
            .insert(reminder.toMap())
            .select()
            .single();

        return EmployeeReminder.fromMap(data);
      });
    } catch (e) {
      debugPrint('Çalışan hatırlatıcısı eklenirken hata: $e');
      return null;
    }
  }

  /// Hatırlatıcıyı güncelle
  Future<bool> updateEmployeeReminder(EmployeeReminder reminder) async {
    try {
      return await _authHelper.executeWithUserId((userId) async {
        await supabase
            .from('employee_reminders')
            .update(reminder.toMap())
            .eq('id', reminder.id!)
            .eq('user_id', userId);

        return true;
      });
    } catch (e) {
      debugPrint('Çalışan hatırlatıcısı güncellenirken hata: $e');
      return false;
    }
  }

  /// Hatırlatıcıyı sil
  Future<bool> deleteEmployeeReminder(int reminderId) async {
    try {
      return await _authHelper.executeWithUserId((userId) async {
        await supabase
            .from('employee_reminders')
            .delete()
            .eq('id', reminderId)
            .eq('user_id', userId);

        return true;
      });
    } catch (e) {
      debugPrint('Çalışan hatırlatıcısı silinirken hata: $e');
      return false;
    }
  }

  /// Hatırlatıcıyı tamamlandı olarak işaretle
  Future<bool> markReminderAsCompleted(int reminderId) async {
    try {
      return await _authHelper.executeWithUserId((userId) async {
        await supabase
            .from('employee_reminders')
            .update({'is_completed': 1})
            .eq('id', reminderId)
            .eq('user_id', userId);

        return true;
      });
    } catch (e) {
      debugPrint(
        'Çalışan hatırlatıcısı tamamlandı olarak işaretlenirken hata: $e',
      );
      return false;
    }
  }

  /// Kullanıcı bilgilerini al
  Future<Map<String, dynamic>> getUserData(int userId) async {
    try {
      final data = await supabase
          .from('users')
          .select('username, first_name, last_name')
          .eq('id', userId)
          .single();

      return data;
    } catch (e) {
      debugPrint('Kullanıcı bilgileri alınırken hata: $e');
      return {'username': 'kullanıcı', 'first_name': '', 'last_name': ''};
    }
  }

  /// Hatırlatıcıyı ID ile getir
  Future<EmployeeReminder?> getReminderById(int reminderId) async {
    try {
      return await _authHelper.executeWithUserId((userId) async {
        final data = await supabase
            .from('employee_reminders')
            .select()
            .eq('id', reminderId)
            .eq('user_id', userId)
            .single();

        return EmployeeReminder.fromMap(data);
      });
    } catch (e) {
      debugPrint('Hatırlatıcı bilgisi alınamadı (id=$reminderId): $e');
      return null;
    }
  }
}
