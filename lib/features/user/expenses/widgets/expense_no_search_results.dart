import 'package:flutter/material.dart';

/// Masraf arama sonucu bulunamadı widget'ı
///
/// Arama sonucunda masraf bulunamadığında gösterilir.
class ExpenseNoSearchResults extends StatelessWidget {
  const ExpenseNoSearchResults({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: w * 0.2,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          SizedBox(height: h * 0.02),
          Text(
            'Sonuç bulunamadı',
            style: TextStyle(
              fontSize: w * 0.05,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: h * 0.01),
          Text(
            'Arama kriterlerinizi değiştirin',
            style: TextStyle(
              fontSize: w * 0.035,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
