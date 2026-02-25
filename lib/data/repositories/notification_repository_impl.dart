import '../../core/error/result.dart';
import '../../core/error/exceptions.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/i_notification_repository.dart';
import '../datasources/supabase_datasource.dart';
import '../models/notification_model.dart';

/// Notification repository implementation
///
/// Implements INotificationRepository using Supabase as data source.
/// Handles all notification data operations with proper error handling.
class NotificationRepositoryImpl implements INotificationRepository {
  final SupabaseDataSource _dataSource;

  NotificationRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<Notification>>> getAll(
    int recipientId,
    String recipientType,
  ) async {
    try {
      final response = await _dataSource.client
          .from('notifications')
          .select()
          .eq('recipient_id', recipientId)
          .eq('recipient_type', recipientType)
          .order('created_at', ascending: false);

      final notifications = (response as List)
          .map((json) => NotificationModel.fromJson(json).toEntity())
          .toList();

      return Success(notifications);
    } catch (e, stackTrace) {
      return Failure(
        NetworkException(
          'Failed to fetch notifications: $e',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<List<Notification>>> getUnread(
    int recipientId,
    String recipientType,
  ) async {
    try {
      final response = await _dataSource.client
          .from('notifications')
          .select()
          .eq('recipient_id', recipientId)
          .eq('recipient_type', recipientType)
          .eq('is_read', false)
          .order('created_at', ascending: false);

      final notifications = (response as List)
          .map((json) => NotificationModel.fromJson(json).toEntity())
          .toList();

      return Success(notifications);
    } catch (e, stackTrace) {
      return Failure(
        NetworkException(
          'Failed to fetch unread notifications: $e',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<void>> markAsRead(int notificationId) async {
    try {
      await _dataSource.update('notifications', notificationId.toString(), {
        'is_read': true,
      });

      return const Success(null);
    } catch (e, stackTrace) {
      return Failure(
        NetworkException(
          'Failed to mark notification as read: $e',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<Notification>> create(Notification notification) async {
    try {
      final data = NotificationModel.fromEntity(notification);

      // Remove id for insert operation
      final insertData = Map<String, dynamic>.from(data)..remove('id');

      final response = await _dataSource.insert('notifications', insertData);

      final createdNotification = NotificationModel.fromJson(
        response,
      ).toEntity();
      return Success(createdNotification);
    } catch (e, stackTrace) {
      return Failure(
        NetworkException(
          'Failed to create notification: $e',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<void>> delete(int notificationId) async {
    try {
      await _dataSource.delete('notifications', notificationId.toString());
      return const Success(null);
    } catch (e, stackTrace) {
      return Failure(
        NetworkException(
          'Failed to delete notification: $e',
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
