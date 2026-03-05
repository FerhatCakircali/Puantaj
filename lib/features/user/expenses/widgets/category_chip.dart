import 'package:flutter/material.dart';
import '../../../../models/expense.dart';

/// Kategori filtreleme chip widget'ı
class CategoryChip extends StatelessWidget {
  final ExpenseCategory? category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    this.category,
    required this.isSelected,
    required this.onTap,
  });

  String _getCategoryName(ExpenseCategory? category) {
    if (category == null) return 'Tümü';
    switch (category) {
      case ExpenseCategory.malzeme:
        return 'Malzeme';
      case ExpenseCategory.ulasim:
        return 'Ulaşım';
      case ExpenseCategory.ekipman:
        return 'Ekipman';
      case ExpenseCategory.diger:
        return 'Diğer';
    }
  }

  Color _getCategoryColor(ExpenseCategory? category) {
    if (category == null) return const Color(0xFF4338CA);
    switch (category) {
      case ExpenseCategory.malzeme:
        return Colors.blue;
      case ExpenseCategory.ulasim:
        return Colors.orange;
      case ExpenseCategory.ekipman:
        return Colors.green;
      case ExpenseCategory.diger:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getCategoryColor(category);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected
              ? null
              : isDark
              ? theme.colorScheme.surfaceContainerHighest
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          _getCategoryName(category),
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : isDark
                ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
                : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
