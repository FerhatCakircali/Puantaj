import '../../../domain/entities/employee.dart';
import '../../../domain/usecases/employee/get_employees_usecase.dart';
import '../../../domain/usecases/employee/create_employee_usecase.dart';
import '../../../domain/usecases/employee/update_employee_usecase.dart';
import '../../../domain/usecases/employee/delete_employee_usecase.dart';
import '../../../domain/usecases/usecase.dart';
import '../../../core/error/result.dart';
import '../base_controller.dart';
import 'employee_state.dart';

/// Çalışan yönetimi controller'ı
///
/// Employee işlemlerini yönetir ve state'i günceller.
class EmployeeController extends BaseController {
  final GetEmployeesUseCase _getEmployeesUseCase;
  final CreateEmployeeUseCase _createEmployeeUseCase;
  final UpdateEmployeeUseCase _updateEmployeeUseCase;
  final DeleteEmployeeUseCase _deleteEmployeeUseCase;

  EmployeeState _state = EmployeeState.initial();

  EmployeeController({
    required GetEmployeesUseCase getEmployeesUseCase,
    required CreateEmployeeUseCase createEmployeeUseCase,
    required UpdateEmployeeUseCase updateEmployeeUseCase,
    required DeleteEmployeeUseCase deleteEmployeeUseCase,
  }) : _getEmployeesUseCase = getEmployeesUseCase,
       _createEmployeeUseCase = createEmployeeUseCase,
       _updateEmployeeUseCase = updateEmployeeUseCase,
       _deleteEmployeeUseCase = deleteEmployeeUseCase;

  /// Mevcut state
  EmployeeState get state => _state;

  /// Çalışanları yükle
  Future<void> loadEmployees() async {
    _state = _state.copyWithLoading();
    notifyListeners();

    final result = await _getEmployeesUseCase.call(const NoParams());

    switch (result) {
      case Success(:final data):
        _state = _state.copyWithEmployees(data);
      case Failure(:final exception):
        _state = _state.copyWithError(exception.message);
    }

    notifyListeners();
  }

  /// Çalışan oluştur
  Future<void> createEmployee({
    required String fullName,
    String? phone,
    String? email,
    required double dailyWage,
  }) async {
    _state = _state.copyWithLoading();
    notifyListeners();

    final params = CreateEmployeeParams(
      fullName: fullName,
      phone: phone,
      email: email,
      dailyWage: dailyWage,
    );

    final result = await _createEmployeeUseCase.call(params);

    switch (result) {
      case Success():
        // Listeyi yeniden yükle
        await loadEmployees();
      case Failure(:final exception):
        _state = _state.copyWithError(exception.message);
        notifyListeners();
    }
  }

  /// Çalışan güncelle
  Future<void> updateEmployee(Employee employee) async {
    _state = _state.copyWithLoading();
    notifyListeners();

    final result = await _updateEmployeeUseCase.call(employee);

    switch (result) {
      case Success():
        // Listeyi yeniden yükle
        await loadEmployees();
      case Failure(:final exception):
        _state = _state.copyWithError(exception.message);
        notifyListeners();
    }
  }

  /// Çalışan sil
  Future<void> deleteEmployee(int employeeId) async {
    _state = _state.copyWithLoading();
    notifyListeners();

    final params = DeleteEmployeeParams(employeeId: employeeId);
    final result = await _deleteEmployeeUseCase.call(params);

    switch (result) {
      case Success():
        // Listeyi yeniden yükle
        await loadEmployees();
      case Failure(:final exception):
        _state = _state.copyWithError(exception.message);
        notifyListeners();
    }
  }
}
