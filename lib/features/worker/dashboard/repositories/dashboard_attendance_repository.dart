import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/dashboard_constants.dart';

/// Dashboard devam verileri repository'si
///
/// Devam kayıtları ve talepleri ile ilgili veritabanı işlemlerini yönetir.
class DashboardAttendanceRepository {
  final _supabase = Supabase.instance.client;

  /// Bugün için devam kaydı var mı kontrol eder
  Future<bool> hasAttendanceToday(int workerId) async {
    try {
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final attendanceResponse = await _supabase
          .from(DashboardConstants.attendanceTable)
          .select('id')
          .eq('worker_id', workerId)
          .eq('date', todayStr)
          .maybeSingle();

      if (attendanceResponse != null) {
        return true;
      }

      final requestResponse = await _supabase
          .from(DashboardConstants.attendanceRequestsTable)
          .select('id')
          .eq('worker_id', workerId)
          .eq('date', todayStr)
          .maybeSingle();

      return requestResponse != null;
    } catch (e) {
      return false;
    }
  }

  /// Bekleyen talep sayısını getirir
  Future<int> getPendingRequestsCount(int workerId) async {
    try {
      final response = await _supabase
          .from(DashboardConstants.attendanceRequestsTable)
          .select('id')
          .eq('worker_id', workerId)
          .eq('request_status', DashboardConstants.requestStatusPending);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Bu hafta çalışılan gün sayısını getirir
  Future<int> getWeeklyDays(int workerId) async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartStr = weekStart.toIso8601String().split('T')[0];

      final response = await _supabase
          .from(DashboardConstants.attendanceTable)
          .select('status')
          .eq('worker_id', workerId)
          .gte('date', weekStartStr);

      int count = 0;
      for (var item in response as List) {
        if (item['status'] == DashboardConstants.statusFullDay ||
            item['status'] == DashboardConstants.statusHalfDay) {
          count++;
        }
      }

      return count;
    } catch (e) {
      return 0;
    }
  }

  /// Toplam çalışma günü sayısını getirir
  Future<int> getTotalWorkDays(int workerId) async {
    try {
      final response = await _supabase
          .from(DashboardConstants.attendanceTable)
          .select('status')
          .eq('worker_id', workerId)
          .or(
            'status.eq.${DashboardConstants.statusFullDay},status.eq.${DashboardConstants.statusHalfDay}',
          );

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Son 3 ay devam trendini getirir
  Future<List<Map<String, dynamic>>> getMonthlyTrend(int workerId) async {
    try {
      final now = DateTime.now();
      final months = <Map<String, dynamic>>[];

      for (int i = DashboardConstants.monthlyTrendMonths - 1; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthStart = DateTime(month.year, month.month, 1);
        final monthEnd = DateTime(month.year, month.month + 1, 0);

        final response = await _supabase
            .from(DashboardConstants.attendanceTable)
            .select('status')
            .eq('worker_id', workerId)
            .gte('date', monthStart.toIso8601String().split('T')[0])
            .lte('date', monthEnd.toIso8601String().split('T')[0]);

        int fullDays = 0;
        int halfDays = 0;

        for (var item in response as List) {
          if (item['status'] == DashboardConstants.statusFullDay) {
            fullDays++;
          } else if (item['status'] == DashboardConstants.statusHalfDay) {
            halfDays++;
          }
        }

        months.add({
          'month_name': DashboardConstants.monthNames[month.month - 1],
          'full_days': fullDays,
          'half_days': halfDays,
        });
      }

      return months;
    } catch (e) {
      return [];
    }
  }

  /// Son devam kaydı tarihini getirir
  Future<DateTime?> getLastAttendance(int workerId) async {
    try {
      final response = await _supabase
          .from(DashboardConstants.attendanceTable)
          .select('date')
          .eq('worker_id', workerId)
          .order('date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return DateTime.parse(response['date']);
    } catch (e) {
      return null;
    }
  }

  /// Son onaylanan talep tarihini getirir
  Future<DateTime?> getLastApproved(int workerId) async {
    try {
      final response = await _supabase
          .from(DashboardConstants.attendanceRequestsTable)
          .select('reviewed_at')
          .eq('worker_id', workerId)
          .eq('request_status', DashboardConstants.requestStatusApproved)
          .order('reviewed_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null || response['reviewed_at'] == null) return null;
      return DateTime.parse(response['reviewed_at']);
    } catch (e) {
      return null;
    }
  }

  /// Yaklaşan hatırlatıcıları getirir
  Future<List<Map<String, dynamic>>> getUpcomingReminders(int workerId) async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      final response = await _supabase
          .from(DashboardConstants.employeeRemindersTable)
          .select('''
            reminder_date,
            message,
            user_id,
            is_completed,
            worker_id,
            users!inner(first_name, last_name)
          ''')
          .eq('worker_id', workerId)
          .eq('is_completed', false)
          .gte('reminder_date', todayStart.toIso8601String())
          .order('reminder_date', ascending: true)
          .limit(DashboardConstants.upcomingRemindersLimit);

      final reminders = <Map<String, dynamic>>[];
      for (var item in response as List) {
        final user = item['users'] as Map<String, dynamic>;
        reminders.add({
          'reminder_date': item['reminder_date'],
          'message': item['message'],
          'manager_name': '${user['first_name']} ${user['last_name']}',
        });
      }

      return reminders;
    } catch (e) {
      return [];
    }
  }
}
