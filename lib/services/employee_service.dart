import 'auth_service.dart';
import '../models/employee.dart';
import '../core/error_handling/error_handler_mixin.dart';
import '../core/di/service_locator.dart';
import 'employee/repositories/employee_repository.dart';
import 'employee/helpers/employee_cleanup_helper.dart';
import 'employee/helpers/employee_user_helper.dart';
import 'employee/validators/employee_validator.dart';

/// Çalışan yönetimi servisi
class EmployeeService with ErrorHandlerMixin {
  final EmployeeRepository _repository;
  final EmployeeCleanupHelper _cleanupHelper;
  final EmployeeUserHelper _userHelper;
  final EmployeeValidator _validator;

  EmployeeService({
    AuthService? authService,
    EmployeeRepository? repository,
    EmployeeCleanupHelper? cleanupHelper,
    EmployeeUserHelper? userHelper,
    EmployeeValidator? validator,
  }) : _repository = repository ?? getIt<EmployeeRepository>(),
       _cleanupHelper = cleanupHelper ?? EmployeeCleanupHelper(),
       _userHelper =
           userHelper ?? EmployeeUserHelper(authService ?? AuthService()),
       _validator = validator ?? getIt<EmployeeValidator>();

  /// Çalışanları getirir
  Future<List<Employee>> getEmployees() async {
    return handleError(
      () => _userHelper.executeWithUserId(
        (userId) => _repository.getEmployees(userId),
        defaultValue: [],
      ),
      [],
      context: 'EmployeeService.getEmployees',
    );
  }

  /// Çalışan ekler
  Future<int> addEmployee(Employee employee) async {
    return handleError(
      () => _userHelper.executeWithUserId(
        (userId) => _repository.addEmployee(employee, userId),
        defaultValue: -1,
      ),
      -1,
      context: 'EmployeeService.addEmployee',
    );
  }

  /// Çalışan günceller
  Future<int> updateEmployee(Employee employee) async {
    return handleError(
      () async => await _userHelper.executeWithUserId((userId) async {
        final success = await _repository.updateEmployee(employee, userId);
        return success ? 1 : -1;
      }, defaultValue: -1),
      -1,
      context: 'EmployeeService.updateEmployee',
    );
  }

  /// Çalışan siler
  Future<int> deleteEmployee(int id) async {
    return handleError(
      () async {
        _validator.validateEmployeeId(id);
        return await _userHelper.executeWithUserId((userId) async {
          final success = await _repository.deleteEmployee(id, userId);
          return success ? 1 : -1;
        }, defaultValue: -1);
      },
      -1,
      context: 'EmployeeService.deleteEmployee',
    );
  }

  /// Tüm çalışanları siler
  Future<int> deleteAllEmployees() async {
    return handleError(
      () async => await _userHelper.executeWithUserId((userId) async {
        await _cleanupHelper.deleteAllRelatedRecords(userId);
        final success = await _repository.deleteAllEmployees(userId);
        return success ? 1 : -1;
      }, defaultValue: -1),
      -1,
      context: 'EmployeeService.deleteAllEmployees',
    );
  }

  /// Belirli tarihten önce kayıt var mı kontrol eder
  Future<bool> hasRecordsBeforeDate(int workerId, DateTime date) async {
    return handleError(
      () async {
        _validator.validateEmployeeId(workerId);
        return await _userHelper.executeWithUserId(
          (userId) => _validator.hasRecordsBeforeDate(userId, workerId, date),
          defaultValue: false,
        );
      },
      false,
      context: 'EmployeeService.hasRecordsBeforeDate',
    );
  }

  /// Belirli tarihten önceki kayıtları siler
  Future<void> deleteRecordsBeforeDate(int workerId, DateTime date) async {
    return handleError(
      () async {
        _validator.validateEmployeeId(workerId);
        return await _userHelper.executeWithUserId(
          (userId) =>
              _cleanupHelper.deleteRecordsBeforeDate(userId, workerId, date),
          defaultValue: null,
        );
      },
      null,
      context: 'EmployeeService.deleteRecordsBeforeDate',
    );
  }
}
