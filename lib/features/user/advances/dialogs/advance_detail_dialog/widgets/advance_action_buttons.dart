import 'package:flutter/material.dart';

/// Avans detay dialog aksiyon butonları widget'ı
class AdvanceActionButtons extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final double width;

  const AdvanceActionButtons({
    super.key,
    required this.onDelete,
    required this.onEdit,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF4338CA);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Sil'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: EdgeInsets.symmetric(vertical: width * 0.035),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        SizedBox(width: width * 0.03),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit),
            label: const Text('Düzenle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: width * 0.035),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
