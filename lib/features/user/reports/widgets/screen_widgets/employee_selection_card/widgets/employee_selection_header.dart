import 'package:flutter/material.dart';
import '../../../../../../../screens/constants/colors.dart';

/// Çalışan seçim kartı başlık widget'ı
class EmployeeSelectionHeader extends StatelessWidget {
  final bool isDark;

  const EmployeeSelectionHeader({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: primaryIndigo.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.person, color: primaryIndigo, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          'Çalışan Seçimi',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }
}
