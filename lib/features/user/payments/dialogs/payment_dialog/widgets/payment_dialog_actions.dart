import 'package:flutter/material.dart';
import '../../../../../../screens/constants/colors.dart';

/// Ödeme dialog'u alt butonlar widget'ı
class PaymentDialogActions extends StatelessWidget {
  final VoidCallback onPayment;
  final VoidCallback onCancel;

  const PaymentDialogActions({
    super.key,
    required this.onPayment,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.2)
            : Colors.grey.shade50,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: onPayment,
              style: FilledButton.styleFrom(
                backgroundColor: primaryIndigo,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Ödeme Yap',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onCancel,
            child: Text(
              'İptal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : primaryIndigo,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
