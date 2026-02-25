import 'package:flutter/material.dart';
import '../../../../../../models/employee.dart';
import '../../../../../../screens/constants/colors.dart';

/// Ödeme dialog'u başlık widget'ı
class PaymentDialogHeader extends StatelessWidget {
  final Employee employee;
  final VoidCallback onClose;

  const PaymentDialogHeader({
    super.key,
    required this.employee,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryIndigo, primaryIndigo.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: primaryIndigo.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
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
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                if (employee.title.isNotEmpty)
                  Text(
                    employee.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(
              Icons.close,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
