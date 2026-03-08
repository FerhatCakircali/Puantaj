import '../../../models/attendance.dart' as attendance;

/// Günlük devam durumu hesaplama sınıfı
class DailyStatusCalculator {
  /// Her gün için devam durumunu hesaplar
  static Map<DateTime, attendance.AttendanceStatus> calculate({
    required DateTime startDate,
    required DateTime endDate,
    required List<attendance.Attendance> attendanceRecords,
    required int workerId,
  }) {
    final dailyStatus = <DateTime, attendance.AttendanceStatus>{};
    DateTime currentDate = startDate;

    while (!currentDate.isAfter(endDate)) {
      final record = _findRecordForDate(
        attendanceRecords,
        currentDate,
        workerId,
      );

      dailyStatus[DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
          )] =
          record.status;

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return dailyStatus;
  }

  /// Belirli bir tarihe ait devam kaydını bulur
  static attendance.Attendance _findRecordForDate(
    List<attendance.Attendance> records,
    DateTime date,
    int workerId,
  ) {
    return records.firstWhere(
      (r) =>
          r.date.year == date.year &&
          r.date.month == date.month &&
          r.date.day == date.day,
      orElse: () => attendance.Attendance(
        userId: 0,
        workerId: workerId,
        date: date,
        status: attendance.AttendanceStatus.absent,
      ),
    );
  }

  /// Durum sayılarını hesaplar
  static Map<String, int> countStatuses(
    Map<DateTime, attendance.AttendanceStatus> dailyStatus,
  ) {
    int fullDays = 0;
    int halfDays = 0;
    int absentDays = 0;

    for (final status in dailyStatus.values) {
      switch (status) {
        case attendance.AttendanceStatus.fullDay:
          fullDays++;
          break;
        case attendance.AttendanceStatus.halfDay:
          halfDays++;
          break;
        case attendance.AttendanceStatus.absent:
          absentDays++;
          break;
      }
    }

    return {
      'fullDays': fullDays,
      'halfDays': halfDays,
      'absentDays': absentDays,
    };
  }
}
