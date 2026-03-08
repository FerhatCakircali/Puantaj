import 'package:flutter/material.dart';
import '../../../../../../services/auth_service.dart';
import '../../../../../../services/notification_service.dart';

/// Hatırlatıcı zamanlama işlemlerini yöneten sınıf
class ReminderScheduler {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  /// Yevmiye hatırlatıcısını zamanlar
  Future<void> scheduleAttendanceReminder(String selectedTime) async {
    try {
      final user = await _authService.currentUser;
      if (user == null) {
        debugPrint('Kullanıcı bilgisi alınamadı');
        return;
      }

      final userId = user['id'] as int;
      final username = user['username'] as String;
      final firstName = user['first_name'] as String? ?? '';
      final lastName = user['last_name'] as String? ?? '';
      final fullName = '$firstName $lastName'.trim();

      final timeParts = selectedTime.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      await _notificationService.scheduleAttendanceReminder(
        userId: userId,
        username: username,
        fullName: fullName,
        time: TimeOfDay(hour: hour, minute: minute),
      );

      debugPrint('Yevmiye hatırlatıcısı zamanlandı');
    } catch (e) {
      debugPrint('Yevmiye hatırlatıcısı zamanlanırken hata: $e');
    }
  }

  /// Yevmiye hatırlatıcısını iptal eder
  Future<void> cancelAttendanceReminder() async {
    try {
      await _notificationService.cancelNotification(1);
      debugPrint('Yevmiye hatırlatıcısı iptal edildi');
    } catch (e) {
      debugPrint('Yevmiye hatırlatıcısı iptal edilirken hata: $e');
    }
  }
}
