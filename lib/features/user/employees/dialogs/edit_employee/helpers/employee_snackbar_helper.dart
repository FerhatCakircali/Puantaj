import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Çalışan işlemleri bildirim yardımcı sınıfı
class EmployeeSnackbarHelper {
  /// Validasyon hatası gösterir
  static void showValidationError(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Başarılı güncelleme mesajı gösterir
  static void showUpdateSuccess(BuildContext context) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Çalışan bilgileri başarıyla güncellendi',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Kayıt silme ile güncelleme başarı mesajı gösterir
  static void showUpdateWithDeletionSuccess(
    BuildContext context,
    DateTime deletionDate,
  ) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Çalışan bilgileri güncellendi. ${DateFormat('dd/MM/yyyy').format(deletionDate)} tarihinden önceki kayıtlar silindi.',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Tarih değişikliği uyarısı gösterir
  static void showDateChangeWarning(BuildContext context) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'UYARI: Seçilen yeni giriş tarihinden önce bu çalışana ait kayıtlar mevcut. '
          'Değişikliği kaydetmeniz veri tutarsızlığına yol açabilir!',
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 5),
      ),
    );
  }
}
