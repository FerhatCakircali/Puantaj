import 'package:flutter/material.dart';

/// Kullanıcı bilgileri card widget'ı
class UserInfoCard extends StatelessWidget {
  final Map<String, dynamic> user;

  const UserInfoCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kullanıcı Bilgileri',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow('Ad', user['first_name'] ?? ''),
            _buildInfoRow('Soyad', user['last_name'] ?? ''),
            _buildInfoRow('Kullanıcı Adı', user['username'] ?? ''),
            _buildInfoRow('E-posta', user['email'] ?? ''),
            _buildInfoRow('Yapılan İş', user['job_title'] ?? ''),
            _buildInfoRow(
              'Kayıt Tarihi',
              user['created_at'] != null
                  ? DateTime.parse(
                      user['created_at'],
                    ).toLocal().toString().split(' ')[0]
                  : '',
            ),
            if (user['updated_at'] != null)
              _buildInfoRow(
                'Son Güncelleme',
                DateTime.parse(
                  user['updated_at'],
                ).toLocal().toString().split(' ')[0],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
