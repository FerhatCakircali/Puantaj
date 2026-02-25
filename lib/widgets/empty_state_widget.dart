import 'package:flutter/material.dart';

/// Boş durum gösterimi için yeniden kullanılabilir widget
/// Material 3 Design System ile uyumlu
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? subtitle;
  final double iconSize;
  final bool isTablet;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
    this.iconSize = 64,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fontSize = isTablet ? 22.0 : 16.0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surfaceContainerHighest,
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: fontSize * 1.1,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: fontSize * 0.9,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
