import '../../../core/error/result.dart';
import '../../../core/error/exceptions.dart';
import '../../repositories/i_notification_repository.dart';
import '../usecase.dart';

/// Mark notification read use case parameters
class MarkNotificationReadParams {
  final int notificationId;

  const MarkNotificationReadParams({required this.notificationId});
}

/// Mark notification read use case
///
/// Marks a notification as read.
/// Business rules:
/// - Notification must exist
/// - Notification ID must be valid
class MarkNotificationReadUseCase
    implements UseCase<void, MarkNotificationReadParams> {
  final INotificationRepository _repository;

  MarkNotificationReadUseCase(this._repository);

  @override
  Future<Result<void>> call(MarkNotificationReadParams params) async {
    // Validate notification ID
    if (params.notificationId <= 0) {
      return const Failure(ValidationException('Geçersiz bildirim ID'));
    }

    // Call repository
    return await _repository.markAsRead(params.notificationId);
  }
}
