import '../../../models/employee.dart';
import '../../../core/repositories/base_supabase_repository.dart';
import '../../../core/error_logger.dart';
import '../../../core/constants/database_constants.dart';

/// Çalışan CRUD işlemlerini yöneten repository
class EmployeeRepository extends BaseSupabaseRepository {
  EmployeeRepository(super.supabase);

  /// Çalışanları getirir
  Future<List<Employee>> getEmployees(int userId) async {
    try {
      final res = await supabase
          .from(DatabaseConstants.workersTable)
          .select()
          .eq(DatabaseConstants.workerUserId, userId)
          .order(DatabaseConstants.workerFullName);

      return res.map((map) => Employee.fromMap(map)).toList();
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'EmployeeRepository.getEmployees hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Çalışan ekler
  Future<int> addEmployee(Employee employee, int userId) async {
    try {
      final map = employee.toMap();
      map[DatabaseConstants.workerUserId] = userId;

      final result = await supabase
          .from(DatabaseConstants.workersTable)
          .insert(map)
          .select(DatabaseConstants.workerId)
          .single();

      return result[DatabaseConstants.workerId] as int;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'EmployeeRepository.addEmployee hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return -1;
    }
  }

  /// Çalışan günceller
  Future<bool> updateEmployee(Employee employee, int userId) async {
    try {
      await supabase
          .from(DatabaseConstants.workersTable)
          .update(employee.toMap())
          .eq(DatabaseConstants.workerId, employee.id)
          .eq(DatabaseConstants.workerUserId, userId);

      return true;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'EmployeeRepository.updateEmployee hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Çalışan siler
  Future<bool> deleteEmployee(int id, int userId) async {
    try {
      await supabase
          .from(DatabaseConstants.workersTable)
          .delete()
          .eq(DatabaseConstants.workerId, id)
          .eq(DatabaseConstants.workerUserId, userId);

      return true;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'EmployeeRepository.deleteEmployee hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Tüm çalışanları siler
  Future<bool> deleteAllEmployees(int userId) async {
    try {
      await supabase
          .from(DatabaseConstants.workersTable)
          .delete()
          .eq(DatabaseConstants.workerUserId, userId);
      return true;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'EmployeeRepository.deleteAllEmployees hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
