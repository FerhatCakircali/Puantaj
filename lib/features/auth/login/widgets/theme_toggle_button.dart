import 'package:flutter/material.dart';

/// Tema değiştirme butonu widget'ı
class ThemeToggleButton extends StatelessWidget {
  final ThemeMode currentMode;
  final VoidCallback onToggle;
  final GlobalKey iconKey;

  const ThemeToggleButton({
    super.key,
    required this.currentMode,
    required this.onToggle,
    required this.iconKey,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = currentMode == ThemeMode.dark;

    return Positioned(
      top: 32,
      right: 16,
      child: Padding(
        padding: const EdgeInsets.only(right: 0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, anim) => RotationTransition(
            turns: child.key == const ValueKey('dark')
                ? Tween<double>(begin: 1, end: 0.75).animate(anim)
                : Tween<double>(begin: 0.75, end: 1).animate(anim),
            child: FadeTransition(opacity: anim, child: child),
          ),
          child: IconButton(
            key: iconKey,
            tooltip: isDark ? 'Açık moda geç' : 'Koyu moda geç',
            icon: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }
}
