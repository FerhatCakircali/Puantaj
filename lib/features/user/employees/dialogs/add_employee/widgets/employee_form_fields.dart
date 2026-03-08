import 'package:flutter/material.dart';

/// Çalışan formu için text field widget'ı
class EmployeeFormField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final String? errorText;
  final bool obscureText;
  final Widget? suffixIcon;
  final VoidCallback? onEditingComplete;

  const EmployeeFormField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.icon,
    required this.keyboardType,
    this.errorText,
    this.obscureText = false,
    this.suffixIcon,
    this.onEditingComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final fillColor = isDark
        ? colorScheme.surfaceContainerHighest
        : colorScheme.surfaceContainerHigh;
    const borderRadius = BorderRadius.all(Radius.circular(12));

    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        suffixIcon: suffixIcon,
        errorText: errorText,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      ),
      onEditingComplete:
          onEditingComplete ??
          () {
            FocusScope.of(context).nextFocus();
          },
    );
  }
}

/// Şifre alanı için özel widget
class PasswordFormField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final VoidCallback? onEditingComplete;

  const PasswordFormField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.obscureText,
    required this.onToggleVisibility,
    this.onEditingComplete,
  });

  @override
  Widget build(BuildContext context) {
    return EmployeeFormField(
      controller: controller,
      focusNode: focusNode,
      label: label,
      icon: Icons.lock_outline,
      keyboardType: TextInputType.visiblePassword,
      obscureText: obscureText,
      suffixIcon: IconButton(
        icon: Icon(
          obscureText
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
        ),
        onPressed: onToggleVisibility,
      ),
      onEditingComplete: onEditingComplete,
    );
  }
}
