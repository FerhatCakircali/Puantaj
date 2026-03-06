import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendance.dart';
import '../utils/date_formatter.dart';
import '../core/error_logger.dart';
import 'auth_service.dart';
import 'notification_service.dart';

class AttendanceService {
  final AuthService _authService = AuthService();
  final NotificationService _notificationServiceV2 = NotificationService();

  SupabaseClient get supabase => Supabase.instance.client;

  Future<List<Attendance>> getAttendanceByDate(DateTime date) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        ErrorLogger.instance.logWarning(
          'AttendanceService.getAttendanceByDate: userId null',
        );
        return [];
      }

      final formattedDate = DateFormatter.toIso8601Date(date);

      final results = await supabase
          .from('attendance')
          .select()
          .eq('user_id', userId)
          .eq('date', formattedDate);

      return results.map<Attendance>((map) => Attendance.fromMap(map)).toList();
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'AttendanceService.getAttendanceByDate hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  Future<List<Attendance>> getAttendanceBetween(
    DateTime startDate,
    DateTime endDate, {
    int? workerId,
  }) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        ErrorLogger.instance.logWarning(
          'AttendanceService.getAttendanceBetween: userId null',
        );
        return [];
      }

      final formattedStartDate = DateFormatter.toIso8601Date(startDate);
      final formattedEndDate = DateFormatter.toIso8601Date(endDate);

      var query = supabase
          .from('attendance')
          .select()
          .eq('user_id', userId)
          .gte('date', formattedStartDate)
          .lte('date', formattedEndDate);

      if (workerId != null) {
        query = query.eq('worker_id', workerId);
      }

      final results = await query;

      return results.map<Attendance>((map) => Attendance.fromMap(map)).toList();
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'AttendanceService.getAttendanceBetween hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  Future<void> markAttendance({
    required int workerId,
    required DateTime date,
    required AttendanceStatus status,
  }) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        ErrorLogger.instance.logWarning(
          'AttendanceService.markAttendance: userId null',
        );
        return;
      }

      final formattedDate = DateFormatter.toIso8601Date(date);

      debugPrint(
        '💾 [AttendanceService] Kaydediliyor: worker=$workerId, date=$formattedDate, status=${status.name}',
      );

      // ⚡ FIX: Türkiye saatini (UTC+3) kullan
      final now = DateTime.now().toUtc().add(const Duration(hours: 3));
      final nowIso = now.toIso8601String();

      debugPrint('🕐 Türkiye saati: $nowIso');

      // Upsert kullan - eğer kayıt varsa güncelle, yoksa ekle
      await supabase.from('attendance').upsert(
        {
          'worker_id': workerId,
          'user_id': userId,
          'date': formattedDate,
          'status': status.name,
          'created_by': 'manager', // Yönetici tarafından oluşturuldu
          'created_at': nowIso, // Türkiye saati
          'updated_at': nowIso, // Türkiye saati
        },
        onConflict: 'worker_id,date', // UNIQUE constraint: (worker_id, date)
      );

      debugPrint('✅ [AttendanceService] Kaydedildi');

      // Yevmiye girişi yapıldığında bugünün hatırlatıcısını iptal et
      final today = DateTime.now();
      if (DateFormatter.toIso8601Date(date) ==
          DateFormatter.toIso8601Date(today)) {
        try {
          await _notificationServiceV2.cancelNotification(
            1,
          ); // NotificationIds.attendanceReminder
          debugPrint(
            '✅ Yevmiye hatırlatıcısı iptal edildi (yevmiye girişi yapıldı)',
          );
        } catch (e, stackTrace) {
          ErrorLogger.instance.logError(
            'AttendanceService.markAttendance - notification cancel hatası',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'AttendanceService.markAttendance hatası',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow; // Hatayı yukarı fırlat ki UI'da gösterilebilsin
    }
  }
}
