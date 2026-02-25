import 'package:flutter/material.dart';

/// Kullanıcı durum ve yetkileri card widget'ı
class UserStatusCard extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserStatusCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isAdmin = user['is_admin'] == 1;
    final isBlocked = user['is_blocked'] as bool? ?? false;
    final isMainAdmin = user['username']?.toString().toLowerCase() == 'admin';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Durum ve Yetkiler',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ListTile(
              leading: Icon(
                isAdmin ? Icons.admin_panel_settings : Icons.person,
                color: isAdmin ? Colors.orange : Colors.blue,
              ),
              title: Text(isAdmin ? 'Admin Kullanıcı' : 'Normal Kullanıcı'),
              subtitle: Text(
                isMainAdmin
                    ? 'Sistem yöneticisi - Tam yetki'
                    : isAdmin
                    ? 'Admin yetkilerine sahip'
                    : 'Standart kullanıcı yetkilerine sahip',
              ),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: Icon(
                isBlocked ? Icons.block : Icons.check_circle,
                color: isBlocked ? Colors.red : Colors.green,
              ),
              title: Text(isBlocked ? 'Hesap Bloklu' : 'Hesap Aktif'),
              subtitle: Text(
                isBlocked
                    ? 'Kullanıcı sisteme giriş yapamaz'
                    : 'Kullanıcı sistemi normal şekilde kullanabilir',
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
