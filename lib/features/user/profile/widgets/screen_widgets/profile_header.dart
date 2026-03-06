import 'package:flutter/material.dart';
import '../../../../../widgets/cached_profile_avatar.dart';

/// Profil ekranı başlık widget'ı
class ProfileHeader extends StatelessWidget {
  final String? username;
  final String firstName;
  final String lastName;
  final String jobTitle;
  final String? profileImageUrl;

  const ProfileHeader({
    super.key,
    this.username,
    required this.firstName,
    required this.lastName,
    required this.jobTitle,
    this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final avatarRadius = isTablet ? 60.0 : 50.0;
    final nameSize = isTablet ? 28.0 : 24.0;
    final titleSize = isTablet ? 20.0 : 16.0;
    final fullName = '$firstName $lastName';

    return Column(
      children: [
        CachedProfileAvatar(
          imageUrl: profileImageUrl,
          name: fullName,
          radius: avatarRadius,
        ),
        const SizedBox(height: 16),
        Text(
          fullName,
          style: TextStyle(fontSize: nameSize, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          jobTitle,
          style: TextStyle(fontSize: titleSize, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        if (username != null)
          Text(
            '@$username',
            style: TextStyle(
              fontSize: titleSize * 0.9,
              color: Colors.grey[500],
            ),
          ),
      ],
    );
  }
}
