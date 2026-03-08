import 'package:flutter/material.dart';
import '../../../../../../../screens/constants/colors.dart';

/// Çalışan özel rapor toggle widget'ı
class EmployeeSpecificToggle extends StatelessWidget {
  final bool isEmployeeSpecific;
  final Function(bool) onChanged;
  final bool isDark;

  const EmployeeSpecificToggle({
    super.key,
    required this.isEmployeeSpecific,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Belirli bir çalışan için rapor',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEmployeeSpecific
                      ? 'Seçili çalışan için rapor oluşturulacak'
                      : 'Tüm çalışanlar için rapor oluşturulacak',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: isEmployeeSpecific,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: primaryIndigo,
            inactiveThumbColor: isDark ? Colors.grey.shade300 : Colors.white,
            inactiveTrackColor: isDark
                ? Colors.grey.shade800
                : Colors.grey.shade400,
            trackOutlineColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.transparent;
              }
              return isDark ? Colors.grey.shade600 : Colors.grey.shade500;
            }),
          ),
        ],
      ),
    );
  }
}
