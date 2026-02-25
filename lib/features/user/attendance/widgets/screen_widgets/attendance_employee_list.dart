import 'package:flutter/material.dart';
import '../../../../../models/employee.dart';
import '../../../../../models/attendance.dart' as attendance;
import 'attendance_employee_item.dart';
import 'attendance_no_results.dart';

/// Çalışan listesi widget'ı
class AttendanceEmployeeList extends StatelessWidget {
  final List<Employee> employees;
  final DateTime selectedDate;
  final Map<int, attendance.Attendance> attendanceMap;
  final Map<int, attendance.AttendanceStatus> pendingChanges;
  final Function(int, attendance.AttendanceStatus) onStatusChanged;

  const AttendanceEmployeeList({
    super.key,
    required this.employees,
    required this.selectedDate,
    required this.attendanceMap,
    required this.pendingChanges,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (employees.isEmpty) {
      return const AttendanceNoResults();
    }

    return ListView.separated(
      itemCount: employees.length,
      separatorBuilder: (context, i) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final emp = employees[index];
        final currentStatus =
            pendingChanges[emp.id] ??
            attendanceMap[emp.id]?.status ??
            attendance.AttendanceStatus.absent;

        return AttendanceEmployeeItem(
          employee: emp,
          selectedDate: selectedDate,
          currentStatus: currentStatus,
          onStatusChanged: (value) => onStatusChanged(emp.id, value),
        );
      },
    );
  }
}
