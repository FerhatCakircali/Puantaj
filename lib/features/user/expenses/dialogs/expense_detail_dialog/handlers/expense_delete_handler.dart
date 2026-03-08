import 'package:flutter/material.dart';
import '../../../../../../models/expense.dart';
import '../../../controllers/expense_controller.dart';

/// Masraf silme işlemlerini yöneten handler sınıfı
class ExpenseDeleteHandler {
  /// Masrafı siler ve kullanıcıya bildirim gösterir
  static Future<void> deleteExpense(
    BuildContext context, {
    required Expense expense,
    required VoidCallback onDeleted,
  }) async {
    final confirmed = await _showDeleteConfirmation(context);
    if (confirmed != true || !context.mounted) return;

    try {
      final controller = ExpenseController();
      await controller.deleteExpense(expense.id!);

      if (!context.mounted) return;

      Navigator.pop(context);
      onDeleted();

      _showSuccessSnackBar(context);
    } catch (e) {
      if (!context.mounted) return;
      _showErrorSnackBar(context, e.toString());
    }
  }

  static Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
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
  }

  static void _showSuccessSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Masraf silindi',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  static void _showErrorSnackBar(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Hata: $error',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
