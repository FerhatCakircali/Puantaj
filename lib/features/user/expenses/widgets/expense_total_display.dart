import 'package:flutter/material.dart';
import '../../../user/payments/utils/currency_formatter.dart';

/// Masraf toplam göstergesi widget'ı
///
/// Aylık veya genel toplam masrafı gösterir.
class ExpenseTotalDisplay extends StatelessWidget {
  final double filteredTotal;
  final bool showMonthlyTotal;
  final VoidCallback onToggle;
  final Color primaryColor;

  const ExpenseTotalDisplay({
    super.key,
    required this.filteredTotal,
    required this.showMonthlyTotal,
    required this.onToggle,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [_buildHeader(), const SizedBox(height: 2), _buildAmount()],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            showMonthlyTotal ? 'Bu Ay' : 'Toplam',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Icon(
          showMonthlyTotal ? Icons.calendar_month : Icons.all_inclusive,
          size: 12,
          color: Colors.white.withValues(alpha: 0.8),
        ),
      ],
    );
  }

  Widget _buildAmount() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        '₺${CurrencyFormatter.format(filteredTotal)}',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
