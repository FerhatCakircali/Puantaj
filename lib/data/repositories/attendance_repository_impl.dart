import '../../core/error/result.dart';
import '../../core/error/exceptions.dart';
import '../../domain/entities/attendance.dart';
import '../../domain/repositories/i_attendance_repository.dart';
import '../datasources/supabase_datasource.dart';
import '../models/attendance_model.dart';

/// Attendance repository implementation
///
/// Implements IAttendanceRepository using Supabase as data source.
/// Handles all attendance data operations with proper error handling.
class AttendanceRepositoryImpl implements IAttendanceRepository {
  final SupabaseDataSource _dataSource;

  AttendanceRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<Attendance>>> getByEmployee(int employeeId) async {
    try {
      final response = await _dataSource.queryList(
        'attendance',
        filters: {'employee_id': employeeId},
      );

      final attendances = response
          .map((json) => AttendanceModel.fromJson(json).toEntity())
          .toList();

      return Success(attendances);
    } catch (e, stackTrace) {
      return Failure(
        NetworkException(
          'Failed to fetch attendance records: $e',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<List<Attendance>>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    try {
      // Use client for complex date range query
      final response = await _dataSource.client
          .from('attendance')
          .select()
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
          'Failed to fetch attendance by date range: $e',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<Attendance>> create(Attendance attendance) async {
    try {
      final data = AttendanceModel.fromEntity(attendance);

      // Remove id for insert operation
      final insertData = Map<String, dynamic>.from(data)..remove('id');

      final response = await _dataSource.insert('attendance', insertData);

      final createdAttendance = AttendanceModel.fromJson(response).toEntity();
      return Success(createdAttendance);
    } catch (e, stackTrace) {
      return Failure(
        NetworkException(
          'Failed to create attendance record: $e',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<Attendance>> update(Attendance attendance) async {
    try {
      final data = AttendanceModel.fromEntity(attendance);

      final response = await _dataSource.update(
        'attendance',
        attendance.id.toString(),
        data,
      );

      final updatedAttendance = AttendanceModel.fromJson(response).toEntity();
      return Success(updatedAttendance);
    } catch (e, stackTrace) {
      return Failure(
        NetworkException(
          'Failed to update attendance record: $e',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<Attendance>> approve(int attendanceId) async {
    try {
      final response = await _dataSource.update(
        'attendance',
        attendanceId.toString(),
        {'status': 'approved'},
      );

      final approvedAttendance = AttendanceModel.fromJson(response).toEntity();
      return Success(approvedAttendance);
    } catch (e, stackTrace) {
      return Failure(
        NetworkException(
          'Failed to approve attendance: $e',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<Attendance>> reject(int attendanceId, String reason) async {
    try {
      final response = await _dataSource.update(
        'attendance',
        attendanceId.toString(),
        {'status': 'rejected', 'notes': reason},
      );

      final rejectedAttendance = AttendanceModel.fromJson(response).toEntity();
      return Success(rejectedAttendance);
    } catch (e, stackTrace) {
      return Failure(
        NetworkException(
          'Failed to reject attendance: $e',
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
