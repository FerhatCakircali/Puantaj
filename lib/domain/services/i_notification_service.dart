import 'package:flutter/material.dart';

/// Notification service interface
/// Defines contract for notification operations (local notifications).
/// Implementations handle platform-specific notification logic.
abstract class INotificationService {
  /// Initialize notification service
  Future<void> initialize();

  /// Show instant notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  });

  /// Schedule notification for specific time
  Future<void> scheduleNotification({
    required int id,
    required DateTime scheduledTime,
    required String title,
    required String body,
    String? payload,
  });

  /// Schedule attendance reminder
  Future<void> scheduleAttendanceReminder({
    required int userId,
    required String username,
    required String fullName,
    required TimeOfDay time,
  });

  /// Cancel specific notification
  Future<void> cancelNotification(int id);

  /// Cancel all notifications
  Future<void> cancelAllNotifications();

  /// Check and request permissions
  Future<bool> checkAndRequestPermissions();
}
