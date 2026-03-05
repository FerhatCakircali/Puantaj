import '../../../../data/services/local_storage_service.dart';
import '../../services/worker_attendance_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../../../../services/notification_service.dart';

/// Çalışan dashboard iş mantığı kontrolcüsü
class WorkerDashboardController {
  final _localStorage = LocalStorageService.instance;
  final _attendanceService = WorkerAttendanceService();
  final _supabase = Supabase.instance.client;
  final _notificationService = NotificationService();

  /// Worker session bilgisini al
  Future<Map<String, String>?> getWorkerSession() async {
    return await _localStorage.getWorkerSession();
  }

  /// Bugün için yevmiye yapılmış mı kontrol et
  Future<bool> hasAttendanceToday(int workerId) async {
    try {
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Attendance tablosunda bugün için kayıt var mı?
      final attendanceResponse = await _supabase
          .from('attendance')
          .select('id')
          .eq('worker_id', workerId)
          .eq('date', todayStr)
          .maybeSingle();

      if (attendanceResponse != null) {
        debugPrint('✅ Bugün için attendance kaydı var');
        return true;
      }

      // Attendance_requests tablosunda bugün için kayıt var mı?
      final requestResponse = await _supabase
          .from('attendance_requests')
          .select('id')
          .eq('worker_id', workerId)
          .eq('date', todayStr)
          .maybeSingle();

      if (requestResponse != null) {
        debugPrint('✅ Bugün için attendance_request kaydı var');
        return true;
      }

      debugPrint('❌ Bugün için yevmiye kaydı yok');
      return false;
    } catch (e) {
      debugPrint('❌ hasAttendanceToday hata: $e');
      return false;
    }
  }

  /// Bildirimi iptal et
  Future<void> cancelNotification(int notificationId) async {
    try {
      await _notificationService.cancelNotification(notificationId);
      debugPrint('✅ Bildirim iptal edildi: $notificationId');
    } catch (e) {
      debugPrint('❌ Bildirim iptal hatası: $e');
    }
  }

  /// Dashboard verilerini yükler
  Future<DashboardData> loadDashboardData() async {
    final session = await _localStorage.getWorkerSession();
    if (session == null) {
      throw Exception('Oturum bulunamadı');
    }

    final workerId = int.parse(session['workerId']!);
    final userId = int.parse(session['userId']!);

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    // Mevcut ay istatistikleri
    final monthlyStats = await _attendanceService.getMonthlyStatsWithDates(
      workerId: workerId,
      monthStart: monthStart,
      monthEnd: monthEnd,
    );

    // Toplam ödemeler
    final totalPayments = await _attendanceService.getTotalPayments(workerId);

    // Bekleyen talepler
    final pendingCount = await _getPendingRequestsCount(workerId);

    // Okunmamış bildirimler
    final unreadNotifications = await _getUnreadNotificationsCount(workerId);

    // Bu hafta çalışılan günler
    final weeklyDays = await _getWeeklyDays(workerId);

    // Toplam çalışma günü
    final totalDays = await _getTotalWorkDays(workerId);

    // Son 3 ödeme
    final recentPayments = await _getRecentPayments(workerId, userId);

    // Aylık ortalama kazanç
    final monthlyAverage = await _getMonthlyAverage(workerId, userId);

    // Son 3 ay trendi
    final monthlyTrend = await _getMonthlyTrend(workerId);

    // Son aktiviteler
    final lastAttendance = await _getLastAttendance(workerId);
    final lastApproved = await _getLastApproved(workerId);
    final lastPayment = await _getLastPayment(workerId, userId);

    // Yaklaşan hatırlatıcılar
    final reminders = await _getUpcomingReminders(workerId);

    return DashboardData(
      workerId: workerId,
      monthlyStats: monthlyStats,
      totalPayments: totalPayments,
      pendingCount: pendingCount,
      unreadNotifications: unreadNotifications,
      weeklyDays: weeklyDays,
      totalDays: totalDays,
      recentPayments: recentPayments,
      monthlyAverage: monthlyAverage,
      monthlyTrend: monthlyTrend,
      lastAttendance: lastAttendance,
      lastApproved: lastApproved,
      lastPayment: lastPayment,
      reminders: reminders,
    );
  }

  /// Devam oranını hesaplar
  double calculateAttendanceRate(Map<String, dynamic> monthlyStats) {
    final fullDays = monthlyStats['total_full_days'] ?? 0;
    final halfDays = monthlyStats['total_half_days'] ?? 0;
    final absentDays = monthlyStats['total_absent_days'] ?? 0;

    final totalDays = fullDays + halfDays + absentDays;
    if (totalDays == 0) return 0.0;

    return (fullDays + halfDays * 0.5) / totalDays * 100;
  }

  // Bekleyen talepler sayısı
  Future<int> _getPendingRequestsCount(int workerId) async {
    try {
      final response = await _supabase
          .from('attendance_requests')
          .select('id')
          .eq('worker_id', workerId)
          .eq('request_status', 'pending');

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  // Okunmamış bildirimler
  Future<int> _getUnreadNotificationsCount(int workerId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('recipient_id', workerId)
          .eq('recipient_type', 'worker')
          .eq('is_read', false);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  // Bu hafta çalışılan günler
  Future<int> _getWeeklyDays(int workerId) async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartStr = weekStart.toIso8601String().split('T')[0];

      final response = await _supabase
          .from('attendance')
          .select('status')
          .eq('worker_id', workerId)
          .gte('date', weekStartStr);

      int count = 0;
      for (var item in response as List) {
        if (item['status'] == 'fullDay') {
          count += 1;
        } else if (item['status'] == 'halfDay') {
          count += 1;
        }
      }

      return count;
    } catch (e) {
      return 0;
    }
  }

  // Toplam çalışma günü
  Future<int> _getTotalWorkDays(int workerId) async {
    try {
      final response = await _supabase
          .from('attendance')
          .select('status')
          .eq('worker_id', workerId)
          .or('status.eq.fullDay,status.eq.halfDay');

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  // Son 3 ödeme
  Future<List<Map<String, dynamic>>> _getRecentPayments(
    int workerId,
    int userId,
  ) async {
    try {
      final response = await _supabase
          .from('payments')
          .select('payment_date, amount, full_days, half_days')
          .eq('worker_id', workerId)
          .eq('user_id', userId)
          .order('payment_date', ascending: false)
          .limit(3);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      return [];
    }
  }

  // Aylık ortalama kazanç
  Future<double> _getMonthlyAverage(int workerId, int userId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select('amount, payment_date')
          .eq('worker_id', workerId)
          .eq('user_id', userId);

      if ((response as List).isEmpty) return 0.0;

      // Ay bazında grupla
      final monthlyTotals = <String, double>{};
      for (var payment in response) {
        final date = DateTime.parse(payment['payment_date']);
        final monthKey = '${date.year}-${date.month}';
        monthlyTotals[monthKey] =
            (monthlyTotals[monthKey] ?? 0) +
            (payment['amount'] as num).toDouble();
      }

      final total = monthlyTotals.values.reduce((a, b) => a + b);
      return total / monthlyTotals.length;
    } catch (e) {
      return 0.0;
    }
  }

  // Son 3 ay trendi
  Future<List<Map<String, dynamic>>> _getMonthlyTrend(int workerId) async {
    try {
      final now = DateTime.now();
      final months = <Map<String, dynamic>>[];

      for (int i = 2; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthStart = DateTime(month.year, month.month, 1);
        final monthEnd = DateTime(month.year, month.month + 1, 0);

        final response = await _supabase
            .from('attendance')
            .select('status')
            .eq('worker_id', workerId)
            .gte('date', monthStart.toIso8601String().split('T')[0])
            .lte('date', monthEnd.toIso8601String().split('T')[0]);

        int fullDays = 0;
        int halfDays = 0;

        for (var item in response as List) {
          if (item['status'] == 'fullDay') {
            fullDays++;
          } else if (item['status'] == 'halfDay') {
            halfDays++;
          }
        }

        final monthNames = [
          'Oca',
          'Şub',
          'Mar',
          'Nis',
          'May',
          'Haz',
          'Tem',
          'Ağu',
          'Eyl',
          'Eki',
          'Kas',
          'Ara',
        ];

        months.add({
          'month_name': monthNames[month.month - 1],
          'full_days': fullDays,
          'half_days': halfDays,
        });
      }

      return months;
    } catch (e) {
      return [];
    }
  }

  // Son yevmiye girişi
  Future<DateTime?> _getLastAttendance(int workerId) async {
    try {
      final response = await _supabase
          .from('attendance')
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

  // Son onaylanan talep
  Future<DateTime?> _getLastApproved(int workerId) async {
    try {
      final response = await _supabase
          .from('attendance_requests')
          .select('reviewed_at')
          .eq('worker_id', workerId)
          .eq('request_status', 'approved')
          .order('reviewed_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null || response['reviewed_at'] == null) return null;
      return DateTime.parse(response['reviewed_at']);
    } catch (e) {
      return null;
    }
  }

  // Son ödeme
  Future<DateTime?> _getLastPayment(int workerId, int userId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select('payment_date')
          .eq('worker_id', workerId)
          .eq('user_id', userId)
          .order('payment_date', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return DateTime.parse(response['payment_date']);
    } catch (e) {
      return null;
    }
  }

  // Yaklaşan hatırlatıcılar
  Future<List<Map<String, dynamic>>> _getUpcomingReminders(int workerId) async {
    try {
      debugPrint('🔍 Hatırlatıcılar sorgulanıyor - workerId: $workerId');

      final now = DateTime.now();
      // Bugünün başlangıcını al (00:00:00)
      final todayStart = DateTime(now.year, now.month, now.day);
      debugPrint('🕐 Şu anki zaman: $now');
      debugPrint('📅 Bugünün başlangıcı: $todayStart');

      final response = await _supabase
          .from('employee_reminders')
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
          .limit(5);

      debugPrint('📊 Sorgu sonucu: ${response.length} hatırlatıcı bulundu');
      debugPrint('📋 Ham veri: $response');

      // Yönetici adını birleştir
      final reminders = <Map<String, dynamic>>[];
      for (var item in response as List) {
        final user = item['users'] as Map<String, dynamic>;
        final reminderData = {
          'reminder_date': item['reminder_date'],
          'message': item['message'],
          'manager_name': '${user['first_name']} ${user['last_name']}',
        };
        reminders.add(reminderData);
        debugPrint(
          '✅ Hatırlatıcı eklendi: ${reminderData['manager_name']} - ${reminderData['message']}',
        );
      }

      debugPrint('🎯 Toplam ${reminders.length} hatırlatıcı döndürülüyor');
      return reminders;
    } catch (e, stackTrace) {
      debugPrint('❌ Hatırlatıcılar yüklenemedi: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }
}

/// Dashboard veri modeli
class DashboardData {
  final int workerId;
  final Map<String, dynamic> monthlyStats;
  final double totalPayments;
  final int pendingCount;
  final int unreadNotifications;
  final int weeklyDays;
  final int totalDays;
  final List<Map<String, dynamic>> recentPayments;
  final double monthlyAverage;
  final List<Map<String, dynamic>> monthlyTrend;
  final DateTime? lastAttendance;
  final DateTime? lastApproved;
  final DateTime? lastPayment;
  final List<Map<String, dynamic>> reminders;

  DashboardData({
    required this.workerId,
    required this.monthlyStats,
    required this.totalPayments,
    required this.pendingCount,
    required this.unreadNotifications,
    required this.weeklyDays,
    required this.totalDays,
    required this.recentPayments,
    required this.monthlyAverage,
    required this.monthlyTrend,
    this.lastAttendance,
    this.lastApproved,
    this.lastPayment,
    required this.reminders,
  });
}
