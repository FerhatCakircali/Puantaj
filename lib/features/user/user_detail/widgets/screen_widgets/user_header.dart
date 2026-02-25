import 'package:flutter/material.dart';

/// Kullanıcı başlık widget'ı - Avatar, isim ve badge'ler
class UserHeader extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isAdmin = user['is_admin'] == 1;
    final isMainAdmin = user['username']?.toString().toLowerCase() == 'admin';
    final isBlocked = user['is_blocked'] as bool? ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(
                context,
              ).primaryColor.withValues(alpha: 0.1),
              child: Icon(
                isMainAdmin
                    ? Icons.verified_user
                    : isAdmin
                    ? Icons.admin_panel_settings
                    : Icons.person,
                size: 40,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${user['first_name']} ${user['last_name']}'.trim(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@${user['username']}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (isMainAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'System Admin',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      else if (isAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Admin',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isBlocked
                              ? Colors.red.withValues(alpha: 0.2)
                              : Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          isBlocked ? 'Bloklu' : 'Aktif',
                          style: TextStyle(
                            fontSize: 12,
                            color: isBlocked
                                ? Colors.red[700]
                                : Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
