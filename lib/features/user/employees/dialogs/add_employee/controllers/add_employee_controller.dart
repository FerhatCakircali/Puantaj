import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../../models/employee.dart';
import '../../../../../../data/services/password_hasher.dart';
import '../validators/employee_form_validator.dart';
import '../models/employee_form_data.dart';

/// Çalışan ekleme dialog'unun state ve business logic'ini yöneten controller
class AddEmployeeController {
  final nameController = TextEditingController();
  final titleController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordConfirmController = TextEditingController();

  final nameFocus = FocusNode();
  final titleFocus = FocusNode();
  final phoneFocus = FocusNode();
  final emailFocus = FocusNode();
  final usernameFocus = FocusNode();
  final passFocus = FocusNode();
  final pass2Focus = FocusNode();

  final scrollController = ScrollController();

  DateTime selectedDate = DateTime.now();
  bool obscurePassword = true;
  bool obscurePasswordConfirm = true;

  late final EmployeeFormValidator validator;

  final void Function() onStateChanged;

  AddEmployeeController({
    required Future<bool> Function(String) onCheckUsername,
    required Future<bool> Function(String) onCheckEmail,
    required this.onStateChanged,
  }) {
    validator = EmployeeFormValidator(
      onCheckUsername: onCheckUsername,
      onCheckEmail: onCheckEmail,
      onStateChanged: onStateChanged,
    );

    usernameController.addListener(_onUsernameChanged);
    emailController.addListener(_onEmailChanged);
  }

  void dispose() {
    validator.dispose();

    usernameController.removeListener(_onUsernameChanged);
    emailController.removeListener(_onEmailChanged);

    nameController.dispose();
    titleController.dispose();
    phoneController.dispose();
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    passwordConfirmController.dispose();

    nameFocus.dispose();
    titleFocus.dispose();
    phoneFocus.dispose();
    emailFocus.dispose();
    usernameFocus.dispose();
    passFocus.dispose();
    pass2Focus.dispose();

    scrollController.dispose();
  }

  void _onUsernameChanged() {
    validator.validateUsername(usernameController.text.trim());
  }

  void _onEmailChanged() {
    validator.validateEmail(emailController.text.trim());
  }

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    onStateChanged();
  }

  void togglePasswordConfirmVisibility() {
    obscurePasswordConfirm = !obscurePasswordConfirm;
    onStateChanged();
  }

  void updateSelectedDate(DateTime date) {
    selectedDate = date;
    onStateChanged();
  }

  EmployeeFormData getFormData() {
    return EmployeeFormData(
      name: nameController.text.trim(),
      title: titleController.text.trim(),
      phone: phoneController.text.trim(),
      email: emailController.text.trim().toLowerCase(),
      username: usernameController.text.trim().toLowerCase(),
      password: passwordController.text.trim(),
      startDate: selectedDate,
    );
  }

  Future<String?> validateAndPrepare() async {
    final formError = validator.validateForm(
      name: nameController.text.trim(),
      title: titleController.text.trim(),
      phone: phoneController.text.trim(),
      email: emailController.text.trim(),
      username: usernameController.text.trim(),
      password: passwordController.text.trim(),
      passwordConfirm: passwordConfirmController.text.trim(),
    );

    if (formError != null) return formError;

    final uniquenessError = await validator.validateUniqueness(
      username: usernameController.text.trim(),
      email: emailController.text.trim(),
    );

    return uniquenessError;
  }

  Future<Employee> createEmployee() async {
    final formData = getFormData();
    final passwordHasher = PasswordHasher.instance;
    final passwordHash = await passwordHasher.hashPassword(formData.password);

    return Employee(
      id: 0,
      name: formData.name,
      title: formData.title,
      phone: formData.phone,
      email: formData.email,
      startDate: formData.startDate,
      username: formData.username,
      password: passwordHash,
    );
  }
}
