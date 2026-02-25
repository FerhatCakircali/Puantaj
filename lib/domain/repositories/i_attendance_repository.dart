import '../../core/error/result.dart';
import '../entities/attendance.dart';

/// Attendance repository interface
///
/// Defines contract for attendance data operations.
abstract class IAttendanceRepository {
  /// Get attendance records by employee ID
  Future<Result<List<Attendance>>> getByEmployee(int employeeId);

  /// Get attendance records by date range
  Future<Result<List<Attendance>>> getByDateRange(DateTime start, DateTime end);

  /// Create new attendance record
  Future<Result<Attendance>> create(Attendance attendance);

  /// Update existing attendance record
  Future<Result<Attendance>> update(Attendance attendance);

  /// Approve attendance request
  Future<Result<Attendance>> approve(int attendanceId);

  /// Reject attendance request
  Future<Result<Attendance>> reject(int attendanceId, String reason);
}
