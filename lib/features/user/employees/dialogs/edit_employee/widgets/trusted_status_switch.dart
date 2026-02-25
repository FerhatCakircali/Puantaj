import 'package:flutter/material.dart';

/// Güvenilir durumu switch widget'ı
/// Çalışanın güvenilir olup olmadığını gösterir ve değiştirir
class TrustedStatusSwitch extends StatelessWidget {
  final bool isTrusted;
  final ValueChanged<bool> onChanged;

  const TrustedStatusSwitch({
    super.key,
    required this.isTrusted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isTrusted
              ? Colors.green
              : theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(16),
        color: isTrusted
            ? Colors.green.withValues(alpha: 0.1)
            : theme.colorScheme.surfaceContainerHighest,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            isTrusted ? Icons.verified : Icons.shield_outlined,
            color: isTrusted ? Colors.green : Colors.grey,
            size: 28,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Güvenilir Durumu',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isTrusted
                      ? 'Kullanıcı güvenilir'
                      : 'Kullanıcı güvenilir değil',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isTrusted,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: Colors.green,
            inactiveThumbColor: isDark ? Colors.grey.shade300 : Colors.white,
            inactiveTrackColor: isDark
                ? Colors.grey.shade800
                : Colors.grey.shade400,
            trackOutlineColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return Colors.transparent;
              }
              return isDark ? Colors.grey.shade600 : Colors.grey.shade500;
            }),
          ),
        ],
      ),
    );
  }
}
