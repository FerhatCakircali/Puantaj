import '../../domain/entities/attendance.dart';

/// Attendance data model
/// Maps database records to Attendance domain entity.
class AttendanceModel {
  final int id;
  final int employeeId;
  final String date;
  final double hoursWorked;
  final String status;
  final String? notes;
  final String createdAt;

  const AttendanceModel({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.hoursWorked,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as int,
      employeeId: json['employee_id'] as int,
      date: json['date'] as String,
      hoursWorked: (json['hours_worked'] as num).toDouble(),
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
    );
  }

  Attendance toEntity() {
    AttendanceStatus statusEnum;
    switch (status.toLowerCase()) {
      case 'approved':
        statusEnum = AttendanceStatus.approved;
        break;
      case 'rejected':
        statusEnum = AttendanceStatus.rejected;
        break;
      default:
        statusEnum = AttendanceStatus.pending;
    }

    return Attendance(
      id: id,
      employeeId: employeeId,
      date: DateTime.parse(date),
      hoursWorked: hoursWorked,
      status: statusEnum,
      notes: notes,
      createdAt: DateTime.parse(createdAt),
    );
  }

  static Map<String, dynamic> fromEntity(Attendance attendance) {
    String statusString;
    switch (attendance.status) {
      case AttendanceStatus.approved:
        statusString = 'approved';
        break;
      case AttendanceStatus.rejected:
        statusString = 'rejected';
        break;
      case AttendanceStatus.pending:
        statusString = 'pending';
        break;
    }

    return {
      'id': attendance.id,
      'employee_id': attendance.employeeId,
      'date': attendance.date.toIso8601String(),
      'hours_worked': attendance.hoursWorked,
      'status': statusString,
      'notes': attendance.notes,
      'created_at': attendance.createdAt.toIso8601String(),
    };
  }
}
