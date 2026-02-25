class NotificationSettings {
  final int? id;
  final int userId;
  final String time; // Format: "HH:mm"
  final bool enabled;
  final bool autoApproveTrusted;
  final bool attendanceRequestsEnabled;
  final DateTime lastUpdated;

  NotificationSettings({
    this.id,
    required this.userId,
    required this.time,
    required this.enabled,
    this.autoApproveTrusted = false,
    this.attendanceRequestsEnabled = true,
    required this.lastUpdated,
  });

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    // enabled değeri hem boolean hem integer olabilir
    final enabledValue = map['enabled'];
    final bool isEnabled;

    if (enabledValue is bool) {
      isEnabled = enabledValue;
    } else if (enabledValue is int) {
      isEnabled = enabledValue == 1;
    } else {
      isEnabled = false;
    }

    // auto_approve_trusted değeri hem boolean hem integer olabilir
    final autoApproveValue = map['auto_approve_trusted'];
    final bool autoApprove;

    if (autoApproveValue is bool) {
      autoApprove = autoApproveValue;
    } else if (autoApproveValue is int) {
      autoApprove = autoApproveValue == 1;
    } else {
      autoApprove = false;
    }

    // attendance_requests_enabled değeri hem boolean hem integer olabilir
    final attendanceRequestsValue = map['attendance_requests_enabled'];
    final bool attendanceRequestsEnabled;

    if (attendanceRequestsValue is bool) {
      attendanceRequestsEnabled = attendanceRequestsValue;
    } else if (attendanceRequestsValue is int) {
      attendanceRequestsEnabled = attendanceRequestsValue == 1;
    } else {
      attendanceRequestsEnabled = true; // Varsayılan değer true
    }

    return NotificationSettings(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      time: map['time'] as String,
      enabled: isEnabled,
      autoApproveTrusted: autoApprove,
      attendanceRequestsEnabled: attendanceRequestsEnabled,
      lastUpdated: DateTime.parse(map['last_updated'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'time': time,
      'enabled': enabled ? 1 : 0,
      'auto_approve_trusted': autoApproveTrusted ? 1 : 0,
      'attendance_requests_enabled': attendanceRequestsEnabled ? 1 : 0,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}
