import '../../domain/entities/employee.dart';

/// Employee data model
/// Maps database records to Employee domain entity.
class EmployeeModel {
  final int id;
  final String fullName;
  final String? phone;
  final String? email;
  final double dailyWage;
  final bool isActive;
  final String createdAt;

  const EmployeeModel({
    required this.id,
    required this.fullName,
    this.phone,
    this.email,
    required this.dailyWage,
    required this.isActive,
    required this.createdAt,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      dailyWage: (json['daily_wage'] as num).toDouble(),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String,
    );
  }

  Employee toEntity() {
    return Employee(
      id: id,
      fullName: fullName,
      phone: phone,
      email: email,
      dailyWage: dailyWage,
      isActive: isActive,
      createdAt: DateTime.parse(createdAt),
    );
  }

  static Map<String, dynamic> fromEntity(Employee employee) {
    return {
      'id': employee.id,
      'full_name': employee.fullName,
      'phone': employee.phone,
      'email': employee.email,
      'daily_wage': employee.dailyWage,
      'is_active': employee.isActive,
      'created_at': employee.createdAt.toIso8601String(),
    };
  }
}
