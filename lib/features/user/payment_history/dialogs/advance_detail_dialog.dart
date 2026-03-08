import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../utils/currency_formatter.dart';

/// Avans detay dialog'u
class AdvanceDetailDialog {
  /// Avans detaylarını gösterir
  static void show(BuildContext context, Map<String, dynamic> advance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: _buildTitle(),
        content: _buildContent(advance),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  static Widget _buildTitle() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.account_balance_wallet,
            color: Colors.orange,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Text('Avans Detayı'),
      ],
    );
  }

  static Widget _buildContent(Map<String, dynamic> advance) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Çalışan', advance['workers']['full_name'] as String),
        const SizedBox(height: 12),
        _buildDetailRow(
          'Tutar',
          CurrencyFormatter.formatWithSymbol(
            (advance['amount'] as num).toDouble(),
          ),
        ),
        const SizedBox(height: 12),
        _buildDetailRow(
          'Tarih',
          DateFormat(
            'dd/MM/yyyy',
          ).format(DateTime.parse(advance['payment_date'] as String)),
        ),
        if (advance['description'] != null &&
            (advance['description'] as String).isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildDetailRow('Açıklama', advance['description'] as String),
        ],
      ],
    );
  }

  static Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
