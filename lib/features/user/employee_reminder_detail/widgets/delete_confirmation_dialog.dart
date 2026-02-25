import 'package:flutter/material.dart';

class DeleteConfirmationDialog extends StatelessWidget {
  final VoidCallback onConfirm;

  const DeleteConfirmationDialog({super.key, required this.onConfirm});

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true, // Dışına tıklayınca kapanabilir
      builder: (BuildContext context) =>
          DeleteConfirmationDialog(onConfirm: onConfirm),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Hatırlatıcıyı Sil'),
      content: const Text(
        'Bu hatırlatıcı bildirim mesajı silinecek. Onaylıyor musunuz?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hayır'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          child: const Text('Evet'),
        ),
      ],
    );
  }
}
