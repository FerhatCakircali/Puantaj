import '../../../core/error/result.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/attendance.dart';
import '../../repositories/i_attendance_repository.dart';
import '../usecase.dart';

/// Update attendance use case
///
/// Validates input and updates existing attendance record.
/// Business rules:
/// - Attendance must exist
/// - Hours worked must be between 0 and 24
/// - Cannot update approved/rejected records (business rule)
class UpdateAttendanceUseCase implements UseCase<Attendance, Attendance> {
  final IAttendanceRepository _repository;

  UpdateAttendanceUseCase(this._repository);

  @override
  Future<Result<Attendance>> call(Attendance attendance) async {
    // Validate hours worked
    if (attendance.hoursWorked < 0 || attendance.hoursWorked > 24) {
      return const Failure(
        ValidationException('Çalışma saati 0 ile 24 arasında olmalıdır'),
      );
    }

    // Business rule: Cannot update approved/rejected records
    if (attendance.status != AttendanceStatus.pending) {
      return const Failure(
        ValidationException(
          'Onaylanmış veya reddedilmiş kayıtlar güncellenemez',
        ),
      );
    }

    // Call repository
    return await _repository.update(attendance);
  }
}
