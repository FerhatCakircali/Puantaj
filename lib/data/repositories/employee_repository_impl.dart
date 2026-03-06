import '../../core/error/result.dart';
import '../../core/error/exceptions.dart';
import '../../domain/entities/employee.dart';
import '../../domain/repositories/i_employee_repository.dart';
import '../datasources/supabase_datasource.dart';
import '../models/employee_model.dart';

/// Employee repository implementation
/// Implements IEmployeeRepository using Supabase as data source.
/// Handles all employee data operations with proper error handling.
class EmployeeRepositoryImpl implements IEmployeeRepository {
  final SupabaseDataSource _dataSource;

  EmployeeRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<Employee>>> getAll() async {
    try {
      final response = await _dataSource.queryList('employees');

      final employees = response
          .map((json) => EmployeeModel.fromJson(json).toEntity())
          .toList();

      return Success(employees);
    } catch (e, stackTrace) {
      return Failure(
        NetworkException(
          'Failed to fetch employees: $e',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<Employee>> getById(int id) async {
    try {
      final response = await _dataSource.query('employees', {'id': id});

      if (response == null) {
        return Failure(NotFoundException('Employee with id $id not found'));
      }

      final employee = EmployeeModel.fromJson(response).toEntity();
      return Success(employee);
    } catch (e, stackTrace) {
      return Failure(
        NetworkException(
          'Failed to fetch employee: $e',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<Employee>> create(Employee employee) async {
    try {
      final data = EmployeeModel.fromEntity(employee);

      // Remove id for insert operation
      final insertData = Map<String, dynamic>.from(data)..remove('id');

      final response = await _dataSource.insert('employees', insertData);

      final createdEmployee = EmployeeModel.fromJson(response).toEntity();
      return Success(createdEmployee);
    } catch (e, stackTrace) {
      return Failure(
        NetworkException(
          'Failed to create employee: $e',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<Employee>> update(Employee employee) async {
    try {
      final data = EmployeeModel.fromEntity(employee);

      final response = await _dataSource.update(
        'employees',
        employee.id.toString(),
        data,
      );

      final updatedEmployee = EmployeeModel.fromJson(response).toEntity();
      return Success(updatedEmployee);
    } catch (e, stackTrace) {
      return Failure(
        NetworkException(
          'Failed to update employee: $e',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<void>> delete(int id) async {
    try {
      await _dataSource.delete('employees', id.toString());
      return const Success(null);
    } catch (e, stackTrace) {
      return Failure(
        NetworkException(
          'Failed to delete employee: $e',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<List<Employee>>> search(String query) async {
    try {
      // Search by full name using ilike for case-insensitive search
      final response = await _dataSource.client
          .from('employees')
          .select()
          .ilike('full_name', '%$query%')
          .order('full_name');

      final employees = (response as List)
          .map((json) => EmployeeModel.fromJson(json).toEntity())
          .toList();

      return Success(employees);
    } catch (e, stackTrace) {
      return Failure(
        NetworkException(
          'Failed to search employees: $e',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<bool>> isUsernameExists(String username) async {
    try {
      final response = await _dataSource.client
          .from('workers')
          .select('username')
          .eq('username', username.toLowerCase())
          .maybeSingle();

      return Success(response != null);
    } catch (e, stackTrace) {
      return Failure(
        NetworkException(
          'Failed to check username: $e',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<bool>> isEmailExists(String email) async {
    try {
      final response = await _dataSource.client
          .from('workers')
          .select('email')
          .eq('email', email.toLowerCase())
          .maybeSingle();

      return Success(response != null);
    } catch (e, stackTrace) {
      return Failure(
        NetworkException('Failed to check email: $e', stackTrace: stackTrace),
      );
    }
  }
}
