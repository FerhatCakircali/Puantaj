import '../../../../../models/attendance.dart' as attendance;
import '../../../../../models/employee.dart';

/// Helper fonksiyonlar - ReportControllerMixin
class ReportControllerHelpers {
  /// Türkçe alfabeye göre sıralama
  static int collateTurkish(String a, String b) {
    const turkishChars = {
      'ç': 'c',
      'ğ': 'g',
      'ı': 'i',
      'ö': 'o',
      'ş': 's',
      'ü': 'u',
      'Ç': 'C',
      'Ğ': 'G',
      'İ': 'I',
      'Ö': 'O',
      'Ş': 'S',
      'Ü': 'U',
    };

    String normalize(String str) {
      return str.split('').map((char) => turkishChars[char] ?? char).join();
    }

    return normalize(a.toLowerCase()).compareTo(normalize(b.toLowerCase()));
  }

  /// Devam istatistiklerini hesapla
  static Map<String, dynamic> calculateAttendanceStats(
    Employee emp,
    List<attendance.Attendance> records,
    DateTime startDate,
    DateTime endDate,
    Map<String, int> unpaidDays,
  ) {
    int fullDays = 0;
    int halfDays = 0;
    int absentDays = 0;
    List<DateTime> fullDayDates = [];
    List<DateTime> halfDayDates = [];
    List<DateTime> absentDayDates = [];

    DateTime currentDate = emp.startDate.isAfter(startDate)
        ? emp.startDate
        : startDate;

    while (!currentDate.isAfter(endDate)) {
      final record = records.firstWhere(
        (r) =>
            r.date.year == currentDate.year &&
            r.date.month == currentDate.month &&
            r.date.day == currentDate.day,
        orElse: () => attendance.Attendance(
          userId: 0,
          workerId: emp.id,
          date: currentDate,
          status: attendance.AttendanceStatus.absent,
        ),
      );

      switch (record.status) {
        case attendance.AttendanceStatus.fullDay:
          fullDays++;
          fullDayDates.add(currentDate);
          break;
        case attendance.AttendanceStatus.halfDay:
          halfDays++;
          halfDayDates.add(currentDate);
          break;
        case attendance.AttendanceStatus.absent:
          absentDays++;
          absentDayDates.add(currentDate);
          break;
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return {
      'fullDays': fullDays,
      'halfDays': halfDays,
      'absentDays': absentDays,
      'fullDayDates': fullDayDates,
      'halfDayDates': halfDayDates,
      'absentDayDates': absentDayDates,
      'unpaidFullDays': unpaidDays['fullDays'] ?? 0,
      'unpaidHalfDays': unpaidDays['halfDays'] ?? 0,
    };
  }
}
