/// Attendance status enum
enum AttendanceStatus { pending, approved, rejected }

/// Attendance domain entity
/// Represents an attendance record for an employee.
/// Independent of any data source or UI framework.
class Attendance {
  final int id;
  final int employeeId;
  final DateTime date;
  final double hoursWorked;
  final AttendanceStatus status;
  final String? notes;
  final DateTime createdAt;

  const Attendance({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.hoursWorked,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Attendance && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Attendance(id: $id, employeeId: $employeeId, date: $date, status: $status)';
}
