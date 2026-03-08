import 'package:flutter/material.dart';

/// Rapor boş durum widget'ı
///
/// Rapor bulunamadığında gösterilir.
class ReportEmptyState extends StatelessWidget {
  final bool hasSearchQuery;

  const ReportEmptyState({super.key, required this.hasSearchQuery});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      child: SizedBox(
        height: screenHeight * 0.5,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIcon(colorScheme),
              const SizedBox(height: 24),
              _buildTitle(colorScheme),
              const SizedBox(height: 8),
              _buildSubtitle(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        shape: BoxShape.circle,
      ),
      child: Icon(
        hasSearchQuery ? Icons.search_off : Icons.inbox_outlined,
        size: 64,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildTitle(ColorScheme colorScheme) {
    return Text(
      hasSearchQuery ? 'Sonuç bulunamadı' : 'Bu tarih aralığında kayıt yok',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSubtitle(ColorScheme colorScheme) {
    return Text(
      hasSearchQuery
          ? 'Arama kriterlerinizi değiştirin'
          : 'Farklı bir tarih aralığı seçin',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
