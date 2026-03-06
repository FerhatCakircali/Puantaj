import '../../../core/error/result.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/notification.dart';
import '../../repositories/i_notification_repository.dart';
import '../usecase.dart';

/// Get notifications use case parameters
class GetNotificationsParams {
  final int recipientId;
  final String recipientType;
  final bool unreadOnly;

  const GetNotificationsParams({
    required this.recipientId,
    required this.recipientType,
    this.unreadOnly = false,
  });
}

/// Get notifications use case
/// Fetches notifications for a recipient.
/// Business rules:
/// - Recipient ID must be valid
/// - Recipient type must be valid (admin, worker, employee)
/// - Sort by created date descending (newest first)
class GetNotificationsUseCase
    implements UseCase<List<Notification>, GetNotificationsParams> {
  final INotificationRepository _repository;

  GetNotificationsUseCase(this._repository);

  @override
  Future<Result<List<Notification>>> call(GetNotificationsParams params) async {
    // Validate recipient ID
    if (params.recipientId <= 0) {
      return const Failure(ValidationException('Geçersiz alıcı ID'));
    }

    // Validate recipient type
    final validTypes = ['admin', 'worker', 'employee'];
    if (!validTypes.contains(params.recipientType.toLowerCase())) {
      return const Failure(ValidationException('Geçersiz alıcı tipi'));
    }

    // Fetch notifications
    final result = params.unreadOnly
        ? await _repository.getUnread(params.recipientId, params.recipientType)
        : await _repository.getAll(params.recipientId, params.recipientType);

    return result;
  }
}
