import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/attendance.dart';

/// Çalışan yevmiye servisi
///
/// SQL fonksiyonları:
/// - check_worker_today_attendance_status: Bugünün durumunu kontrol et
/// - get_worker_attendance_history: Geçmiş kayıtları getir
/// - get_worker_monthly_stats: Aylık istatistikler
/// - get_worker_total_payments: Toplam kazanç
class WorkerAttendanceService {
  SupabaseClient get supabase => Supabase.instance.client;

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Bugün için yevmiye durumunu kontrol et
  Future<Map<String, dynamic>?> checkTodayStatus(int workerId) async {
    try {
      final today = _formatDate(DateTime.now());

      final response = await supabase.rpc(
        'check_worker_today_attendance_status',
        params: {'worker_id_param': workerId, 'check_date': today},
      );

      if (response == null || response.isEmpty) return null;

      return response[0] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ checkTodayStatus hata: $e');
      return null;
    }
  }

  /// Yevmiye talebi gönder
  ///
  /// Database trigger otomatik olarak:
  /// 1. notifications tablosuna kayıt ekler (scheduled_time = NULL)
  /// 2. FCM ile ANINDA bildirim gönderilir
  /// 3. Uygulama açıksa Realtime, kapalıysa Push Notification
  Future<bool> submitAttendanceRequest({
    required int workerId,
    int? userId,
    required DateTime date,
    required AttendanceStatus status,
    String? workerName,
  }) async {
    try {
      final formattedDate = _formatDate(date);

      // Çalışanın yöneticisini workers tablosundan al
      final workerData = await supabase
          .from('workers')
          .select('user_id, full_name')
          .eq('id', workerId)
          .single();

      final managerId = workerData['user_id'] as int;
      final effectiveWorkerName =
          workerName ?? (workerData['full_name'] as String);

      debugPrint('👤 Çalışan ID: $workerId');
      debugPrint('👔 Yönetici ID: $managerId');
      debugPrint('📝 Çalışan Adı: $effectiveWorkerName');

      // Reddedilen talep varsa sil
      final existingRequest = await supabase
          .from('attendance_requests')
          .select('id, request_status')
          .eq('worker_id', workerId)
          .eq('date', formattedDate)
          .maybeSingle();

      if (existingRequest != null &&
          existingRequest['request_status'] == 'rejected') {
        await supabase
            .from('attendance_requests')
            .delete()
            .eq('id', existingRequest['id']);

        debugPrint('✅ Reddedilen talep silindi');
      }

      // Yeni talep oluştur (trigger çalışacak)
      final response = await supabase
          .from('attendance_requests')
          .insert({
            'worker_id': workerId,
            'user_id': managerId,
            'date': formattedDate,
            'status': status.name,
          })
          .select()
          .single();

      final requestId = response['id'] as int;

      debugPrint('✅ Yeni yevmiye talebi gönderildi (ID: $requestId)');
      debugPrint('📬 Database trigger notifications tablosuna kayıt ekleyecek');
      debugPrint('⚡ FCM ile ANINDA bildirim gönderilecek');
      debugPrint('📡 Uygulama açıksa Realtime, kapalıysa Push Notification');

      return true;
    } catch (e) {
      debugPrint('❌ submitAttendanceRequest hata: $e');
      return false;
    }
  }

  /// Geçmiş yevmiye kayıtlarını getir
  Future<List<Map<String, dynamic>>> getAttendanceHistory({
    required int workerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await supabase.rpc(
        'get_worker_attendance_history',
        params: {
          'worker_id_param': workerId,
          'start_date': _formatDate(startDate),
          'end_date': _formatDate(endDate),
        },
      );

      if (response == null) return [];

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ getAttendanceHistory hata: $e');
      return [];
    }
  }

  /// Aylık istatistikleri getir
  Future<Map<String, dynamic>?> getMonthlyStats({
    required int workerId,
    required DateTime monthStart,
    required DateTime monthEnd,
  }) async {
    try {
      final response = await supabase.rpc(
        'get_worker_monthly_stats',
        params: {
          'worker_id_param': workerId,
          'month_start': _formatDate(monthStart),
          'month_end': _formatDate(monthEnd),
        },
      );

      if (response == null || response.isEmpty) return null;

      return response[0] as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ getMonthlyStats hata: $e');
      return null;
    }
  }

  /// Aylık detaylı istatistikleri getir (tarihlerle birlikte)
  Future<Map<String, dynamic>> getMonthlyStatsWithDates({
    required int workerId,
    required DateTime monthStart,
    required DateTime monthEnd,
  }) async {
    try {
      final workerResponse = await supabase
          .from('workers')
          .select('start_date')
          .eq('id', workerId)
          .maybeSingle();

      DateTime? workerStartDate;
      if (workerResponse != null && workerResponse['start_date'] != null) {
        workerStartDate = DateTime.parse(workerResponse['start_date']);
      }

      final response = await supabase
          .from('attendance')
          .select('date, status')
          .eq('worker_id', workerId)
          .gte('date', _formatDate(monthStart))
          .lte('date', _formatDate(monthEnd))
          .order('date', ascending: true);

      final List<Map<String, dynamic>> records =
          List<Map<String, dynamic>>.from(response);

      final fullDayDates = <String>[];
      final halfDayDates = <String>[];
      final absentDates = <String>[];

      final workedDates = <String>{};
      for (final record in records) {
        final date = record['date'] as String;
        final status = record['status'] as String;

        workedDates.add(date);

        if (status == 'fullDay') {
          fullDayDates.add(date);
        } else if (status == 'halfDay') {
          halfDayDates.add(date);
        }
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final endDate = monthEnd.isAfter(today) ? today : monthEnd;

      var startDate = monthStart;
      if (workerStartDate != null) {
        final workerStartDateOnly = DateTime(
          workerStartDate.year,
          workerStartDate.month,
          workerStartDate.day,
        );
        if (workerStartDateOnly.isAfter(startDate)) {
          startDate = workerStartDateOnly;
        }
      }

      var date = startDate;
      while (date.isBefore(endDate) || date.isAtSameMomentAs(endDate)) {
        final dateStr = _formatDate(date);
        if (!workedDates.contains(dateStr)) {
          absentDates.add(dateStr);
        }
        date = date.add(const Duration(days: 1));
      }

      final paymentsResponse = await supabase
          .from('payments')
          .select('amount')
          .eq('worker_id', workerId)
          .gte('payment_date', _formatDate(monthStart))
          .lte('payment_date', _formatDate(monthEnd));

      double totalAmount = 0.0;
      for (final payment in paymentsResponse) {
        totalAmount += (payment['amount'] as num).toDouble();
      }

      return {
        'total_full_days': fullDayDates.length,
        'total_half_days': halfDayDates.length,
        'total_absent_days': absentDates.length,
        'total_amount': totalAmount,
        'full_day_dates': fullDayDates,
        'half_day_dates': halfDayDates,
        'absent_dates': absentDates,
      };
    } catch (e) {
      debugPrint('❌ getMonthlyStatsWithDates hata: $e');
      return {
        'total_full_days': 0,
        'total_half_days': 0,
        'total_absent_days': 0,
        'total_amount': 0.0,
        'full_day_dates': <String>[],
        'half_day_dates': <String>[],
        'absent_dates': <String>[],
      };
    }
  }

  /// Toplam kazancı getir
  Future<double> getTotalPayments(int workerId) async {
    try {
      final response = await supabase.rpc(
        'get_worker_total_payments',
        params: {'worker_id_param': workerId},
      );

      if (response == null) return 0.0;

      return double.tryParse(response.toString()) ?? 0.0;
    } catch (e) {
      debugPrint('❌ getTotalPayments hata: $e');
      return 0.0;
    }
  }

  /// Reddedilen talebi sil
  Future<bool> deleteRejectedRequest({
    required int workerId,
    required DateTime date,
  }) async {
    try {
      final formattedDate = _formatDate(date);

      await supabase
          .from('attendance_requests')
          .delete()
          .eq('worker_id', workerId)
          .eq('date', formattedDate)
          .eq('request_status', 'rejected');

      debugPrint('✅ Reddedilen talep silindi');
      return true;
    } catch (e) {
      debugPrint('❌ deleteRejectedRequest hata: $e');
      return false;
    }
  }

  /// Ödeme geçmişini getir (avans bilgisi ile)
  Future<List<Map<String, dynamic>>> getPaymentHistory({
    required int workerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await supabase
          .from('payments')
          .select('*')
          .eq('worker_id', workerId)
          .gte('payment_date', _formatDate(startDate))
          .lte('payment_date', _formatDate(endDate))
          .order('created_at', ascending: false);

      final payments = List<Map<String, dynamic>>.from(response);

      // Her ödeme için avans bilgisini ekle
      for (var payment in payments) {
        final paymentId = payment['id'];

        // Bu ödemeden düşülen avansları getir
        final advances = await supabase
            .from('advances')
            .select('amount, description')
            .eq('deducted_from_payment_id', paymentId);

        if (advances.isNotEmpty) {
          final totalAdvance = advances.fold<double>(
            0.0,
            (sum, adv) => sum + (adv['amount'] as num).toDouble(),
          );
          payment['advance_deducted'] = totalAdvance;
          payment['advance_count'] = advances.length;
        } else {
          payment['advance_deducted'] = 0.0;
          payment['advance_count'] = 0;
        }
      }

      return payments;
    } catch (e) {
      debugPrint('❌ getPaymentHistory hata: $e');
      return [];
    }
  }

  /// Avans geçmişini getir
  Future<List<Map<String, dynamic>>> getAdvanceHistory({
    required int workerId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await supabase
          .from('advances')
          .select('*')
          .eq('worker_id', workerId)
          .gte('advance_date', _formatDate(startDate))
          .lte('advance_date', _formatDate(endDate))
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ getAdvanceHistory hata: $e');
      return [];
    }
  }      return payments;
    } catch (e) {
      debugPrint('❌ getPaymentHistory hata: $e');
      return [];
    }
  }

  /// Ödeme detaylarını getir
  Future<Map<String, dynamic>?> getPaymentDetails(int paymentId) async {
    try {
      final payment = await supabase
          .from('payments')
          .select('*')
          .eq('id', paymentId)
          .maybeSingle();

      if (payment == null) return null;

      final workerId = payment['worker_id'] as int;
      final paymentDate = DateTime.parse(payment['payment_date']);

      final startDate = paymentDate.subtract(const Duration(days: 30));

      final attendanceRecords = await supabase
          .from('attendance')
          .select('date, status')
          .eq('worker_id', workerId)
          .gte('date', _formatDate(startDate))
          .lte('date', _formatDate(paymentDate))
          .order('date', ascending: true);

      return {'payment': payment, 'attendance_records': attendanceRecords};
    } catch (e) {
      debugPrint('❌ getPaymentDetails hata: $e');
      return null;
    }
  }
}
