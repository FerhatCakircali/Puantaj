import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Profil form alanı konfigürasyonu
///
/// Form field'larının özelliklerini tanımlar
class ProfileFieldConfig {
  final String label;
  final String? hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int? maxLength;
  final bool isRequired;
  final MaxLengthEnforcement? maxLengthEnforcement;

  const ProfileFieldConfig({
    required this.label,
    this.hint,
    required this.icon,
    this.keyboardType,
    this.maxLength,
    this.isRequired = false,
    this.maxLengthEnforcement,
  });
}
