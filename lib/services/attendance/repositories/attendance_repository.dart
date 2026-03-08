import '../../../models/attendance.dart';
import '../../../utils/date_formatter.dart';
import '../../../core/repositories/base_supabase_repository.dart';
import '../../../core/constants/database_constants.dart';

/// Devam CRUD işlemlerini yöneten repository
class AttendanceRepository extends BaseSupabaseRepository {
  AttendanceRepository(super.supabase);

  Future<List<Attendance>> getAttendanceByDate(
    int userId,
    DateTime date,
  ) async {
    return executeQuery(
      () async {
        final formattedDate = DateFormatter.toIso8601Date(date);
        final results = await supabase
            .from(DatabaseConstants.attendanceTable)
            .select()
            .eq(DatabaseConstants.attendanceUserId, userId)
            .eq(DatabaseConstants.attendanceDate, formattedDate);
        return results
            .map<Attendance>((map) => Attendance.fromMap(map))
            .toList();
      },
      [],
      context: 'AttendanceRepository.getAttendanceByDate',
    );
  }

  Future<List<Attendance>> getAttendanceBetween(
    int userId,
    DateTime startDate,
    DateTime endDate, {
    int? workerId,
  }) async {
    return executeQuery(
      () async {
        final formattedStartDate = DateFormatter.toIso8601Date(startDate);
        final formattedEndDate = DateFormatter.toIso8601Date(endDate);

        var query = supabase
            .from(DatabaseConstants.attendanceTable)
            .select()
            .eq(DatabaseConstants.attendanceUserId, userId)
            .gte(DatabaseConstants.attendanceDate, formattedStartDate)
            .lte(DatabaseConstants.attendanceDate, formattedEndDate);

        if (workerId != null) {
          query = query.eq(DatabaseConstants.attendanceWorkerId, workerId);
        }

        final results = await query;
        return results
            .map<Attendance>((map) => Attendance.fromMap(map))
            .toList();
      },
      [],
      context: 'AttendanceRepository.getAttendanceBetween',
    );
  }

  Future<void> upsertAttendance(Map<String, dynamic> data) async {
    return executeQueryWithThrow(() async {
      await supabase
          .from(DatabaseConstants.attendanceTable)
          .upsert(data, onConflict: 'worker_id,date');
    }, context: 'AttendanceRepository.upsertAttendance');
  }

  Future<bool> deleteAttendance(int userId, int workerId, DateTime date) async {
    return executeQuery(
      () async {
        final formattedDate = DateFormatter.toIso8601Date(date);
        await supabase
            .from(DatabaseConstants.attendanceTable)
            .delete()
            .eq(DatabaseConstants.attendanceUserId, userId)
            .eq(DatabaseConstants.attendanceWorkerId, workerId)
            .eq(DatabaseConstants.attendanceDate, formattedDate);
        return true;
      },
      false,
      context: 'AttendanceRepository.deleteAttendance',
    );
  }
}
