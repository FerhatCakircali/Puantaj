import '../../../models/attendance.dart';
import '../constants/payment_constants.dart';

/// Ödeme hesaplamalarını yapan helper sınıfı
class PaymentCalculator {
  /// Ödenmemiş günleri sayar
  ///
  /// [unpaidAttendance] Ödenmemiş devamsızlık listesi
  /// Returns: Tam ve yarım gün sayıları
  Map<String, int> calculateUnpaidDays(List<Attendance> unpaidAttendance) {
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

  /// Attendance status'ü string'e çevirir
  ///
  /// [status] Attendance status
  /// Returns: String status (fullDay/halfDay)
  String attendanceStatusToString(AttendanceStatus status) {
    return status == AttendanceStatus.fullDay
        ? PaymentConstants.statusFullDay
        : PaymentConstants.statusHalfDay;
  }
}
