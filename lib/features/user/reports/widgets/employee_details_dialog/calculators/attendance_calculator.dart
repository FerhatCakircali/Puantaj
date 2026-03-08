import '../../../../../../models/attendance.dart' as attendance;

/// Devam kayıtlarını hesaplayan yardımcı sınıf
///
/// Tam gün, yarım gün ve devamsızlık sayılarını hesaplar.
class AttendanceCalculator {
  /// Devam kayıtlarını analiz eder ve sonuçları döndürür
  static AttendanceResult calculate({
    required List<attendance.Attendance> records,
    required DateTime startDate,
    required DateTime endDate,
    required int workerId,
  }) {
    int fullDays = 0;
    int halfDays = 0;
    int absentDays = 0;

    final List<DateTime> fullDayDates = [];
    final List<DateTime> halfDayDates = [];
    final List<DateTime> absentDayDates = [];

    DateTime currentDate = startDate;
    while (!currentDate.isAfter(endDate)) {
      final record = records.firstWhere(
        (r) =>
            r.date.year == currentDate.year &&
            r.date.month == currentDate.month &&
            r.date.day == currentDate.day,
        orElse: () => attendance.Attendance(
          userId: 0,
          workerId: workerId,
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

    return AttendanceResult(
      fullDays: fullDays,
      halfDays: halfDays,
      absentDays: absentDays,
      fullDayDates: fullDayDates,
      halfDayDates: halfDayDates,
      absentDayDates: absentDayDates,
    );
  }
}

/// Devam hesaplama sonucu
class AttendanceResult {
  final int fullDays;
  final int halfDays;
  final int absentDays;
  final List<DateTime> fullDayDates;
  final List<DateTime> halfDayDates;
  final List<DateTime> absentDayDates;

  AttendanceResult({
    required this.fullDays,
    required this.halfDays,
    required this.absentDays,
    required this.fullDayDates,
    required this.halfDayDates,
    required this.absentDayDates,
  });
}
