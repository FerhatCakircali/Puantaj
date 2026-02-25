import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Kayıt silme onay dialog'u
/// Giriş tarihi değiştirildiğinde önceki kayıtları silmek için onay ister
class DeleteRecordsConfirmationDialog extends StatelessWidget {
  final String employeeName;
  final DateTime newStartDate;

  const DeleteRecordsConfirmationDialog({
    super.key,
    required this.employeeName,
    required this.newStartDate,
  });

  /// Dialog'u göster
  static Future<bool> show(
    BuildContext context, {
    required String employeeName,
    required DateTime newStartDate,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => DeleteRecordsConfirmationDialog(
            employeeName: employeeName,
            newStartDate: newStartDate,
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Dikkat! Veri Kaybı Riski'),
      content: Text(
        '$employeeName için seçtiğiniz yeni giriş tarihi (${DateFormat('dd/MM/yyyy').format(newStartDate)}) öncesinde devam ve/veya ödeme kayıtları mevcut.\n\n'
        'Devam ederseniz, bu tarihten önceki TÜM devam ve ödeme kayıtları SİLİNECEKTİR!\n\n'
        'Bu işlem geri alınamaz. Emin misiniz?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Evet, Kayıtları Sil ve Devam Et'),
        ),
      ],
    );
  }
}
