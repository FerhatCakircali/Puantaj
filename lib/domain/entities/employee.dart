/// Employee domain entity
///
/// Represents an employee in the attendance tracking system.
/// Independent of any data source or UI framework.
class Employee {
  final int id;
  final String fullName;
  final String? phone;
  final String? email;
  final double dailyWage;
  final bool isActive;
  final DateTime createdAt;

  const Employee({
    required this.id,
    required this.fullName,
    this.phone,
    this.email,
    required this.dailyWage,
    required this.isActive,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Employee && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Employee(id: $id, fullName: $fullName, isActive: $isActive)';
}
