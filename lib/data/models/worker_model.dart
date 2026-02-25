import '../../domain/entities/worker.dart';

/// Worker data model
///
/// Maps database records to Worker domain entity.
class WorkerModel {
  final String id;
  final String username;
  final String fullName;
  final String? phone;
  final String? email;
  final bool isActive;
  final String createdAt;

  const WorkerModel({
    required this.id,
    required this.username,
    required this.fullName,
    this.phone,
    this.email,
    required this.isActive,
    required this.createdAt,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    return WorkerModel(
      id: json['id'].toString(),
      username: json['username'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] as String,
    );
  }

  Worker toEntity() {
    return Worker(
      id: id,
      username: username,
      fullName: fullName,
      phone: phone,
      email: email,
      isActive: isActive,
      createdAt: DateTime.parse(createdAt),
    );
  }

  static Map<String, dynamic> fromEntity(Worker worker) {
    return {
      'id': worker.id,
      'username': worker.username,
      'full_name': worker.fullName,
      'phone': worker.phone,
      'email': worker.email,
      'is_active': worker.isActive,
      'created_at': worker.createdAt.toIso8601String(),
    };
  }
}
