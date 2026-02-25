import '../../../domain/entities/attendance.dart';
import '../../../domain/usecases/attendance/get_attendance_usecase.dart';
import '../../../domain/usecases/attendance/create_attendance_usecase.dart';
import '../../../domain/usecases/attendance/update_attendance_usecase.dart';
import '../../../domain/usecases/attendance/approve_attendance_usecase.dart';
import '../../../core/error/result.dart';
import '../base_controller.dart';
import 'attendance_state.dart';

/// Devam kaydı controller'ı
///
/// Attendance işlemlerini yönetir ve state'i günceller.
class AttendanceController extends BaseController {
  final GetAttendanceUseCase _getAttendanceUseCase;
  final CreateAttendanceUseCase _createAttendanceUseCase;
  final UpdateAttendanceUseCase _updateAttendanceUseCase;
  final ApproveAttendanceUseCase _approveAttendanceUseCase;

  AttendanceState _state = AttendanceState.initial();

  AttendanceController({
    required GetAttendanceUseCase getAttendanceUseCase,
    required CreateAttendanceUseCase createAttendanceUseCase,
    required UpdateAttendanceUseCase updateAttendanceUseCase,
    required ApproveAttendanceUseCase approveAttendanceUseCase,
  }) : _getAttendanceUseCase = getAttendanceUseCase,
       _createAttendanceUseCase = createAttendanceUseCase,
       _updateAttendanceUseCase = updateAttendanceUseCase,
       _approveAttendanceUseCase = approveAttendanceUseCase;

  /// Mevcut state
  AttendanceState get state => _state;

  /// Devam kayıtlarını yükle
  Future<void> loadAttendance({
    int? employeeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    final params = GetAttendanceParams(
      employeeId: employeeId,
      startDate: startDate,
      endDate: endDate,
    );

    final result = await _getAttendanceUseCase.call(params);

    switch (result) {
      case Success(:final data):
        _state = _state.copyWith(records: data, isLoading: false);
      case Failure(:final exception):
        _state = _state.copyWith(
          errorMessage: exception.message,
          isLoading: false,
        );
    }

    notifyListeners();
  }

  /// Devam kaydı oluştur
  Future<void> createRecord({
    required int employeeId,
    required DateTime date,
    required double hoursWorked,
    String? notes,
  }) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    final params = CreateAttendanceParams(
      employeeId: employeeId,
      date: date,
      hoursWorked: hoursWorked,
      notes: notes,
    );

    final result = await _createAttendanceUseCase.call(params);

    switch (result) {
      case Success():
        // Listeyi yeniden yükle
        await loadAttendance(employeeId: employeeId);
      case Failure(:final exception):
        _state = _state.copyWith(
          errorMessage: exception.message,
          isLoading: false,
        );
        notifyListeners();
    }
  }

  /// Devam kaydı güncelle
  Future<void> updateRecord(Attendance attendance) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    final result = await _updateAttendanceUseCase.call(attendance);

    switch (result) {
      case Success():
        // Listeyi yeniden yükle
        await loadAttendance(employeeId: attendance.employeeId);
      case Failure(:final exception):
        _state = _state.copyWith(
          errorMessage: exception.message,
          isLoading: false,
        );
        notifyListeners();
    }
  }

  /// Devam kaydını onayla
  Future<void> approveRequest(int attendanceId, int employeeId) async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    final params = ApproveAttendanceParams(attendanceId: attendanceId);
    final result = await _approveAttendanceUseCase.call(params);

    switch (result) {
      case Success():
        // Listeyi yeniden yükle
        await loadAttendance(employeeId: employeeId);
      case Failure(:final exception):
        _state = _state.copyWith(
          errorMessage: exception.message,
          isLoading: false,
        );
        notifyListeners();
    }
  }

  /// Tarih seç
  void selectDate(DateTime date) {
    _state = _state.copyWith(selectedDate: date);
    notifyListeners();
  }
}
