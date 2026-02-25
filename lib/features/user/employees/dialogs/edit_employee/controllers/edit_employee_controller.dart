import '../../../../../../models/employee.dart';

/// Çalışan düzenleme iş mantığı kontrolcüsü
class EditEmployeeController {
  /// Tarih değişikliğini kontrol eder ve kayıt varlığını döndürür
  Future<DateChangeResult> handleDateChange({
    required DateTime newDate,
    required DateTime originalDate,
    required int employeeId,
    required Future<bool> Function(int employeeId, DateTime date)
    onCheckRecords,
  }) async {
    final isDateChanged =
        newDate.day != originalDate.day ||
        newDate.month != originalDate.month ||
        newDate.year != originalDate.year;

    if (!isDateChanged) {
      return DateChangeResult(isChanged: false, hasRecordsBeforeNewDate: false);
    }

    if (newDate.isAfter(originalDate)) {
      final hasRecords = await onCheckRecords(employeeId, newDate);
      return DateChangeResult(
        isChanged: true,
        hasRecordsBeforeNewDate: hasRecords,
      );
    }

    return DateChangeResult(isChanged: true, hasRecordsBeforeNewDate: false);
  }

  /// Çalışan bilgilerini günceller
  Future<void> updateEmployee({
    required Employee employee,
    required Future<void> Function(Employee employee) onUpdate,
  }) async {
    await onUpdate(employee);
  }

  /// Kayıtları siler ve çalışanı günceller
  Future<void> updateWithRecordDeletion({
    required Employee employee,
    required DateTime newStartDate,
    required Future<void> Function(int employeeId, DateTime date)
    onDeleteRecords,
    required Future<void> Function(Employee employee) onUpdate,
  }) async {
    await onDeleteRecords(employee.id, newStartDate);
    await onUpdate(employee);
  }

  /// Form validasyonu
  bool validateForm({
    required String name,
    required String title,
    required String phone,
  }) {
    return name.isNotEmpty && title.isNotEmpty && phone.isNotEmpty;
  }
}

/// Tarih değişikliği sonuç modeli
class DateChangeResult {
  final bool isChanged;
  final bool hasRecordsBeforeNewDate;

  DateChangeResult({
    required this.isChanged,
    required this.hasRecordsBeforeNewDate,
  });
}
