import '../models/attendance.dart';
import 'auth_service.dart';
import 'db_service.dart';
import 'payment_service.dart';
import '../main.dart';

class AttendanceService {
  final AuthService _authService = AuthService();
  final AppDatabase _db = AppDatabase();
  final PaymentService _paymentService = PaymentService();

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<List<Attendance>> getAttendanceByDate(DateTime date) async {
    final userId = await _authService.getUserId();
    if (userId == null) return [];

    final formattedDate = _formatDate(date);

    final results = await supabase
        .from('attendance')
        .select()
        .eq('user_id', userId)
        .like('date', '$formattedDate%');

    return results.map((map) => Attendance.fromMap(map)).toList();
  }

  Future<Map<String, int>> _checkPaymentStatus(
    int workerId,
    DateTime date,
  ) async {
    final userId = await _authService.getUserId();
    if (userId == null) return {'fullDay': 0, 'halfDay': 0};

    final formattedDate = _formatDate(date);

    // Devam durumunu kontrol et
    final attendanceResults = await supabase
        .from('attendance')
        .select('status')
        .eq('user_id', userId)
        .eq('worker_id', workerId)
        .like('date', '$formattedDate%')
        .maybeSingle();

    if (attendanceResults == null) {
      return {'fullDay': 0, 'halfDay': 0};
    }

    final currentStatus = attendanceResults['status'] as String;

    // Toplam ödeme bilgilerini al
    final paymentResults = await supabase
        .from('payments')
        .select('full_days, half_days')
        .eq('worker_id', workerId)
        .eq('user_id', userId);

    int paidFullDays = 0;
    int paidHalfDays = 0;

    for (final payment in paymentResults) {
      paidFullDays += payment['full_days'] as int? ?? 0;
      paidHalfDays += payment['half_days'] as int? ?? 0;
    }

    // Toplam devam bilgilerini al
    final fullDaysResult = await supabase
        .from('attendance')
        .select()
        .eq('worker_id', workerId)
        .eq('user_id', userId)
        .eq('status', 'fullDay');

    final halfDaysResult = await supabase
        .from('attendance')
        .select()
        .eq('worker_id', workerId)
        .eq('user_id', userId)
        .eq('status', 'halfDay');

    final totalFullDays = fullDaysResult.length;
    final totalHalfDays = halfDaysResult.length;

    final isFullDayPaid =
        paidFullDays >= totalFullDays && currentStatus == 'fullDay';
    final isHalfDayPaid =
        paidHalfDays >= totalHalfDays && currentStatus == 'halfDay';

    return {'fullDay': isFullDayPaid ? 1 : 0, 'halfDay': isHalfDayPaid ? 1 : 0};
  }

  Future<void> markAttendance({
    required int workerId,
    required DateTime date,
    required AttendanceStatus status,
  }) async {
    final userId = await _authService.getUserId();
    if (userId == null) return;

    final formattedDate = _formatDate(date);

    // Önce mevcut kaydı kontrol et
    final existingRecord = await supabase
        .from('attendance')
        .select()
        .eq('user_id', userId)
        .eq('worker_id', workerId)
        .like('date', '$formattedDate%')
        .maybeSingle();

    // Eğer mevcut bir kayıt varsa, ödenip ödenmediğini kontrol et
    if (existingRecord != null) {
      final currentStatusStr = existingRecord['status'] as String;
      final currentStatus = _statusFromString(currentStatusStr);

      // Eğer mevcut durum ile yeni durum farklıysa
      if (currentStatus != status) {
        // Mevcut durumun ödenip ödenmediğini kontrol et
        final isPaid = await _paymentService.isDayPaid(
          workerId,
          DateTime.parse(formattedDate),
          currentStatus,
        );

        // Eğer mevcut durum ödenmişse, değişikliğe izin verme
        if (isPaid) {
          return; // Ödenen günün durumu değiştirilemez
        }
      }

      // Mevcut kaydı güncelle
      await supabase
          .from('attendance')
          .update({'status': _statusToString(status)})
          .eq('id', existingRecord['id']);
    } else {
      // Yeni kayıt ekle
      await supabase
          .from('attendance')
          .insert({
            'user_id': userId,
            'worker_id': workerId,
            'date': formattedDate,
            'status': _statusToString(status),
          });
    }
  }

  Future<List<Attendance>> getAttendanceBetween(
    DateTime startDate,
    DateTime endDate, {
    int? workerId,
  }) async {
    final userId = await _authService.getUserId();
    if (userId == null) return [];

    final start = _formatDate(startDate);
    final end = _formatDate(endDate);

    var query = supabase
        .from('attendance')
        .select()
        .eq('user_id', userId)
        .gte('date', start)
        .lte('date', end);

    if (workerId != null) {
      query = query.eq('worker_id', workerId);
    }

    final maps = await query;
    return List.generate(maps.length, (i) => Attendance.fromMap(maps[i]));
  }

  Future<void> deleteAttendance(int id) async {
    final userId = await _authService.getUserId();
    if (userId == null) return;

    await supabase
        .from('attendance')
        .delete()
        .eq('id', id)
        .eq('user_id', userId);
  }

  String _statusToString(AttendanceStatus status) {
    return switch (status) {
      AttendanceStatus.halfDay => 'halfDay',
      AttendanceStatus.fullDay => 'fullDay',
      AttendanceStatus.absent => 'absent',
    };
  }

  AttendanceStatus _statusFromString(String status) {
    return switch (status) {
      'halfDay' => AttendanceStatus.halfDay,
      'fullDay' => AttendanceStatus.fullDay,
      _ => AttendanceStatus.absent,
    };
  }
}
