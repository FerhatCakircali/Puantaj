import '../../domain/entities/user.dart';

/// User data model
/// Maps database records to User domain entity.
/// Handles type conversions and data transformations.
class UserModel {
  final int id;
  final String username;
  final String fullName;
  final dynamic isAdmin; // Can be int or bool from database
  final String createdAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.fullName,
    required this.isAdmin,
    required this.createdAt,
  });

  /// Create from JSON (database response)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      fullName: json['full_name'] as String,
      isAdmin: json['is_admin'],
      createdAt: json['created_at'] as String,
    );
  }

  /// Convert to domain entity
  User toEntity() {
    bool isAdminBool = false;
    if (isAdmin is int) {
      isAdminBool = isAdmin == 1;
    } else if (isAdmin is bool) {
      isAdminBool = isAdmin;
    }

    return User(
      id: id,
      username: username,
      fullName: fullName,
      isAdmin: isAdminBool || username.toLowerCase() == 'admin',
      createdAt: DateTime.parse(createdAt),
    );
  }

  /// Convert from domain entity
  static Map<String, dynamic> fromEntity(User user) {
    return {
      'id': user.id,
      'username': user.username,
      'full_name': user.fullName,
      'is_admin': user.isAdmin,
      'created_at': user.createdAt.toIso8601String(),
    };
  }
}
