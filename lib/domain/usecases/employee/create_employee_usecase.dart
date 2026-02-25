import '../../../core/error/result.dart';
import '../../../core/error/exceptions.dart';
import '../../entities/employee.dart';
import '../../repositories/i_employee_repository.dart';
import '../usecase.dart';

/// Create employee use case parameters
class CreateEmployeeParams {
  final String fullName;
  final String? phone;
  final String? email;
  final double dailyWage;

  const CreateEmployeeParams({
    required this.fullName,
    this.phone,
    this.email,
    required this.dailyWage,
  });
}

/// Create employee use case
///
/// Validates input and creates new employee.
/// Business rules:
/// - Full name cannot be empty
/// - Daily wage must be positive
/// - Email must be valid format (if provided)
/// - Phone must be valid format (if provided)
class CreateEmployeeUseCase implements UseCase<Employee, CreateEmployeeParams> {
  final IEmployeeRepository _repository;

  CreateEmployeeUseCase(this._repository);

  @override
  Future<Result<Employee>> call(CreateEmployeeParams params) async {
    // Validate full name
    if (params.fullName.trim().isEmpty) {
      return const Failure(ValidationException('Ad soyad boş olamaz'));
    }

    // Validate daily wage
    if (params.dailyWage <= 0) {
      return const Failure(
        ValidationException('Günlük ücret pozitif bir değer olmalıdır'),
      );
    }

    // Validate email format (if provided)
    if (params.email != null && params.email!.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(params.email!)) {
        return const Failure(ValidationException('Geçersiz email formatı'));
      }
    }

    // Validate phone format (if provided)
    if (params.phone != null && params.phone!.isNotEmpty) {
      final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
      if (!phoneRegex.hasMatch(params.phone!)) {
        return const Failure(ValidationException('Geçersiz telefon formatı'));
      }
    }

    // Create employee entity
    final employee = Employee(
      id: 0, // Will be assigned by database
      fullName: params.fullName.trim(),
      phone: params.phone?.trim(),
      email: params.email?.trim(),
      dailyWage: params.dailyWage,
      isActive: true,
      createdAt: DateTime.now(),
    );

    // Call repository
    return await _repository.create(employee);
  }
}
