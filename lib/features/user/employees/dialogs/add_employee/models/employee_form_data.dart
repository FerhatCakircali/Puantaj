/// Çalışan formu için veri modeli
class EmployeeFormData {
  final String name;
  final String title;
  final String phone;
  final String email;
  final String username;
  final String password;
  final DateTime startDate;

  const EmployeeFormData({
    required this.name,
    required this.title,
    required this.phone,
    required this.email,
    required this.username,
    required this.password,
    required this.startDate,
  });

  bool get isValid =>
      name.isNotEmpty &&
      title.isNotEmpty &&
      phone.isNotEmpty &&
      email.isNotEmpty &&
      username.isNotEmpty &&
      password.isNotEmpty;
}
