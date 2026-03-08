import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/attendance.dart' as attendance;
import '../../../../models/employee.dart';
import '../../../../services/attendance_service.dart';
import '../../../../services/employee_service.dart';
import '../widgets/attendance_helpers.dart';

/// Yoklama verilerini yükleyen sınıf
///
/// Çalışan ve yoklama kayıtlarını veritabanından çeker ve işler
class AttendanceDataLoader {
  final AttendanceService _attendanceService = AttendanceService();
  final EmployeeService _employeeService = EmployeeService();

  /// Seçili tarihe ait verileri yükler
  ///
  /// Returns: Çalışanlar, filtrelenmiş çalışanlar ve yoklama map'i
  Future<AttendanceData> loadData(DateTime selectedDate) async {
    debugPrint('[Attendance] loadData başladı');

    try {
      final allEmployees = await _employeeService.getEmployees();
      final allAttendance = await _attendanceService.getAttendanceByDate(
        selectedDate,
      );

      debugPrint(
        '[Attendance] Veritabanından ${allAttendance.length} kayıt geldi',
      );
      for (var record in allAttendance) {
        debugPrint('Worker ${record.workerId}: ${record.status}');
      }

      allEmployees.sort(
        (a, b) => AttendanceHelpers.collateTurkish(a.name, b.name),
      );

      final filteredEmps = allEmployees
          .where((e) => !e.startDate.isAfter(selectedDate))
          .toList();

      final attendanceMap = {
        for (var record in allAttendance) record.workerId: record,
      };

      debugPrint('[Attendance] Veriler yüklendi');
      debugPrint('Tarih: ${DateFormat('dd/MM/yyyy').format(selectedDate)}');
      debugPrint('Toplam çalışan sayısı: ${allEmployees.length}');
      debugPrint(
        'İşe başlama tarihine göre filtrelenmiş çalışan sayısı: ${filteredEmps.length}',
      );
      debugPrint('Devam kaydı sayısı: ${allAttendance.length}');

      return AttendanceData(
        employees: filteredEmps,
        filteredEmployees: filteredEmps,
        attendanceMap: attendanceMap,
      );
    } catch (e, stackTrace) {
      debugPrint('[Attendance] Çalışan verileri yüklenirken hata oluştu: $e');
      debugPrint('Hata ayrıntıları: $stackTrace');
      rethrow;
    }
  }
}

/// Yoklama veri modeli
class AttendanceData {
  final List<Employee> employees;
  final List<Employee> filteredEmployees;
  final Map<int, attendance.Attendance> attendanceMap;

  const AttendanceData({
    required this.employees,
    required this.filteredEmployees,
    required this.attendanceMap,
  });
}
