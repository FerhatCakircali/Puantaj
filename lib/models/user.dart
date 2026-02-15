class User {
  final int id;
  final String username;
  final String password;
  final String firstName;
  final String lastName;
  final String jobTitle;
  final bool isAdmin;
  final bool isBlocked;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.jobTitle,
    required this.isAdmin,
    required this.isBlocked,
    this.createdAt,
  });

  factory User.fromMap(Map<String, dynamic> json) => User(
    id: json['id'] as int,
    username: json['username'] as String,
    password: json['password'] as String,
    firstName: json['first_name'] as String,
    lastName: json['last_name'] as String,
    jobTitle: json['job_title'] as String,
    isAdmin: (json['is_admin'] as int? ?? 0) == 1,
    isBlocked: json['is_blocked'] as bool,
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : null,
  );

  Map<String, dynamic> toMap() => {
    if (id != 0) 'id': id,
    'username': username,
    'password': password,
    'first_name': firstName,
    'last_name': lastName,
    'job_title': jobTitle,
    'is_admin': isAdmin ? 1 : 0,
    'is_blocked': isBlocked,
  };

  // Backward compatibility with existing code
  factory User.fromJson(Map<String, dynamic> json) => User.fromMap(json);

  Map<String, dynamic> toJson() => toMap();
}
