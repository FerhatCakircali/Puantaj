import 'package:flutter/material.dart';
import '../../../../screens/constants/colors.dart';
import '../models/profile_field_config.dart';

/// Generic profil text field widget'ı
///
/// Tüm profil form alanları için kullanılır
class ProfileTextField extends StatelessWidget {
  final TextEditingController controller;
  final ProfileFieldConfig config;
  final String? errorText;
  final ThemeData theme;
  final bool isDark;
  final double screenWidth;

  const ProfileTextField({
    super.key,
    required this.controller,
    required this.config,
    this.errorText,
    required this.theme,
    required this.isDark,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: config.isRequired ? '${config.label} *' : config.label,
        hintText: config.hint,
        errorText: errorText,
        prefixIcon: Icon(
          config.icon,
          color: isDark
              ? Colors.white.withValues(alpha: 0.7)
              : theme.colorScheme.primary,
          size: screenWidth * 0.055,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          borderSide: BorderSide(color: primaryIndigo, width: 2),
        ),
        errorBorder: errorText != null
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                borderSide: BorderSide(color: theme.colorScheme.error),
              )
            : null,
        focusedErrorBorder: errorText != null
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                borderSide: BorderSide(
                  color: theme.colorScheme.error,
                  width: 2,
                ),
              )
            : null,
        counterStyle: config.maxLength != null
            ? TextStyle(fontSize: screenWidth * 0.028)
            : null,
      ),
      style: TextStyle(fontSize: screenWidth * 0.038),
      keyboardType: config.keyboardType,
      maxLength: config.maxLength,
      maxLengthEnforcement: config.maxLengthEnforcement,
    );
  }
}
