import 'package:flutter/material.dart';
import '../../../../models/expense.dart';
import 'category_chip.dart';

/// Masraf kategori filtreleme widget'ı
///
/// Masrafları kategoriye göre filtrelemeyi sağlar.
class ExpenseCategoryFilters extends StatelessWidget {
  final ExpenseCategory? selectedCategory;
  final ValueChanged<ExpenseCategory?> onCategorySelected;

  const ExpenseCategoryFilters({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
        ],
      ),
    );
  }
}
