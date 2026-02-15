import 'package:flutter/material.dart';

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final Iterable<String>? autofillHints;

  const PasswordField({
    Key? key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.validator,
    this.autofillHints,
  }) : super(key: key);

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      validator: widget.validator,
      autofillHints: widget.autofillHints,
      decoration: InputDecoration(
        labelText: widget.labelText ?? 'Password',
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.lock_outline), // Buraya ikon eklendi
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withOpacity(0.5), // Her zaman görünür border
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color:
                Theme.of(
                  context,
                ).colorScheme.primary, // Focus olunca temanın ana rengi
            width: 2,
          ),
        ),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
