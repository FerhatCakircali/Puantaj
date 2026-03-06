import 'package:flutter/material.dart';
import '../../../../widgets/cached_profile_avatar.dart';

class ProfileHeaderCard extends StatelessWidget {
  final Map<String, dynamic> user;

  const ProfileHeaderCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final fontSize = isTablet ? 22.0 : 16.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      margin: const EdgeInsets.only(bottom: 24),
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CachedProfileAvatar(
              imageUrl:
                  null, // User model'e profile_image_url eklendiğinde kullanılacak
              name: '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'
                  .trim(),
              radius: 44,
            ),
            const SizedBox(height: 16),
            Text(
              '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim(),
              style: TextStyle(
                fontSize: fontSize + 4,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (user['job_title'] != null &&
                user['job_title'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  user['job_title'],
                  style: TextStyle(
                    fontSize: fontSize,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
          ],
        ),
      ),
    );
  }
}
