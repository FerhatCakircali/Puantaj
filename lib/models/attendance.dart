enum AttendanceStatus { absent, halfDay, fullDay }

class Attendance {
  final int? id;
  final int userId;
  final int workerId;
  final DateTime date;
  final AttendanceStatus status;

  Attendance({
    this.id,
    required this.userId,
    required this.workerId,
    required this.date,
    this.status = AttendanceStatus.absent,
  });

  factory Attendance.fromMap(Map<String, dynamic> map) {
    final dateStr = map['date'] as String;
    final date = DateTime.parse(dateStr);

    return Attendance(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      workerId: map['worker_id'] as int,
      date: date,
      status: _statusFromString(map['status'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'worker_id': workerId,
      'date':
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'status': _statusToString(status),
    };
  }

  static AttendanceStatus _statusFromString(String status) {
    return switch (status) {
      'halfDay' => AttendanceStatus.halfDay,
      'fullDay' => AttendanceStatus.fullDay,
      _ => AttendanceStatus.absent,
    };
  }

  static String _statusToString(AttendanceStatus status) {
    return switch (status) {
      AttendanceStatus.halfDay => 'halfDay',
      AttendanceStatus.fullDay => 'fullDay',
      AttendanceStatus.absent => 'absent',
    };
  }
}
