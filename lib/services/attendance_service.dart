import '../models/attendance.dart';
import '../core/error_handling/error_handler_mixin.dart';
import '../core/di/service_locator.dart';
import 'auth_service.dart';
import 'attendance/repositories/attendance_repository.dart';
import 'shared/base_user_helper.dart';

/// Devam yönetimi servisi
class AttendanceService with ErrorHandlerMixin {
  final AttendanceRepository _repository;
  final BaseUserHelper _userHelper;

  AttendanceService({
    AuthService? authService,
    AttendanceRepository? repository,
    BaseUserHelper? userHelper,
  }) : _repository = repository ?? getIt<AttendanceRepository>(),
       _userHelper = userHelper ?? BaseUserHelper(authService ?? AuthService());

  Future<List<Attendance>> getAttendanceByDate(DateTime date) async {
    return handleError(
      () => _userHelper.executeWithUserId(
        (userId) => _repository.getAttendanceByDate(userId, date),
        defaultValue: [],
      ),
      [],
      context: 'AttendanceService.getAttendanceByDate',
    );
  }

  Future<List<Attendance>> getAttendanceBetween(
    DateTime startDate,
    DateTime endDate, {
    int? workerId,
  }) async {
    return handleError(
      () => _userHelper.executeWithUserId(
        (userId) => _repository.getAttendanceBetween(
          userId,
          startDate,
          endDate,
          workerId: workerId,
        ),
        defaultValue: [],
      ),
      [],
      context: 'AttendanceService.getAttendanceBetween',
    );
  }

  Future<void> markAttendance({
    required int workerId,
    required DateTime date,
    required AttendanceStatus status,
  }) async {
    return handleErrorWithThrow(
      () async => await _userHelper.executeWithUserIdOrThrow((userId) async {
        final data = {
          'user_id': userId,
          'worker_id': workerId,
          'date': date.toIso8601String().split('T')[0],
          'status': status == AttendanceStatus.fullDay ? 'fullDay' : 'halfDay',
        };
        await _repository.upsertAttendance(data);
      }),
      context: 'AttendanceService.markAttendance',
      userMessage: 'Devam kaydı eklenirken hata oluştu',
    );
  }

  Future<bool> deleteAttendance({
    required int workerId,
    required DateTime date,
  }) async {
    return handleError(
      () => _userHelper.executeWithUserId(
        (userId) => _repository.deleteAttendance(userId, workerId, date),
        defaultValue: false,
      ),
      false,
      context: 'AttendanceService.deleteAttendance',
    );
  }
}
