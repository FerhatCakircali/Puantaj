import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/attendance.dart';
import '../utils/date_formatter.dart';
import '../core/error_logger.dart';
import '../data/local/hive_service.dart';
import '../data/local/sync_manager.dart';
import 'auth_service.dart';
import 'notification_service.dart';

class AttendanceService {
  final AuthService _authService = AuthService();
  final NotificationService _notificationServiceV2 = NotificationService();
  final _hiveService = HiveService.instance;
  final _syncManager = SyncManager.instance;

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
    Attendance? tempAttendance;

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

      // 1. Optimistic update: Hive'a kaydet
      tempAttendance = Attendance(
        userId: userId,
        workerId: workerId,
        date: date,
        status: status,
        createdBy: 'manager',
        notificationSent: false,
      );

      final key = '${workerId}_$formattedDate';
      await _hiveService.attendance.put(key, tempAttendance);
      debugPrint('✅ Optimistic: Attendance Hive\'a eklendi');

      // 2. Online ise Supabase'e gönder
      if (_syncManager.isOnline) {
        try {
          final now = DateTime.now().toUtc().add(const Duration(hours: 3));
          final nowIso = now.toIso8601String();

          await supabase.from('attendance').upsert({
            'worker_id': workerId,
            'user_id': userId,
            'date': formattedDate,
            'status': status.name,
            'created_by': 'manager',
            'created_at': nowIso,
            'updated_at': nowIso,
          }, onConflict: 'worker_id,date');

          debugPrint('✅ [AttendanceService] Supabase\'e kaydedildi');
        } catch (e) {
          // Supabase hatası: Pending sync'e ekle
          await _syncManager.addPendingSync(
            type: 'attendance',
            data: tempAttendance.toMap(),
            operation: 'create',
          );

          debugPrint('⚠️ Supabase hatası: Pending sync\'e eklendi');
        }
      } else {
        // 3. Offline: Pending sync'e ekle
        await _syncManager.addPendingSync(
          type: 'attendance',
          data: tempAttendance.toMap(),
          operation: 'create',
        );

        debugPrint('📵 Offline: Attendance pending sync\'e eklendi');
      }

      // Yevmiye girişi yapıldığında bugünün hatırlatıcısını iptal et
      final today = DateTime.now();
      if (DateFormatter.toIso8601Date(date) ==
          DateFormatter.toIso8601Date(today)) {
        try {
          await _notificationServiceV2.cancelNotification(1);
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

      // Rollback: Hive'dan sil
      if (tempAttendance != null) {
        final key =
            '${tempAttendance.workerId}_${DateFormatter.toIso8601Date(tempAttendance.date)}';
        await _hiveService.attendance.delete(key);
        debugPrint('🔄 Rollback: Attendance Hive\'dan silindi');
      }

      rethrow;
    }
  }
}
