import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';

class UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final AuthService authService;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const UserCard({
    super.key,
    required this.user,
    required this.authService,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isBlocked = user['is_blocked'] as bool;
    final isAdmin = user['is_admin'] == 1;
    final isSystemAdmin = authService.isSystemAdmin(user);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[300],
                    child: Icon(
                      isSystemAdmin ? Icons.verified_user : Icons.person,
                      color: isSystemAdmin
                          ? Colors.orange
                          : (Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]
                                : Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Kullanıcı Bilgileri
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'
                              .trim(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${user['username'] ?? ''}',
                          style: TextStyle(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (user['job_title'] != null &&
                            user['job_title'].toString().isNotEmpty)
                          Text(
                            user['job_title'],
                            style: TextStyle(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[500]
                                  : Colors.grey[500],
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),

                  // Aksiyon Butonları
                  Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isSystemAdmin)
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: onEdit,
                              tooltip: 'Düzenle',
                              constraints: const BoxConstraints(
                                minWidth: 32,
                                minHeight: 32,
                              ),
                              padding: const EdgeInsets.all(4),
                            ),
                        ],
                      ),
                      Text(
                        '#${user['id']}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[500]
                              : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Durum Etiketleri - Alt satırda
              Row(
                children: [
                  if (isSystemAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'System Admin',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.orange[300]
                              : Colors.orange[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else if (isAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Admin',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.orange[300]
                              : Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  if (isAdmin || isSystemAdmin) const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isBlocked
                          ? Colors.red.withValues(alpha: 0.2)
                          : Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isBlocked ? 'Bloklu' : 'Aktif',
                      style: TextStyle(
                        fontSize: 10,
                        color: isBlocked
                            ? (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.red[300]
                                  : Colors.red[700])
                            : (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.green[300]
                                  : Colors.green[700]),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Kayıt: ${user['created_at'] != null ? DateTime.parse(user['created_at']).toLocal().toString().split(' ')[0] : 'Bilinmiyor'}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[500]
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
