import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/expense.dart';
import '../../../user/payments/utils/currency_formatter.dart';

/// Masraf listesi için kart widget'ı
class ExpenseListTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback onTap;
  final Color primaryColor;

  const ExpenseListTile({
    super.key,
    required this.expense,
    required this.onTap,
    this.primaryColor = const Color(0xFF4338CA),
  });

  String _getCategoryName(ExpenseCategory category) {
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

  Color _getCategoryColor(ExpenseCategory category) {
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

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.malzeme:
        return Icons.inventory_2;
      case ExpenseCategory.ulasim:
        return Icons.local_shipping;
      case ExpenseCategory.ekipman:
        return Icons.construction;
      case ExpenseCategory.diger:
        return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.04,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Sol taraf - Kategori ikonu
                    Container(
                      width: w * 0.11,
                      height: w * 0.11,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getCategoryColor(expense.category),
                            _getCategoryColor(
                              expense.category,
                            ).withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _getCategoryColor(
                              expense.category,
                            ).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          _getCategoryIcon(expense.category),
                          color: Colors.white,
                          size: w * 0.055,
                        ),
                      ),
                    ),
                    SizedBox(width: w * 0.03),
                    // Orta - Masraf bilgisi
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.expenseType,
                            style: TextStyle(
                              fontSize: w * 0.045,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              // Kategori chip
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: w * 0.02,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(
                                    expense.category,
                                  ).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getCategoryName(expense.category),
                                  style: TextStyle(
                                    fontSize: w * 0.028,
                                    color: _getCategoryColor(
                                      expense.category,
                                    ).withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(width: w * 0.02),
                              // Tarih
                              Icon(
                                Icons.calendar_today,
                                size: w * 0.03,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              SizedBox(width: w * 0.01),
                              Text(
                                DateFormat(
                                  'dd MMM',
                                  'tr_TR',
                                ).format(expense.expenseDate),
                                style: TextStyle(
                                  fontSize: w * 0.032,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              // Fatura ikonu (varsa)
                              if (expense.receiptUrl != null &&
                                  expense.receiptUrl!.isNotEmpty) ...[
                                SizedBox(width: w * 0.02),
                                Icon(
                                  Icons.receipt,
                                  size: w * 0.035,
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Sağ taraf - Tutar
                    Text(
                      '₺${CurrencyFormatter.format(expense.amount)}',
                      style: TextStyle(
                        fontSize: w * 0.05,
                        fontWeight: FontWeight.w900,
                        color: primaryColor,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
