import 'package:flutter/material.dart';

class ProfileInfoCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onEdit;

  const ProfileInfoCard({super.key, required this.user, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final fontSize = isTablet ? 22.0 : 16.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kullanıcı Bilgileri',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: onEdit,
                  tooltip: 'Düzenle',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Kullanıcı Adı
            _buildInfoRow(
              context,
              Icons.person_outline,
              'Kullanıcı Adı: ',
              user['username'] ?? '',
              fontSize,
            ),
            const SizedBox(height: 12),

            // Ad
            _buildInfoRow(
              context,
              Icons.badge_outlined,
              'Ad: ',
              user['first_name'] ?? '',
              fontSize,
            ),
            const SizedBox(height: 12),

            // Soyad
            _buildInfoRow(
              context,
              Icons.badge_outlined,
              'Soyad: ',
              user['last_name'] ?? '',
              fontSize,
            ),
            const SizedBox(height: 12),

            // Meslek
            if (user['job_title'] != null &&
                user['job_title'].toString().isNotEmpty)
              _buildInfoRow(
                context,
                Icons.work_outline,
                'Meslek: ',
                user['job_title'] ?? '',
                fontSize,
              ),
            if (user['job_title'] != null &&
                user['job_title'].toString().isNotEmpty)
              const SizedBox(height: 12),

            // Kayıt Tarihi
            _buildInfoRow(
              context,
              Icons.calendar_today_outlined,
              'Kayıt Tarihi: ',
              user['created_at'] != null
                  ? DateTime.parse(
                      user['created_at'],
                    ).toLocal().toString().split(' ')[0]
                  : '',
              fontSize,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    double fontSize,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize * 0.9,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: fontSize * 0.9,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ],
    );
  }
}
