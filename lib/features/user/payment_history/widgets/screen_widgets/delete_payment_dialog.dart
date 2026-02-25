import 'package:flutter/material.dart';
import '../../../../../screens/constants/colors.dart';

/// Ödeme silme onay dialog'u
/// Ödeme kaydını silmeden önce kullanıcıdan onay alır
class DeletePaymentDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const DeletePaymentDialog({super.key, required this.onConfirm});

  /// Dialog'u göster
  static Future<void> show(
    BuildContext context, {
    required VoidCallback onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (context) => DeletePaymentDialog(onConfirm: onConfirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: errorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.warning_outlined,
              color: errorColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ödemeyi Sil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        'Bu ödeme kaydını silmek istediğinizden emin misiniz? '
        'Çalışana bildirim gönderilecektir.',
        style: TextStyle(
          fontSize: 14,
          color: isDark
              ? Colors.white.withValues(alpha: 0.8)
              : Colors.grey.shade700,
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            side: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.grey.shade300,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: Text(
            'İptal',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        FilledButton(
          onPressed: onConfirm,
          style: FilledButton.styleFrom(
            backgroundColor: errorColor,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: const Text(
            'Sil',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
