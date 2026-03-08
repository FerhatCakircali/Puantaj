import 'package:flutter/material.dart';
import '../../../../models/expense.dart';
import 'category_chip.dart';

/// Masraf kategori filtreleme widget'ı
class ExpenseCategoryFilter extends StatelessWidget {
  final ExpenseCategory? selectedCategory;
  final ValueChanged<ExpenseCategory?> onCategorySelected;

  const ExpenseCategoryFilter({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.filter_list,
              size: 16,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              'Kategori Filtrele',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              CategoryChip(
                category: null,
                isSelected: selectedCategory == null,
                onTap: () => onCategorySelected(null),
              ),
              const SizedBox(width: 8),
              CategoryChip(
                category: ExpenseCategory.malzeme,
                isSelected: selectedCategory == ExpenseCategory.malzeme,
                onTap: () => onCategorySelected(ExpenseCategory.malzeme),
              ),
              const SizedBox(width: 8),
              CategoryChip(
                category: ExpenseCategory.ulasim,
                isSelected: selectedCategory == ExpenseCategory.ulasim,
                onTap: () => onCategorySelected(ExpenseCategory.ulasim),
              ),
              const SizedBox(width: 8),
              CategoryChip(
                category: ExpenseCategory.ekipman,
                isSelected: selectedCategory == ExpenseCategory.ekipman,
                onTap: () => onCategorySelected(ExpenseCategory.ekipman),
              ),
              const SizedBox(width: 8),
              CategoryChip(
                category: ExpenseCategory.diger,
                isSelected: selectedCategory == ExpenseCategory.diger,
                onTap: () => onCategorySelected(ExpenseCategory.diger),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ],
    );
  }
}
