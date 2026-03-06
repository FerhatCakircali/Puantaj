import '../../../core/error/result.dart';
import '../../entities/employee.dart';
import '../../repositories/i_employee_repository.dart';
import '../usecase.dart';

/// Get employees use case
/// Fetches all employees and applies business rules.
/// Business rules:
/// - Sort by full name alphabetically
/// - Filter out inactive employees (optional)
class GetEmployeesUseCase implements UseCase<List<Employee>, NoParams> {
  final IEmployeeRepository _repository;

  GetEmployeesUseCase(this._repository);

  @override
  Future<Result<List<Employee>>> call(NoParams params) async {
    // Fetch employees from repository
    final result = await _repository.getAll();

    // Apply business rules if successful
    if (result is Success<List<Employee>>) {
      // Sort by full name
      final sortedEmployees = List<Employee>.from(result.data)
        ..sort((a, b) => a.fullName.compareTo(b.fullName));

      return Success(sortedEmployees);
    }

    return result;
  }
}
