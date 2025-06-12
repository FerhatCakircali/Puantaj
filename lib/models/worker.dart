class Worker {
  final int? id;
  final int userId;
  final String fullName;
  final String? title;
  final String? phone;
  final String startDate;
  final DateTime? createdAt;

  Worker({
    this.id,
    required this.userId,
    required this.fullName,
    this.title,
    this.phone,
    required this.startDate,
    this.createdAt,
  });

  factory Worker.fromMap(Map<String, dynamic> map) {
    return Worker(
      id: map['id'],
      userId: map['user_id'],
      fullName: map['full_name'],
      title: map['title'],
      phone: map['phone'],
      startDate: map['start_date'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'full_name': fullName,
      if (title != null) 'title': title,
      if (phone != null) 'phone': phone,
      'start_date': startDate,
    };
  }
} 