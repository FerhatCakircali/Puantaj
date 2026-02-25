enum AttendanceStatus { absent, halfDay, fullDay }

class Attendance {
  final int? id;
  final int userId;
  final int workerId;
  final DateTime date;
  final AttendanceStatus status;
  final String? createdBy; // 'manager' veya 'worker'
  final bool notificationSent; // Bildirim gönderildi mi?
  final String? workerName; // Çalışan adı (join'den gelir)

  Attendance({
    this.id,
    required this.userId,
    required this.workerId,
    required this.date,
    this.status = AttendanceStatus.absent,
    this.createdBy,
    this.notificationSent = false,
    this.workerName,
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
      createdBy: map['created_by'] as String?,
      notificationSent: map['notification_sent'] as bool? ?? false,
      workerName: map['worker_name'] as String?,
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
      if (createdBy != null) 'created_by': createdBy,
      'notification_sent': notificationSent,
      // workerName is not included in toMap as it's a join field
    };
  }

  /// Attendance kopyasını oluşturur (immutable pattern)
  Attendance copyWith({
    int? id,
    int? userId,
    int? workerId,
    DateTime? date,
    AttendanceStatus? status,
    String? createdBy,
    bool? notificationSent,
    String? workerName,
  }) {
    return Attendance(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workerId: workerId ?? this.workerId,
      date: date ?? this.date,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      notificationSent: notificationSent ?? this.notificationSent,
      workerName: workerName ?? this.workerName,
    );
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
