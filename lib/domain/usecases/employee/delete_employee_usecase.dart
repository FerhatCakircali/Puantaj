import '../../../core/error/result.dart';
import '../../../core/error/exceptions.dart';
import '../../repositories/i_employee_repository.dart';
import '../usecase.dart';

/// Delete employee use case parameters
class DeleteEmployeeParams {
  final int employeeId;

  const DeleteEmployeeParams({required this.employeeId});
}

/// Delete employee use case
///
/// Deletes employee from system.
/// Business rules:
/// - Employee must exist
/// - Cannot delete employee with pending attendance records (future enhancement)
class DeleteEmployeeUseCase implements UseCase<void, DeleteEmployeeParams> {
  final IEmployeeRepository _repository;

  DeleteEmployeeUseCase(this._repository);

  @override
  Future<Result<void>> call(DeleteEmployeeParams params) async {
    // Validate employee ID
    if (params.employeeId <= 0) {
      return const Failure(ValidationException('Geçersiz çalışan ID'));
    }

    // Call repository
    return await _repository.delete(params.employeeId);
  }
}
