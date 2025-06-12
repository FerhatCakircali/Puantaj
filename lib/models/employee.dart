class Employee {
  final int id;
  final String name;
  final String title;
  final String phone;
  final DateTime startDate;

  Employee({
    required this.id,
    required this.name,
    required this.title,
    required this.phone,
    required this.startDate,
  });

  Employee copyWith({
    int? id,
    String? name,
    String? title,
    String? phone,
    DateTime? startDate,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      phone: phone ?? this.phone,
      startDate: startDate ?? this.startDate,
    );
  }

  factory Employee.fromMap(Map<String, dynamic> map) => Employee(
    id: map['id'] as int,
    name: map['full_name'] as String,
    title: map['title'] as String? ?? '',
    phone: map['phone'] as String? ?? '',
    startDate: DateTime.parse(
      map['start_date'] as String? ?? DateTime.now().toIso8601String(),
    ),
  );

  Map<String, dynamic> toMap() => {
    if (id != 0) 'id': id,
    'full_name': name,
    'title': title,
    'phone': phone,
    'start_date': startDate.toIso8601String(),
  };

  // For backward compatibility
  factory Employee.fromJson(Map<String, dynamic> json) =>
      Employee.fromMap(json);
  Map<String, dynamic> toJson() => toMap();
}
