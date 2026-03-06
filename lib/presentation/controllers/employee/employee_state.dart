import '../../../domain/entities/employee.dart';

/// Çalışan yönetimi state'i
/// Employee ekranının durumunu yönetir.
class EmployeeState {
  final List<Employee> employees;
  final bool isLoading;
  final String? errorMessage;

  const EmployeeState({
    this.employees = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  /// Initial state
  factory EmployeeState.initial() => const EmployeeState();

  /// Loading state
  EmployeeState copyWithLoading() =>
      EmployeeState(employees: employees, isLoading: true, errorMessage: null);

  /// Success state
  EmployeeState copyWithEmployees(List<Employee> employees) =>
      EmployeeState(employees: employees, isLoading: false, errorMessage: null);

  /// Error state
  EmployeeState copyWithError(String error) => EmployeeState(
    employees: employees,
    isLoading: false,
    errorMessage: error,
  );
}
