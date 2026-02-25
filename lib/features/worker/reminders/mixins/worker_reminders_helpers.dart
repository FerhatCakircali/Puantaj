import '../../../../models/attendance.dart';

/// Helper fonksiyonlar - WorkerRemindersScreen
class WorkerRemindersHelpers {
  /// AttendanceStatus enum'ını Türkçe metne çevirir
  static String getStatusText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.fullDay:
        return 'Tam Gün';
      case AttendanceStatus.halfDay:
        return 'Yarım Gün';
      case AttendanceStatus.absent:
        return 'Gelmedi';
    }
  }

  /// String status değerini Türkçe metne çevirir
  static String getStatusTextFromString(String? statusValue) {
    if (statusValue == 'fullDay') return 'Tam Gün';
    if (statusValue == 'halfDay') return 'Yarım Gün';
    if (statusValue == 'absent') return 'Gelmedi';
    return 'Bilinmeyen';
  }

  /// TimeOfDay'i string formatına çevirir (HH:mm:ss)
  static String formatTimeOfDayToString(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// TimeOfDay'i görüntüleme formatına çevirir (HH:mm)
  static String formatTimeOfDayForDisplay(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
