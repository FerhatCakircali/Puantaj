import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Kayıt formu için özelleştirilmiş text field
class RegisterFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData prefixIcon;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;

  const RegisterFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.errorText,
    this.onChanged,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration(context).copyWith(errorText: errorText),
      validator: validator,
      keyboardType: keyboardType,
      maxLength: 30,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDecoration(BuildContext context) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(prefixIcon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }
}
