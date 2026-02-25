import 'package:flutter/material.dart';

/// Tarih değişikliği uyarı kutusu
/// Giriş tarihi değiştirildiğinde ve önceki kayıtlar varsa gösterilir
class DateChangeWarning extends StatelessWidget {
  const DateChangeWarning({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.error),
      ),
      child: Text(
        'UYARI: Seçtiğiniz yeni giriş tarihinden önce bu çalışana ait devam kaydı veya ödeme kaydı bulunmaktadır. Giriş tarihini değiştirdiğinizde veri tutarsızlığı oluşabilir!',
        style: TextStyle(color: theme.colorScheme.error),
      ),
    );
  }
}
