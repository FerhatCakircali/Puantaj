class User {
  final String id;
  final String email;
  final String username;
  final bool isBlocked;

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.isBlocked,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'].toString(),
    email: json['email'] as String,
    username: json['username'] as String,
    isBlocked: json['is_blocked'] as bool,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'username': username,
    'is_blocked': isBlocked,
  };
}
