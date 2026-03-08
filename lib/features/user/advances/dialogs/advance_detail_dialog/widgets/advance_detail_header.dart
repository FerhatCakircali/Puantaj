import 'package:flutter/material.dart';

/// Avans detay dialog başlık widget'ı
class AdvanceDetailHeader extends StatelessWidget {
  final double width;

  const AdvanceDetailHeader({super.key, required this.width});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const primaryColor = Color(0xFF4338CA);

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(width * 0.03),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primaryColor, Color(0xFF6366F1)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.account_balance_wallet,
            color: Colors.white,
            size: width * 0.06,
          ),
        ),
        SizedBox(width: width * 0.03),
        Expanded(
          child: Text(
            'Avans Detayı',
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
