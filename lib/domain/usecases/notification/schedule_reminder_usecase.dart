import 'package:flutter/material.dart';
import '../../../core/error/result.dart';
import '../../../core/error/exceptions.dart';
import '../../services/i_notification_service.dart';
import '../usecase.dart';

/// Schedule reminder use case parameters
class ScheduleReminderParams {
  final int userId;
  final String username;
  final String fullName;
  final TimeOfDay time;

  const ScheduleReminderParams({
    required this.userId,
    required this.username,
    required this.fullName,
    required this.time,
  });
}

/// Schedule reminder use case
/// Schedules attendance reminder notification.
/// Business rules:
/// - User ID must be valid
/// - Time must be valid (0-23 hours, 0-59 minutes)
/// - Check notification permissions
/// - Schedule for daily recurrence
class ScheduleReminderUseCase implements UseCase<void, ScheduleReminderParams> {
  final INotificationService _notificationService;

  ScheduleReminderUseCase(this._notificationService);

  @override
  Future<Result<void>> call(ScheduleReminderParams params) async {
    try {
      // Validate user ID
      if (params.userId <= 0) {
        return const Failure(ValidationException('Geçersiz kullanıcı ID'));
      }

      // Validate time
      if (params.time.hour < 0 || params.time.hour > 23) {
        return const Failure(ValidationException('Geçersiz saat'));
      }

      if (params.time.minute < 0 || params.time.minute > 59) {
        return const Failure(ValidationException('Geçersiz dakika'));
      }

      // Check permissions
      final hasPermission = await _notificationService
          .checkAndRequestPermissions();
      if (!hasPermission) {
        return const Failure(ValidationException('Bildirim izni verilmedi'));
      }

      // Schedule reminder
      await _notificationService.scheduleAttendanceReminder(
        userId: params.userId,
        username: params.username,
        fullName: params.fullName,
        time: params.time,
      );

      return const Success(null);
    } catch (e, stackTrace) {
      return Failure(
        NetworkException(
          'Hatırlatıcı zamanlanamadı: $e',
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
