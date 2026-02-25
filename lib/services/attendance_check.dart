import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class AttendanceCheck {
  static const String attendanceKeyPrefix = 'attendance_date_user_';

  /// Kullanıcıya özel anahtar oluştur
  static Future<String> _getUserAttendanceKey() async {
    final userId = await AuthService().getUserId();
    return '$attendanceKeyPrefix${userId ?? "guest"}';
  }

  /// Bugünün yevmiye girişi yapılmış mı kontrolü
  static Future<bool> isTodayAttendanceDone() async {
    final prefs = await SharedPreferences.getInstance();
    final attendanceKey = await _getUserAttendanceKey();
    final savedDateStr = prefs.getString(attendanceKey);

    if (savedDateStr == null) return false;

    final savedDate = DateTime.tryParse(savedDateStr);
    if (savedDate == null) return false;

    final now = DateTime.now();
    return savedDate.year == now.year &&
        savedDate.month == now.month &&
        savedDate.day == now.day;
  }

  /// Bugün için yevmiye giriş yapıldı olarak işaretle
  static Future<void> markAttendanceDone() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final attendanceKey = await _getUserAttendanceKey();
    await prefs.setString(attendanceKey, now.toIso8601String());
    
    // Ayrıca bugün için işlem yapıldığını belirt (yeni anahtar)
    final todayKey = 'attendance_done_today_${now.year}_${now.month}_${now.day}';
    await prefs.setBool(todayKey, true);
  }
  
  /// Kullanıcı değiştiğinde veya çıkış yapıldığında yevmiye durumunu temizle
  static Future<void> clearAttendanceState() async {
    final prefs = await SharedPreferences.getInstance();
    final attendanceKey = await _getUserAttendanceKey();
    await prefs.remove(attendanceKey);
  }
}
