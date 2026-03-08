import 'package:flutter/material.dart';
import '../../../../../../../screens/constants/colors.dart';

/// Şifre giriş alanı widget'ı
class PasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const PasswordTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return TextField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: Icon(
          widget.icon,
          color: isDark ? Colors.white.withValues(alpha: 0.7) : primaryIndigo,
          size: screenWidth * 0.055,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isVisible ? Icons.visibility : Icons.visibility_off,
            size: screenWidth * 0.055,
          ),
          onPressed: () => setState(() => _isVisible = !_isVisible),
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
          borderSide: const BorderSide(color: primaryIndigo, width: 2),
        ),
      ),
      style: TextStyle(fontSize: screenWidth * 0.038),
      obscureText: !_isVisible,
    );
  }
}
