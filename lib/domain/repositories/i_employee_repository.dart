import '../../core/error/result.dart';
import '../entities/employee.dart';

/// Employee repository interface
///
/// Defines contract for employee data operations.
abstract class IEmployeeRepository {
  /// Get all employees
  Future<Result<List<Employee>>> getAll();

  /// Get employee by ID
  Future<Result<Employee>> getById(int id);

  /// Create new employee
  Future<Result<Employee>> create(Employee employee);

  /// Update existing employee
  Future<Result<Employee>> update(Employee employee);

  /// Delete employee by ID
  Future<Result<void>> delete(int id);

  /// Search employees by name
  Future<Result<List<Employee>>> search(String query);

  /// Check if username already exists
  Future<Result<bool>> isUsernameExists(String username);

  /// Check if email already exists
  Future<Result<bool>> isEmailExists(String email);
}
