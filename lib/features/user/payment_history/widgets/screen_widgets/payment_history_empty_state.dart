import 'package:flutter/material.dart';

/// Ödeme geçmişi boş durum widget'ı
/// Kayıt bulunamadığında veya arama sonucu boş olduğunda gösterilir
class PaymentHistoryEmptyState extends StatelessWidget {
  final bool isSearching;

  const PaymentHistoryEmptyState({super.key, this.isSearching = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSearching ? Icons.search_off : Icons.inbox_outlined,
              size: 64,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isSearching ? 'Sonuç bulunamadı' : 'Ödeme kaydı bulunamadı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Arama kriterlerinizi değiştirin'
                : 'Farklı bir tarih aralığı deneyin',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
