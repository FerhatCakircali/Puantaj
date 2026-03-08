import 'package:flutter/material.dart';
import '../../payment_history/widgets/screen_widgets/index.dart';
import '../controllers/payment_history_controller.dart';
import '../dialogs/advance_detail_dialog.dart';

/// Ödeme kartı tıklama işlemlerini yöneten sınıf
class PaymentTapHandler {
  final PaymentHistoryController _controller;
  final BuildContext _context;
  final VoidCallback _onUpdate;

  PaymentTapHandler({
    required PaymentHistoryController controller,
    required BuildContext context,
    required VoidCallback onUpdate,
  }) : _controller = controller,
       _context = context,
       _onUpdate = onUpdate;

  /// Ödeme kartına tıklandığında çağrılır
  Future<void> handle(Map<String, dynamic> payment) async {
    final isAdvance = payment['is_advance'] as bool? ?? false;

    if (isAdvance) {
      _handleAdvance(payment);
    } else {
      await _handleRegularPayment(payment);
    }
  }

  /// Avans detayını gösterir
  void _handleAdvance(Map<String, dynamic> advance) {
    AdvanceDetailDialog.show(_context, advance);
  }

  /// Normal ödeme düzenleme dialog'unu gösterir
  Future<void> _handleRegularPayment(Map<String, dynamic> payment) async {
    final details = _controller.parsePaymentDetails(payment);

    debugPrint(
      'Ödeme düzenleme açılıyor: paymentId=${details.id}, workerId=${details.workerId}',
    );

    final unpaidDays = await _controller.getUnpaidDaysExcludingPayment(
      details.workerId,
      details.id,
    );
    final maxFullDays = unpaidDays['fullDays'] ?? 0;
    final maxHalfDays = unpaidDays['halfDays'] ?? 0;

    if (!_context.mounted) return;

    EditPaymentDialog.show(
      _context,
      paymentId: details.id,
      workerId: details.workerId,
      workerName: details.workerName,
      currentFullDays: details.fullDays,
      currentHalfDays: details.halfDays,
      currentAmount: details.amount,
      paymentDate: details.paymentDate,
      displayTime: details.displayTime,
      maxFullDays: maxFullDays,
      maxHalfDays: maxHalfDays,
      onUpdate: (paymentId, fullDays, halfDays, amount) async {
        await _handleUpdate(paymentId, fullDays, halfDays, amount);
      },
      onDelete: () => _handleDeleteRequest(details.id),
    );
  }

  /// Ödeme güncelleme işlemini yapar
  Future<void> _handleUpdate(
    int paymentId,
    int fullDays,
    int halfDays,
    double amount,
  ) async {
    Navigator.pop(_context);

    try {
      final success = await _controller.updatePayment(
        paymentId: paymentId,
        fullDays: fullDays,
        halfDays: halfDays,
        amount: amount,
      );

      if (success && _context.mounted) {
        _showSuccessMessage(
          'Ödeme güncellendi ve çalışana bildirim gönderildi',
        );
        _onUpdate();
      }
    } catch (e) {
      if (_context.mounted) {
        _showErrorMessage(e.toString());
      }
    }
  }

  /// Silme onayı ister
  void _handleDeleteRequest(int paymentId) {
    Navigator.pop(_context);

    DeletePaymentDialog.show(
      _context,
      onConfirm: () => _handleDelete(paymentId),
    );
  }

  /// Ödeme silme işlemini yapar
  Future<void> _handleDelete(int paymentId) async {
    Navigator.pop(_context);

    try {
      final success = await _controller.deletePayment(paymentId);

      if (success && _context.mounted) {
        _showSuccessMessage('Ödeme silindi ve çalışana bildirim gönderildi');
        _onUpdate();
      }
    } catch (e) {
      if (_context.mounted) {
        _showErrorMessage(e.toString());
      }
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(
      _context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(_context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
