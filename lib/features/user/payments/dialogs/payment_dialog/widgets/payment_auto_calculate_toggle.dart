import 'package:flutter/material.dart';
import '../../../../../../screens/constants/colors.dart';

/// Ödeme dialog'unda otomatik hesaplama toggle'ı
/// Günlük ücret ile otomatik hesaplama özelliğini açıp kapatır
class PaymentAutoCalculateToggle extends StatelessWidget {
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const PaymentAutoCalculateToggle({
    super.key,
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onChanged(!isEnabled),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isEnabled
                ? primaryIndigo.withValues(alpha: 0.3)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.shade200),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            _buildIcon(isDark),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Günlük ücret ile hesapla',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            _buildToggleSwitch(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(bool isDark) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isEnabled
            ? primaryIndigo.withValues(alpha: 0.15)
            : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        Icons.calculate_outlined,
        color: isEnabled
            ? primaryIndigo
            : (isDark
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.grey.shade400),
        size: 20,
      ),
    );
  }

  Widget _buildToggleSwitch(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 50,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isEnabled
            ? primaryIndigo
            : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        border: Border.all(
          color: isEnabled
              ? Colors.transparent
              : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
          width: 1,
        ),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        alignment: isEnabled ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isEnabled
                ? Colors.white
                : (isDark ? Colors.grey.shade300 : Colors.white),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
