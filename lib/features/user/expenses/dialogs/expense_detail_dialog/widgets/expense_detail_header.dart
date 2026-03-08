import 'package:flutter/material.dart';

/// Masraf detay dialog başlık widget'ı
class ExpenseDetailHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double width;

  const ExpenseDetailHeader({
    super.key,
    required this.icon,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(width * 0.03),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.7)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: width * 0.06),
        ),
        SizedBox(width: width * 0.03),
        Expanded(
          child: Text(
            'Masraf Detayı',
            style: TextStyle(
              fontSize: width * 0.05,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}
