import 'package:flutter/material.dart';

import '../../../../../../screens/constants/colors.dart';

/// Dialog başlığı widget
class EditPaymentDialogHeader extends StatelessWidget {
  final String workerName;
  final bool isDark;
  final VoidCallback onClose;

  const EditPaymentDialogHeader({
    required this.workerName,
    required this.isDark,
    required this.onClose,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryIndigo, primaryIndigo.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                workerName.isNotEmpty ? workerName[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Ödeme Düzenle - $workerName',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
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
