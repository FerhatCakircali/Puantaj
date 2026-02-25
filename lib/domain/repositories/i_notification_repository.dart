import '../../core/error/result.dart';
import '../entities/notification.dart';

/// Notification repository interface
///
/// Defines contract for notification data operations.
abstract class INotificationRepository {
  /// Get all notifications for recipient
  Future<Result<List<Notification>>> getAll(
    int recipientId,
    String recipientType,
  );

  /// Get unread notifications
  Future<Result<List<Notification>>> getUnread(
    int recipientId,
    String recipientType,
  );

  /// Mark notification as read
  Future<Result<void>> markAsRead(int notificationId);

  /// Create new notification
  Future<Result<Notification>> create(Notification notification);

  /// Delete notification
  Future<Result<void>> delete(int notificationId);
}
