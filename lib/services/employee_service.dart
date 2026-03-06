import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import '../models/employee.dart';
import '../core/app_globals.dart';
import '../utils/date_formatter.dart';
import '../core/error_logger.dart';

class EmployeeService {
  final AuthService _authService = AuthService();

  Future<List<Employee>> getEmployees() async {
    final userId = await _authService.getUserId();
    if (userId == null) return [];

    final res = await supabase
        .from('workers')
        .select()
        .eq('user_id', userId)
        .order('full_name');

    return res.map((map) => Employee.fromMap(map)).toList();
  }

  Future<int> addEmployee(Employee employee) async {
    final userId = await _authService.getUserId();
    if (userId == null) return -1;

    final map = employee.toMap();
    map['user_id'] = userId;

    try {
      final result = await supabase
          .from('workers')
          .insert(map)
          .select('id')
          .single();

      return result['id'];
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'EmployeeService.addEmployee hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return -1;
    }
  }

  Future<int> updateEmployee(Employee employee) async {
    final userId = await _authService.getUserId();
    if (userId == null) return -1;

    try {
      await supabase
          .from('workers')
          .update(employee.toMap())
          .eq('id', employee.id)
          .eq('user_id', userId);

      return 1;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'EmployeeService.updateEmployee hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return -1;
    }
  }

  Future<int> deleteEmployee(int id) async {
    final userId = await _authService.getUserId();
    if (userId == null) return -1;

    try {
      await supabase
          .from('workers')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);

      return 1;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'EmployeeService.deleteEmployee hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return -1;
    }
  }

  Future<int> deleteAllEmployees() async {
    final userId = await _authService.getUserId();
    if (userId == null) return -1;

    try {
      // İlişkili kayıtları da sil (cascading delete yerine manuel silme)
      await supabase.from('paid_days').delete().eq('user_id', userId);

      await supabase.from('payments').delete().eq('user_id', userId);

      await supabase.from('attendance').delete().eq('user_id', userId);

      await supabase.from('workers').delete().eq('user_id', userId);

      return 1;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'EmployeeService.deleteAllEmployees hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return -1;
    }
  }

  // Belirlenen tarihten öncesinde herhangi bir devam kaydı veya ödeme kaydı var mı kontrol et
  Future<bool> hasRecordsBeforeDate(int workerId, DateTime date) async {
    final userId = await _authService.getUserId();
    if (userId == null) return false;

    final formattedDate = DateFormatter.toIso8601Date(date);

    try {
      // Devam kayıtlarını kontrol et
      final attendanceResults = await supabase
          .from('attendance')
          .select()
          .eq('user_id', userId)
          .eq('worker_id', workerId)
          .lt('date', formattedDate)
          .limit(1);

      if (attendanceResults.isNotEmpty) {
        return true;
      }

      // Ödeme kayıtlarını kontrol et
      final paymentResults = await supabase
          .from('paid_days')
          .select()
          .eq('user_id', userId)
          .eq('worker_id', workerId)
          .lt('date', formattedDate)
          .limit(1);

      return paymentResults.isNotEmpty;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'EmployeeService.hasRecordsBeforeDate hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  // Belirlenen tarihten önce olan tüm kayıtları sil
  Future<void> deleteRecordsBeforeDate(int workerId, DateTime date) async {
    final userId = await _authService.getUserId();
    if (userId == null) return;

    final formattedDate = DateFormatter.toIso8601Date(date);

    try {
      // 1. Önce devam kayıtlarını sil
      // ignore: unused_local_variable
      final attendanceResponse = await supabase
          .from('attendance')
          .delete()
          .eq('user_id', userId)
          .eq('worker_id', workerId)
          .lt('date', formattedDate);

      debugPrint("Devam kayıtları silindi");

      // 2. Ödemesi yapılmış günleri sil
      // ignore: unused_local_variable
      final paidDaysResponse = await supabase
          .from('paid_days')
          .delete()
          .eq('user_id', userId)
          .eq('worker_id', workerId)
          .lt('date', formattedDate);

      debugPrint("Ödenmiş günler silindi");

      // 3. Belirli tarihten önceki ödeme kayıtlarını doğrudan sil
      // ignore: unused_local_variable
      final paymentsResponse = await supabase
          .from('payments')
          .delete()
          .eq('user_id', userId)
          .eq('worker_id', workerId)
          .lt('payment_date', formattedDate);

      debugPrint("Ödeme kayıtları silindi");

      // 4. Sahipsiz ödeme kayıtlarını sil
      await _deleteOrphanedPayments(userId, workerId);

      // 5. Kalan ödemeleri güncelle
      await _updateRemainingPayments(userId, workerId);

      debugPrint(
        "$workerId ID'li çalışanın $formattedDate tarihinden önceki kayıtları silindi",
      );
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'EmployeeService.deleteRecordsBeforeDate hatası',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // Sahipsiz ödeme kayıtlarını silen yardımcı metod
  Future<void> _deleteOrphanedPayments(int userId, int workerId) async {
    try {
      // paid_days tablosunda hiç kaydı olmayan payment_id'leri bul
      final orphanedPayments = await supabase
          .from('payments')
          .select('id')
          .eq('user_id', userId)
          .eq('worker_id', workerId);

      if (orphanedPayments.isEmpty) return;

      List<int> paymentIds = orphanedPayments
          .map<int>((p) => p['id'] as int)
          .toList();

      for (final paymentId in paymentIds) {
        // Her ödeme için bağlı paid_days kayıtlarını kontrol et
        final paidDays = await supabase
            .from('paid_days')
            .select()
            .eq('payment_id', paymentId)
            .limit(1);

        // Hiç paid_days kaydı yoksa, bu ödemeyi sil
        if (paidDays.isEmpty) {
          await supabase.from('payments').delete().eq('id', paymentId);

          debugPrint("Sahipsiz ödeme kaydı silindi: $paymentId");
        }
      }
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'EmployeeService._deleteOrphanedPayments hatası',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // Kalan ödemelerin gün sayılarını güncelleyen yardımcı metod
  Future<void> _updateRemainingPayments(int userId, int workerId) async {
    try {
      // Tüm ödemeleri al
      final payments = await supabase
          .from('payments')
          .select('id')
          .eq('user_id', userId)
          .eq('worker_id', workerId);

      for (final payment in payments) {
        final paymentId = payment['id'] as int;

        // Bu ödeme için tam gün sayısını hesapla
        final fullDaysResult = await supabase
            .from('paid_days')
            .select()
            .eq('payment_id', paymentId)
            .eq('status', 'fullDay');

        final fullDays = fullDaysResult.length;

        // Bu ödeme için yarım gün sayısını hesapla
        final halfDaysResult = await supabase
            .from('paid_days')
            .select()
            .eq('payment_id', paymentId)
            .eq('status', 'halfDay');

        final halfDays = halfDaysResult.length;

        // Ödemeyi güncelle
        await supabase
            .from('payments')
            .update({'full_days': fullDays, 'half_days': halfDays})
            .eq('id', paymentId);

        debugPrint(
          "Ödeme kaydı güncellendi: $paymentId (Tam: $fullDays, Yarım: $halfDays)",
        );
      }
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'EmployeeService._updateRemainingPayments hatası',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
