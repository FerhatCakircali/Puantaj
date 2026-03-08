import '../../../models/attendance.dart';
import '../../../core/repositories/base_supabase_repository.dart';
import '../../../utils/date_formatter.dart';
import '../constants/payment_constants.dart';

/// Ödenmiş günleri yöneten repository sınıfı
class PaidDaysRepository extends BaseSupabaseRepository {
  PaidDaysRepository(super.supabase);

  /// Günü ödenmiş olarak işaretler
  ///
  /// [userId] Kullanıcı ID'si
  /// [workerId] Çalışan ID'si
  /// [date] Tarih
  /// [status] Durum (fullDay/halfDay)
  /// [paymentId] Ödeme ID'si
  Future<void> markDayAsPaid({
    required int userId,
    required int workerId,
    required DateTime date,
    required String status,
    required int paymentId,
  }) async {
    return executeQueryWithThrow(() async {
      await supabase.from(PaymentConstants.paidDaysTable).insert({
        PaymentConstants.userIdColumn: userId,
        PaymentConstants.workerIdColumn: workerId,
        PaymentConstants.dateColumn: DateFormatter.toIso8601Date(date),
        PaymentConstants.statusColumn: status,
        PaymentConstants.paymentIdColumn: paymentId,
      });
    }, context: 'PaidDaysRepository.markDayAsPaid');
  }

  /// Çalışanın ödenmemiş günlerini getirir
  ///
  /// [userId] Kullanıcı ID'si
  /// [workerId] Çalışan ID'si
  /// Returns: Ödenmemiş devamsızlık listesi
  Future<List<Attendance>> getUnpaidAttendance({
    required int userId,
    required int workerId,
  }) async {
    return executeQuery(
      () async {
        final allAttendanceResults = await supabase
            .from(PaymentConstants.attendanceTable)
            .select()
            .eq(PaymentConstants.workerIdColumn, workerId)
            .eq(PaymentConstants.userIdColumn, userId)
            .or(
              'status.eq.${PaymentConstants.statusFullDay},status.eq.${PaymentConstants.statusHalfDay}',
            )
            .order(PaymentConstants.dateColumn);

        final paidDaysResults = await supabase
            .from(PaymentConstants.paidDaysTable)
            .select('date, status')
            .eq(PaymentConstants.workerIdColumn, workerId)
            .eq(PaymentConstants.userIdColumn, userId);

        final paidDays = paidDaysResults
            .map(
              (row) => {
                'date': row['date'] as String,
                'status': row['status'] as String,
              },
            )
            .toList();

        final unpaidAttendance = allAttendanceResults
            .where((record) {
              final recordDate = DateFormatter.toIso8601Date(
                DateTime.parse(record['date'] as String),
              );
              final recordStatus = record['status'] as String;

              return !paidDays.any(
                (paidDay) =>
                    paidDay['date'] == recordDate &&
                    paidDay['status'] == recordStatus,
              );
            })
            .map((map) => Attendance.fromMap(map))
            .toList();

        return unpaidAttendance;
      },
      [],
      context: 'PaidDaysRepository.getUnpaidAttendance',
    );
  }

  /// Belirli bir ödemeyi hariç tutarak ödenmemiş günleri getirir
  ///
  /// [userId] Kullanıcı ID'si
  /// [workerId] Çalışan ID'si
  /// [excludePaymentId] Hariç tutulacak ödeme ID'si
  /// Returns: Ödenmemiş gün sayıları
  Future<Map<String, int>> getUnpaidDaysExcludingPayment({
    required int userId,
    required int workerId,
    required int excludePaymentId,
  }) async {
    return executeQuery(
      () async {
        final allAttendanceResults = await supabase
            .from(PaymentConstants.attendanceTable)
            .select()
            .eq(PaymentConstants.workerIdColumn, workerId)
            .eq(PaymentConstants.userIdColumn, userId)
            .or(
              'status.eq.${PaymentConstants.statusFullDay},status.eq.${PaymentConstants.statusHalfDay}',
            )
            .order(PaymentConstants.dateColumn);

        final paidDaysResults = await supabase
            .from(PaymentConstants.paidDaysTable)
            .select('date, status')
            .eq(PaymentConstants.workerIdColumn, workerId)
            .eq(PaymentConstants.userIdColumn, userId)
            .neq(PaymentConstants.paymentIdColumn, excludePaymentId);

        final paidDays = paidDaysResults
            .map(
              (row) => {
                'date': row['date'] as String,
                'status': row['status'] as String,
              },
            )
            .toList();

        final unpaidAttendance = allAttendanceResults.where((record) {
          final recordDate = DateFormatter.toIso8601Date(
            DateTime.parse(record['date'] as String),
          );
          final recordStatus = record['status'] as String;

          return !paidDays.any(
            (paidDay) =>
                paidDay['date'] == recordDate &&
                paidDay['status'] == recordStatus,
          );
        }).toList();

        int fullDays = 0;
        int halfDays = 0;

        for (var record in unpaidAttendance) {
          final status = record['status'] as String;
          if (status == PaymentConstants.statusFullDay) {
            fullDays++;
          } else if (status == PaymentConstants.statusHalfDay) {
            halfDays++;
          }
        }

        return {'fullDays': fullDays, 'halfDays': halfDays};
      },
      {'fullDays': 0, 'halfDays': 0},
      context: 'PaidDaysRepository.getUnpaidDaysExcludingPayment',
    );
  }

  /// Günün ödenip ödenmediğini kontrol eder
  ///
  /// [userId] Kullanıcı ID'si
  /// [workerId] Çalışan ID'si
  /// [date] Tarih
  /// [status] Durum
  /// Returns: Ödenmiş ise true
  Future<bool> isDayPaid({
    required int userId,
    required int workerId,
    required DateTime date,
    required String status,
  }) async {
    return executeQuery(
      () async {
        final formattedDate = DateFormatter.toIso8601Date(date);

        final results = await supabase
            .from(PaymentConstants.paidDaysTable)
            .select()
            .eq(PaymentConstants.workerIdColumn, workerId)
            .eq(PaymentConstants.userIdColumn, userId)
            .eq(PaymentConstants.dateColumn, formattedDate)
            .eq(PaymentConstants.statusColumn, status);

        return results.isNotEmpty;
      },
      false,
      context: 'PaidDaysRepository.isDayPaid',
    );
  }
}
