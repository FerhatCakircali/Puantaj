import '../../../core/error/result.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/employee.dart';
import '../../repositories/i_employee_repository.dart';
import '../usecase.dart';

/// Update employee use case
/// Validates input and updates existing employee.
/// Business rules:
/// - Employee must exist
/// - Full name cannot be empty
/// - Daily wage must be positive
/// - Email must be valid format (if provided)
/// - Phone must be valid format (if provided)
class UpdateEmployeeUseCase implements UseCase<Employee, Employee> {
  final IEmployeeRepository _repository;

  UpdateEmployeeUseCase(this._repository);

  @override
  Future<Result<Employee>> call(Employee employee) async {
    // Validate full name
    if (employee.fullName.trim().isEmpty) {
      return const Failure(ValidationException('Ad soyad boş olamaz'));
    }

    // Validate daily wage
    if (employee.dailyWage <= 0) {
      return const Failure(
        ValidationException('Günlük ücret pozitif bir değer olmalıdır'),
      );
    }

    // Validate email format (if provided)
    if (employee.email != null && employee.email!.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(employee.email!)) {
        return const Failure(ValidationException('Geçersiz email formatı'));
      }
    }

    // Validate phone format (if provided)
    if (employee.phone != null && employee.phone!.isNotEmpty) {
      final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
      if (!phoneRegex.hasMatch(employee.phone!)) {
        return const Failure(ValidationException('Geçersiz telefon formatı'));
      }
    }

    // Call repository
    return await _repository.update(employee);
  }
}
