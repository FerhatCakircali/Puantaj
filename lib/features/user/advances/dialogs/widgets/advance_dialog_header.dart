import 'package:flutter/material.dart';

/// Avans dialog başlığı widget'ı
///
/// Dialog'un üst kısmındaki başlık ve kapat butonunu içerir.
class AdvanceDialogHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color primaryColor;

  const AdvanceDialogHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final w = MediaQuery.sizeOf(context).width;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(w * 0.03),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: primaryColor, size: w * 0.06),
        ),
        SizedBox(width: w * 0.03),
        Text(
          title,
          style: TextStyle(
            fontSize: w * 0.05,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}
