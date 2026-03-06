/// User domain entity
/// Represents a user in the system (admin or regular user).
/// Independent of any data source or UI framework.
class User {
  final int id;
  final String username;
  final String fullName;
  final bool isAdmin;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.isAdmin,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          username == other.username;

  @override
  int get hashCode => id.hashCode ^ username.hashCode;

  @override
  String toString() => 'User(id: $id, username: $username, isAdmin: $isAdmin)';
}
