/// Notification type enum
enum NotificationType {
  attendanceReminder,
  attendanceRequest,
  paymentNotification,
  paymentUpdated,
  paymentDeleted,
  general,
}

/// Notification domain entity
/// Represents a notification in the system.
/// Independent of any data source or UI framework.
class Notification {
  final int id;
  final int recipientId;
  final String recipientType; // 'user' or 'worker'
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const Notification({
    required this.id,
    required this.recipientId,
    required this.recipientType,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.metadata,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Notification &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Notification(id: $id, title: $title, isRead: $isRead, type: $type)';
}
