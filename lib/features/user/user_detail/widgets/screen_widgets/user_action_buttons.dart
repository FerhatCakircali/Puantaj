import 'package:flutter/material.dart';

/// Kullanıcı işlem butonları widget'ı
class UserActionButtons extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isUpdating;
  final VoidCallback onEdit;
  final VoidCallback onToggleBlock;
  final VoidCallback onDelete;

  const UserActionButtons({
    super.key,
    required this.user,
    required this.isUpdating,
    required this.onEdit,
    required this.onToggleBlock,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isBlocked = user['is_blocked'] as bool? ?? false;
    final isMainAdmin = user['username']?.toString().toLowerCase() == 'admin';

    if (isMainAdmin) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.security, size: 48, color: Colors.green),
              const SizedBox(height: 8),
              const Text(
                'Sistem Yöneticisi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Bu hesap sistem yöneticisidir ve değiştirilemez.',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'İşlemler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isUpdating ? null : onEdit,
                    icon: const Icon(Icons.edit),
                    label: const Text('Düzenle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isUpdating ? null : onToggleBlock,
                    icon: Icon(isBlocked ? Icons.person_add : Icons.person_off),
                    label: Text(isBlocked ? 'Bloku Kaldır' : 'Blokla'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isBlocked ? Colors.green : Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isUpdating ? null : onDelete,
                icon: const Icon(Icons.delete),
                label: const Text('Kullanıcıyı Sil'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
