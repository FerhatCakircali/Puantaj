import 'package:flutter/material.dart';

/// Kullanıcı silme onay dialog widget'ı
class DeleteConfirmDialog extends StatelessWidget {
  final Map<String, dynamic> user;

  const DeleteConfirmDialog({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kullanıcıyı Sil'),
      content: Text(
        '${user['first_name']} ${user['last_name']} kullanıcısını silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz.',
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
          child: const Text('Sil'),
        ),
      ],
    );
  }
}
