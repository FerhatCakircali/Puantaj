import 'package:flutter/material.dart';

/// Dialog handle bar widget'ı
///
/// Bottom sheet'lerin üstünde görünen sürüklenebilir çubuk.
class DialogHandleBar extends StatelessWidget {
  final double screenWidth;
  final ColorScheme colorScheme;

  const DialogHandleBar({
    super.key,
    required this.screenWidth,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: screenWidth * 0.03),
      width: screenWidth * 0.1,
      height: 4,
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
