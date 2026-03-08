import 'package:flutter/material.dart';
import '../../../../../../../models/employee.dart';
import '../../../../../../../screens/constants/colors.dart';

/// Çalışan liste öğesi widget'ı
class EmployeeListItem extends StatelessWidget {
  final Employee employee;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const EmployeeListItem({
    super.key,
    required this.employee,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryIndigo.withValues(alpha: 0.1)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? primaryIndigo
                : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryIndigo
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  employee.name[0].toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    employee.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  if (employee.title.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      employee.title,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: primaryIndigo, size: 20),
          ],
        ),
      ),
    );
  }
}
