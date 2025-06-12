class NotificationSettings {
  final int? id;
  final int userId;
  final String time; // Format: "HH:mm"
  final bool enabled;
  final DateTime lastUpdated;

  NotificationSettings({
    this.id,
    required this.userId,
    required this.time,
    required this.enabled,
    required this.lastUpdated,
  });

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      time: map['time'] as String,
      enabled: map['enabled'] == 1,
      lastUpdated: DateTime.parse(map['last_updated'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'time': time,
      'enabled': enabled ? 1 : 0,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}
