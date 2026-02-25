import 'package:flutter/material.dart';

import '../../../../../../screens/constants/colors.dart';

/// Yeni hatırlatıcı ekleme kartı widget
class ReminderListAddCard extends StatelessWidget {
  final VoidCallback onAddNew;

  const ReminderListAddCard({required this.onAddNew, super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: primaryIndigo.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onAddNew,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primaryIndigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.add, color: primaryIndigo, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Yeni Hatırlatıcı Ekle',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryIndigo,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Çalışanlar sekmesinden ekleyebilirsiniz',
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
              const Icon(
                Icons.arrow_forward_ios,
                color: primaryIndigo,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
