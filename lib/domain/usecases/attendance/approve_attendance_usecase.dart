import '../../../core/error/result.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/attendance.dart';
import '../../repositories/i_attendance_repository.dart';
import '../usecase.dart';

/// Approve attendance use case parameters
class ApproveAttendanceParams {
  final int attendanceId;

  const ApproveAttendanceParams({required this.attendanceId});
}

/// Approve attendance use case
/// Approves pending attendance request.
/// Business rules:
/// - Attendance must exist
/// - Attendance must be in pending status
/// - Trigger notification to employee (future enhancement)
class ApproveAttendanceUseCase
    implements UseCase<Attendance, ApproveAttendanceParams> {
  final IAttendanceRepository _repository;

  ApproveAttendanceUseCase(this._repository);

  @override
  Future<Result<Attendance>> call(ApproveAttendanceParams params) async {
    // Validate attendance ID
    if (params.attendanceId <= 0) {
      return const Failure(ValidationException('Geçersiz devam kaydı ID'));
    }

    // Call repository to approve
    final result = await _repository.approve(params.attendanceId);

    // TODO: Trigger notification to employee
    // if (result is Success<Attendance>) {
    //   await _notificationRepository.create(...);
    // }

    return result;
  }
}
