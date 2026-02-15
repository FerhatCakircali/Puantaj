import 'worker.dart';

/// Employee model - compatibility wrapper around Worker
/// Prefer using Worker instead. This class exists for backward compatibility.
/// 
/// Maps DateTime-based properties to/from Worker's string-based properties
/// (e.g., DateTime startDate <-> String startDate in 'YYYY-MM-DD' format)
class Employee {
  final int id;
  final int userId; // Made optional since it may not always be available at construction time
  final String name;
  final String title;
  final String phone;
  final DateTime startDate;
  final DateTime? createdAt;

  Employee({
    required this.id,
    required this.name,
    required this.title,
    required this.phone,
    required this.startDate,
    this.userId = 0, // Default to 0 if not provided, will be set later
    this.createdAt,
  });

  Employee copyWith({
    int? id,
    String? name,
    String? title,
    String? phone,
    DateTime? startDate,
    int? userId,
    DateTime? createdAt,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      phone: phone ?? this.phone,
      startDate: startDate ?? this.startDate,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert from Worker model (consolidation support)
  factory Employee.fromWorker(Worker worker) => Employee(
    id: worker.id ?? 0,
    userId: worker.userId,
    name: worker.fullName,
    title: worker.title ?? '',
    phone: worker.phone ?? '',
    startDate: DateTime.parse(worker.startDate),
    createdAt: worker.createdAt,
  );

  /// Convert to Worker model (consolidation support)
  Worker toWorker() => Worker(
    id: id != 0 ? id : null,
    userId: userId,
    fullName: name,
    title: title.isNotEmpty ? title : null,
    phone: phone.isNotEmpty ? phone : null,
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
    startDate: DateTime.parse(
      map['start_date'] as String? ?? DateTime.now().toIso8601String(),
    ),
    createdAt: map['created_at'] != null
        ? DateTime.parse(map['created_at'] as String)
        : null,
  );

  Map<String, dynamic> toMap() => {
    if (id != 0) 'id': id,
    'user_id': userId,
    'full_name': name,
    'title': title,
    'phone': phone,
    'start_date':
        '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
  };

  // For backward compatibility
  factory Employee.fromJson(Map<String, dynamic> json) =>
      Employee.fromMap(json);
  Map<String, dynamic> toJson() => toMap();
}
