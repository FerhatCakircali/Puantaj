import 'package:flutter/material.dart';

/// Tüm ödemeler tamamlandığında gösterilen widget
class AllPaidState extends StatelessWidget {
  final Color primaryColor;

  const AllPaidState({super.key, this.primaryColor = const Color(0xFF4338CA)});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(w * 0.08),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: w * 0.16,
              color: primaryColor,
            ),
          ),
          SizedBox(height: h * 0.03),
          Text(
            'Tüm Ödemeler Tamamlandı',
            style: TextStyle(
              fontSize: w * 0.07,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: h * 0.01),
          Text(
            'Ödenmemiş günü olan çalışan yok',
            style: TextStyle(
              fontSize: w * 0.045,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Arama sonucu bulunamadığında gösterilen widget
class NoSearchResults extends StatelessWidget {
  const NoSearchResults({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: w * 0.12,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          SizedBox(height: h * 0.02),
          Text(
            'Sonuç bulunamadı',
            style: TextStyle(
              fontSize: w * 0.045,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
