import 'package:flutter/material.dart';

class UserFilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String currentFilter;
  final Function(String) onSelected;

  const UserFilterChip({
    super.key,
    required this.label,
    required this.value,
    required this.currentFilter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentFilter == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        onSelected(value);
      },
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      checkmarkColor: isDark ? Colors.white : Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected
            ? (isDark ? Colors.white : Theme.of(context).primaryColor)
            : null,
      ),
    );
  }
}
