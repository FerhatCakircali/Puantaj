import '../../../core/error/result.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/attendance.dart';
import '../../repositories/i_attendance_repository.dart';
import '../usecase.dart';

/// Get attendance use case parameters
class GetAttendanceParams {
  final int? employeeId;
  final DateTime? startDate;
  final DateTime? endDate;

  const GetAttendanceParams({this.employeeId, this.startDate, this.endDate});
}

/// Get attendance use case
///
/// Fetches attendance records with optional filters.
/// Business rules:
/// - If employeeId provided, fetch by employee
/// - If date range provided, fetch by date range
/// - Sort by date descending (newest first)
class GetAttendanceUseCase
    implements UseCase<List<Attendance>, GetAttendanceParams> {
  final IAttendanceRepository _repository;

  GetAttendanceUseCase(this._repository);

  @override
  Future<Result<List<Attendance>>> call(GetAttendanceParams params) async {
    // Validate date range if provided
    if (params.startDate != null && params.endDate != null) {
      if (params.startDate!.isAfter(params.endDate!)) {
        return const Failure(
          ValidationException('Başlangıç tarihi bitiş tarihinden sonra olamaz'),
        );
      }
    }

    // Fetch by employee or date range
    Result<List<Attendance>> result;

    if (params.employeeId != null) {
      result = await _repository.getByEmployee(params.employeeId!);
    } else if (params.startDate != null && params.endDate != null) {
      result = await _repository.getByDateRange(
        params.startDate!,
        params.endDate!,
      );
    } else {
      return const Failure(
        ValidationException('Çalışan ID veya tarih aralığı belirtilmelidir'),
      );
    }

    // Sort by date descending if successful
    if (result is Success<List<Attendance>>) {
      final sortedRecords = List<Attendance>.from(result.data)
        ..sort((a, b) => b.date.compareTo(a.date));

      return Success(sortedRecords);
    }

    return result;
  }
}
