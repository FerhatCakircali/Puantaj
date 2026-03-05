import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/expense.dart';
import '../controllers/expense_controller.dart';
import 'edit_expense_dialog.dart';

/// Masraf detay dialog'u
class ExpenseDetailDialog extends StatelessWidget {
  final Expense expense;
  final VoidCallback onExpenseUpdated;

  const ExpenseDetailDialog({
    super.key,
    required this.expense,
    required this.onExpenseUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required Expense expense,
    required VoidCallback onExpenseUpdated,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ExpenseDetailDialog(
        expense: expense,
        onExpenseUpdated: onExpenseUpdated,
      ),
    );
  }

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

  Future<void> _deleteExpense(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Masrafı Sil'),
        content: const Text('Bu masrafı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final controller = ExpenseController();
      await controller.deleteExpense(expense.id!);

      if (!context.mounted) return;

      Navigator.pop(context);
      onExpenseUpdated();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Masraf silindi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Hata: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _editExpense(BuildContext context) {
    Navigator.pop(context);
    EditExpenseDialog.show(
      context,
      expense: expense,
      onExpenseUpdated: onExpenseUpdated,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final categoryColor = _getCategoryColor(expense.category);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(w * 0.06),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık ve kapat butonu
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(w * 0.03),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        categoryColor,
                        categoryColor.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(expense.category),
                    color: Colors.white,
                    size: w * 0.06,
                  ),
                ),
                SizedBox(width: w * 0.03),
                Expanded(
                  child: Text(
                    'Masraf Detayı',
                    style: TextStyle(
                      fontSize: w * 0.05,
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
            ),
            SizedBox(height: w * 0.06),

            // Masraf türü
            _buildInfoRow(
              context,
              icon: Icons.receipt_long,
              label: 'Masraf Türü',
              value: expense.expenseType,
              w: w,
            ),
            SizedBox(height: w * 0.04),

            // Kategori
            _buildInfoRow(
              context,
              icon: Icons.category,
              label: 'Kategori',
              value: _getCategoryName(expense.category),
              w: w,
              valueColor: categoryColor,
            ),
            SizedBox(height: w * 0.04),

            // Tutar
            _buildInfoRow(
              context,
              icon: Icons.currency_lira,
              label: 'Tutar',
              value:
                  '₺${expense.amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
              w: w,
              valueColor: const Color(0xFF4338CA),
              valueBold: true,
            ),
            SizedBox(height: w * 0.04),

            // Tarih
            _buildInfoRow(
              context,
              icon: Icons.calendar_today,
              label: 'Tarih',
              value: DateFormat(
                'dd MMMM yyyy',
                'tr_TR',
              ).format(expense.expenseDate),
              w: w,
            ),
            SizedBox(height: w * 0.04),

            // Açıklama (varsa)
            if (expense.description != null &&
                expense.description!.isNotEmpty) ...[
              _buildInfoRow(
                context,
                icon: Icons.description,
                label: 'Açıklama',
                value: expense.description!,
                w: w,
                multiline: true,
              ),
              SizedBox(height: w * 0.04),
            ],

            // Fatura (varsa)
            if (expense.receiptUrl != null &&
                expense.receiptUrl!.isNotEmpty) ...[
              Row(
                children: [
                  Icon(
                    Icons.receipt,
                    size: w * 0.05,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: w * 0.02),
                  Text(
                    'Fatura mevcut',
                    style: TextStyle(
                      fontSize: w * 0.035,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: w * 0.04),
            ],

            SizedBox(height: w * 0.02),

            // Butonlar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteExpense(context),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Sil'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: EdgeInsets.symmetric(vertical: w * 0.035),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: w * 0.03),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _editExpense(context),
                    icon: const Icon(Icons.edit),
                    label: const Text('Düzenle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4338CA),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: w * 0.035),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required double w,
    Color? valueColor,
    bool valueBold = false,
    bool multiline = false,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: multiline
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: w * 0.05, color: theme.colorScheme.onSurfaceVariant),
        SizedBox(width: w * 0.03),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: w * 0.032,
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: w * 0.04,
                  color: valueColor ?? theme.colorScheme.onSurface,
                  fontWeight: valueBold ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
