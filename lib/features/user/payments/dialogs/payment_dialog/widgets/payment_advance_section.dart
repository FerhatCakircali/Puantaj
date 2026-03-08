import 'package:flutter/material.dart';
import '../../../../../../models/advance.dart';
import '../../../../../../utils/currency_formatter.dart';

/// Avans bölümü widget'ı
///
/// Bekleyen avansları gösterir ve düşme seçeneği sunar
class PaymentAdvanceSection extends StatelessWidget {
  final List<Advance> pendingAdvances;
  final double totalPendingAdvances;
  final bool deductAdvances;
  final ValueChanged<bool> onDeductChanged;
  final double paymentAmount;

  const PaymentAdvanceSection({
    super.key,
    required this.pendingAdvances,
    required this.totalPendingAdvances,
    required this.deductAdvances,
    required this.onDeductChanged,
    required this.paymentAmount,
  });

  @override
  Widget build(BuildContext context) {
    if (pendingAdvances.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: deductAdvances
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 12),
          _buildAdvanceInfo(theme),
          const SizedBox(height: 12),
          _buildDeductCheckbox(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.account_balance_wallet,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Bekleyen Avanslar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildAdvanceInfo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${pendingAdvances.length} adet bekleyen avans',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Toplam: ${CurrencyFormatter.formatWithSymbol(totalPendingAdvances)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeductCheckbox(ThemeData theme) {
    return CheckboxListTile(
      value: deductAdvances,
      onChanged: (value) => onDeductChanged(value ?? false),
      title: Text(
        'Avansları ödemeden düş',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: deductAdvances
          ? Text(
              'Ödenecek tutar: ${CurrencyFormatter.formatWithSymbol(paymentAmount - totalPendingAdvances)}',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      activeColor: theme.colorScheme.primary,
    );
  }
}
