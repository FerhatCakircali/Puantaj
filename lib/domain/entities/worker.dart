/// Worker domain entity
/// Represents a worker (employee with login credentials) in the system.
/// Independent of any data source or UI framework.
class Worker {
  final String id;
  final String username;
  final String fullName;
  final String? phone;
  final String? email;
  final bool isActive;
  final DateTime createdAt;

  const Worker({
    required this.id,
    required this.username,
    required this.fullName,
    this.phone,
    this.email,
    required this.isActive,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Worker && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Worker(id: $id, username: $username, fullName: $fullName)';
}
