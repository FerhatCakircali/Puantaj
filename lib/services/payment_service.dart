import '../models/payment.dart';
import 'auth_service.dart';
import 'db_service.dart';
import '../models/attendance.dart';
import '../main.dart';

class PaymentService {
  final _db = AppDatabase();
  final _authService = AuthService();

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> addPayment(Payment payment) async {
    // Ödeme kaydını ekle
    final paymentResponse = await supabase
        .from('payments')
        .insert(payment.toMap())
        .select('id')
        .single();
    
    final paymentId = paymentResponse['id'];

    // Ödeme yapılan çalışan için henüz ödenmemiş günleri al
    final attendance = await _getUnpaidAttendanceForWorker(payment.workerId);

    // Ödenecek tam ve yarım günlerin sayısı
    int fullDaysToMark = payment.fullDays;
    int halfDaysToMark = payment.halfDays;

    // Hangi günlerin ödendiğini kaydet
    for (var record in attendance) {
      if (record.status == AttendanceStatus.fullDay && fullDaysToMark > 0) {
        // Bu tam günü ödenmiş olarak işaretle
        await _markDayAsPaid(record, paymentId);
        fullDaysToMark--;
      } else if (record.status == AttendanceStatus.halfDay &&
          halfDaysToMark > 0) {
        // Bu yarım günü ödenmiş olarak işaretle
        await _markDayAsPaid(record, paymentId);
        halfDaysToMark--;
      }

      // Tüm günler işaretlendiyse döngüden çık
      if (fullDaysToMark <= 0 && halfDaysToMark <= 0) break;
    }
  }

  Future<void> _markDayAsPaid(Attendance record, int paymentId) async {
    final userId = await _authService.getUserId();
    if (userId == null) return;

    // paid_days tablosuna kaydı ekle
    await supabase.from('paid_days').insert({
      'user_id': userId,
      'worker_id': record.workerId,
      'date': _formatDate(record.date),
      'status':
          record.status == AttendanceStatus.fullDay ? 'fullDay' : 'halfDay',
      'payment_id': paymentId,
    });
  }

  Future<List<Attendance>> _getUnpaidAttendanceForWorker(int workerId) async {
    final userId = await _authService.getUserId();
    if (userId == null) return [];

    // Tüm devamsızlık kayıtlarını al
    final allAttendanceResults = await supabase
        .from('attendance')
        .select()
        .eq('worker_id', workerId)
        .eq('user_id', userId)
        .or('status.eq.fullDay,status.eq.halfDay')
        .order('date');

    // Tüm ödenmiş günleri al
    final paidDaysResults = await supabase
        .from('paid_days')
        .select('date, status')
        .eq('worker_id', workerId)
        .eq('user_id', userId);

    // Ödenmiş günlerin listesini oluştur
    final paidDays = paidDaysResults
        .map((row) => {
                'date': row['date'] as String,
                'status': row['status'] as String,
            })
            .toList();

    // Ödenmemiş kayıtları filtrele
    final unpaidAttendance = allAttendanceResults
            .where((record) {
              final recordDate = _formatDate(
                DateTime.parse(record['date'] as String),
              );
              final recordStatus = record['status'] as String;

              // Bu gün ve durum için ödeme yapılıp yapılmadığını kontrol et
              return !paidDays.any(
                (paidDay) =>
                    paidDay['date'] == recordDate &&
                    paidDay['status'] == recordStatus,
              );
            })
            .map((map) => Attendance.fromMap(map))
            .toList();

    return unpaidAttendance;
  }

  Future<List<Payment>> getPaymentsByWorker(int workerId) async {
    final currentUser = await _authService.currentUser;
    if (currentUser == null) return [];

    final maps = await supabase
        .from('payments')
        .select()
        .eq('worker_id', workerId)
        .eq('user_id', currentUser['id']);

    return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
  }

  Future<List<Payment>> getPaymentsByWorkerId(int workerId) async {
    final userId = await _authService.getUserId();
    if (userId == null) return [];

    final maps = await supabase
        .from('payments')
        .select()
        .eq('worker_id', workerId)
        .eq('user_id', userId)
        .order('payment_date', ascending: false);

    return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
  }

  Future<Map<String, int>> getUnpaidDays(int workerId) async {
    // Ödenmemiş yevmiye kayıtlarını al
    final unpaidAttendance = await _getUnpaidAttendanceForWorker(workerId);

    // Ödenmemiş tam ve yarım günleri say
    int fullDays = 0;
    int halfDays = 0;

    for (var record in unpaidAttendance) {
      if (record.status == AttendanceStatus.fullDay) {
        fullDays++;
      } else if (record.status == AttendanceStatus.halfDay) {
        halfDays++;
      }
    }

    return {'fullDays': fullDays, 'halfDays': halfDays};
  }

  // Belirli bir günün ödenmiş olup olmadığını kontrol et
  Future<bool> isDayPaid(
    int workerId,
    DateTime date,
    AttendanceStatus status,
  ) async {
    final userId = await _authService.getUserId();
    if (userId == null) return false;

    final formattedDate = _formatDate(date);
    final statusStr =
        status == AttendanceStatus.fullDay ? 'fullDay' : 'halfDay';

    final results = await supabase
        .from('paid_days')
        .select()
        .eq('worker_id', workerId)
        .eq('user_id', userId)
        .eq('date', formattedDate)
        .eq('status', statusStr);

    return results.isNotEmpty;
  }
}
