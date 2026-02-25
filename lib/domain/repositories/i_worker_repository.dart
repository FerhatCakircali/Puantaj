import '../../core/error/result.dart';
import '../entities/worker.dart';
import '../entities/attendance.dart';

/// Worker repository interface
///
/// Defines contract for worker data operations.
abstract class IWorkerRepository {
  /// Get worker by ID
  Future<Result<Worker>> getById(String workerId);

  /// Update worker profile
  Future<Result<Worker>> updateProfile(Worker worker);

  /// Change worker password
  Future<Result<void>> changePassword(
    String workerId,
    String oldPassword,
    String newPassword,
  );

  /// Get worker's attendance records
  Future<Result<List<Attendance>>> getAttendance(
    String workerId,
    DateTime start,
    DateTime end,
  );
}
