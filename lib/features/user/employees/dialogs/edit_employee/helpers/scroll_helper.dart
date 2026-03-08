import 'package:flutter/material.dart';

/// Scroll yönetim yardımcı sınıfı
class ScrollHelper {
  /// Widget'ı görünür alana kaydırır
  ///
  /// Klavye açıldığında veya focus değiştiğinde
  /// ilgili widget'ın görünür olmasını sağlar.
  static Future<void> ensureVisible(GlobalKey key) async {
    await Future.delayed(const Duration(milliseconds: 60));

    final ctx = key.currentContext;
    if (ctx == null) return;

    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      alignment: 0.2,
    );
  }
}
