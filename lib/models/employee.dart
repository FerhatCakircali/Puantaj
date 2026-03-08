import 'worker.dart';

/// Employee model - compatibility wrapper around Worker
/// Prefer using Worker instead. This class exists for backward compatibility.
/// Maps DateTime-based properties to/from Worker's string-based properties
/// (e.g., DateTime startDate <-> String startDate in 'YYYY-MM-DD' format)
class Employee {
  final int id;
  final int
  userId; // Made optional since it may not always be available at construction time
  final String name;
  final String title;
  final String phone;
  final String? email;
  final DateTime startDate;
  final DateTime? createdAt;
  final String? username;
  final String? password;
  final bool isActive;
  final bool isTrusted;

  Employee({
    required this.id,
    required this.name,
    required this.title,
    required this.phone,
    required this.startDate,
    this.userId = 0, // Default to 0 if not provided, will be set later
    this.email,
    this.createdAt,
    this.username,
    this.password,
    this.isActive = true,
    this.isTrusted = false,
  });

  Employee copyWith({
    int? id,
    String? name,
    String? title,
    String? phone,
    String? email,
    DateTime? startDate,
    int? userId,
    DateTime? createdAt,
    String? username,
    String? password,
    bool? isActive,
    bool? isTrusted,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      startDate: startDate ?? this.startDate,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      username: username ?? this.username,
      password: password ?? this.password,
      isActive: isActive ?? this.isActive,
      isTrusted: isTrusted ?? this.isTrusted,
    );
  }

  /// Convert from Worker model (consolidation support - old model)
  factory Employee.fromWorker(Worker worker) => Employee(
    id: worker.id ?? 0,
    userId: worker.userId,
    username: worker.username,
    name: worker.fullName,
    title: worker.title ?? '',
    phone: worker.phone ?? '',
    email: worker.email,
    startDate: DateTime.parse(worker.startDate),
    createdAt: worker.createdAt,
    isActive: true, // Default for old model
    isTrusted: false, // Default for old model
  );

  /// Employee modelini Worker modeline dönüştürür
  Worker toWorker() => Worker(
    id: id != 0 ? id : null,
    userId: userId,
    username: username ?? '',
    fullName: name,
    title: title.isNotEmpty ? title : null,
    phone: phone.isNotEmpty ? phone : null,
    email: email,
    startDate:
        '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
    createdAt: createdAt,
  );

  factory Employee.fromMap(Map<String, dynamic> map) => Employee(
    id: map['id'] as int,
    userId: map['user_id'] as int? ?? 0,
    name: map['full_name'] as String,
    title: map['title'] as String? ?? '',
    phone: map['phone'] as String? ?? '',
    email: map['email'] as String?,
    startDate: DateTime.parse(
      map['start_date'] as String? ?? DateTime.now().toIso8601String(),
    ),
    createdAt: map['created_at'] != null
        ? DateTime.parse(map['created_at'] as String)
        : null,
    username: map['username'] as String?,
    isActive: map['is_active'] as bool? ?? true,
    isTrusted: map['is_trusted'] as bool? ?? false,
  );

  Map<String, dynamic> toMap() => {
    if (id != 0) 'id': id,
    'user_id': userId,
    'full_name': name,
    'title': title,
    'phone': phone,
    if (email != null) 'email': email,
    'start_date':
        '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
    'is_active': isActive,
    'is_trusted': isTrusted,
  };

  // For backward compatibility
  factory Employee.fromJson(Map<String, dynamic> json) =>
      Employee.fromMap(json);
  Map<String, dynamic> toJson() => toMap();
}
