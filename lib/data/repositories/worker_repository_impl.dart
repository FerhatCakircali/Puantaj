import '../../core/error/result.dart';
import '../../core/error/exceptions.dart';
import '../../domain/entities/worker.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/repositories/i_worker_repository.dart';
import '../datasources/supabase_datasource.dart';
import '../models/worker_model.dart';
import '../models/attendance_model.dart';

/// Worker repository implementation
/// Implements IWorkerRepository using Supabase as data source.
/// Handles all worker data operations with proper error handling.
class WorkerRepositoryImpl implements IWorkerRepository {
  final SupabaseDataSource _dataSource;

  WorkerRepositoryImpl(this._dataSource);

  @override
  Future<Result<Worker>> getById(String workerId) async {
    try {
      final response = await _dataSource.query('workers', {'id': workerId});

      if (response == null) {
        return Failure(NotFoundException('Worker with id $workerId not found'));
      }

      final worker = WorkerModel.fromJson(response).toEntity();
      return Success(worker);
    } catch (e, stackTrace) {
      return Failure(
        NetworkException('Failed to fetch worker: $e', stackTrace: stackTrace),
      );
    }
  }

  @override
  Future<Result<Worker>> updateProfile(Worker worker) async {
    try {
      final data = WorkerModel.fromEntity(worker);

      final response = await _dataSource.update('workers', worker.id, data);

      final updatedWorker = WorkerModel.fromJson(response).toEntity();
      return Success(updatedWorker);
    } catch (e, stackTrace) {
      return Failure(
        NetworkException(
          'Failed to update worker profile: $e',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<void>> changePassword(
    String workerId,
    String oldPassword,
    String newPassword,
  ) async {
    try {
      // Verify old password
      final workerResponse = await _dataSource.query('workers', {
        'id': workerId,
      });

      if (workerResponse == null) {
        return Failure(NotFoundException('Worker with id $workerId not found'));
      }

      final currentPassword = workerResponse['password'] as String?;
      if (currentPassword != oldPassword) {
        return const Failure(AuthException('Old password is incorrect'));
      }

      // Update password
      await _dataSource.update('workers', workerId, {'password': newPassword});

      return const Success(null);
    } catch (e, stackTrace) {
      return Failure(
        NetworkException(
          'Failed to change password: $e',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<List<Attendance>>> getAttendance(
    String workerId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      // Get worker's employee ID
      final workerResponse = await _dataSource.query('workers', {
        'id': workerId,
      });

      if (workerResponse == null) {
        return Failure(NotFoundException('Worker with id $workerId not found'));
      }

      // Assuming workers table has employee_id field
      final employeeId = workerResponse['employee_id'] as int?;
      if (employeeId == null) {
        return const Failure(
          ValidationException('Worker is not linked to an employee'),
        );
      }

      // Get attendance records
      final response = await _dataSource.client
          .from('attendance')
          .select()
          .eq('employee_id', employeeId)
          .gte('date', start.toIso8601String())
          .lte('date', end.toIso8601String())
          .order('date', ascending: false);

      final attendances = (response as List)
          .map((json) => AttendanceModel.fromJson(json).toEntity())
          .toList();

      return Success(attendances);
    } catch (e, stackTrace) {
      return Failure(
        NetworkException(
          'Failed to fetch worker attendance: $e',
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
