import '../../../core/error/result.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/attendance.dart';
import '../../repositories/i_attendance_repository.dart';
import '../usecase.dart';

/// Create attendance use case parameters
class CreateAttendanceParams {
  final int employeeId;
  final DateTime date;
  final double hoursWorked;
  final String? notes;

  const CreateAttendanceParams({
    required this.employeeId,
    required this.date,
    required this.hoursWorked,
    this.notes,
  });
}

/// Create attendance use case
/// Validates input, checks for duplicates, and creates attendance record.
/// Business rules:
/// - Employee ID must be valid
/// - Hours worked must be between 0 and 24
/// - Cannot create duplicate attendance for same employee and date
/// - Date cannot be in the future
class CreateAttendanceUseCase
    implements UseCase<Attendance, CreateAttendanceParams> {
  final IAttendanceRepository _repository;

  CreateAttendanceUseCase(this._repository);

  @override
  Future<Result<Attendance>> call(CreateAttendanceParams params) async {
    // Validate employee ID
    if (params.employeeId <= 0) {
      return const Failure(ValidationException('Geçersiz çalışan ID'));
    }

    // Validate hours worked
    if (params.hoursWorked < 0 || params.hoursWorked > 24) {
      return const Failure(
        ValidationException('Çalışma saati 0 ile 24 arasında olmalıdır'),
      );
    }

    // Validate date (cannot be in future)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final recordDate = DateTime(
      params.date.year,
      params.date.month,
      params.date.day,
    );

    if (recordDate.isAfter(today)) {
      return const Failure(
        ValidationException('Gelecek tarih için devam kaydı oluşturulamaz'),
      );
    }

    // Check for duplicates
    final existingRecords = await _repository.getByEmployee(params.employeeId);

    if (existingRecords is Success<List<Attendance>>) {
      final hasDuplicate = existingRecords.data.any((record) {
        final existingDate = DateTime(
          record.date.year,
          record.date.month,
          record.date.day,
        );
        return existingDate.isAtSameMomentAs(recordDate);
      });

      if (hasDuplicate) {
        return const Failure(
          ValidationException('Bu tarih için zaten devam kaydı mevcut'),
        );
      }
    }

    // Create attendance entity
    final attendance = Attendance(
      id: 0, // Will be assigned by database
      employeeId: params.employeeId,
      date: params.date,
      hoursWorked: params.hoursWorked,
      status: AttendanceStatus.pending,
      notes: params.notes,
      createdAt: DateTime.now(),
    );

    // Call repository
    return await _repository.create(attendance);
  }
}
