class EmployeeReminder {
  final int? id;
  final int userId;
  final int workerId;
  final String workerName; // Çalışan adı (gösterim için)
  final DateTime reminderDate;
  final String message;
  final bool isCompleted;

  EmployeeReminder({
    this.id,
    required this.userId,
    required this.workerId,
    required this.workerName,
    required this.reminderDate,
    required this.message,
    this.isCompleted = false,
  });

  factory EmployeeReminder.fromMap(Map<String, dynamic> map) {
    // Tarihi parse et ve UTC'den yerel saate çevir
    final reminderDateUtc = DateTime.parse(map['reminder_date'] as String);
    final reminderDateLocal = reminderDateUtc.isUtc ? reminderDateUtc.toLocal() : reminderDateUtc;
    
    return EmployeeReminder(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      workerId: map['worker_id'] as int,
      workerName: map['worker_name'] as String,
      reminderDate: reminderDateLocal,
      message: map['message'] as String,
      isCompleted: map['is_completed'] == 1,
    );
  }

  Map<String, dynamic> toMap() {
    // Yerel tarihten UTC'ye çevir ve ISO formatında sakla
    final reminderDateUtc = reminderDate.isUtc ? reminderDate : reminderDate.toUtc();
    
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'worker_id': workerId,
      'worker_name': workerName,
      'reminder_date': reminderDateUtc.toIso8601String(),
      'message': message,
      'is_completed': isCompleted ? 1 : 0,
    };
  }
} 