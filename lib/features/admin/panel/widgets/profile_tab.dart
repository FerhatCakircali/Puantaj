import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';
import '../../../../widgets/shimmer_loading.dart';
import '../../../../utils/cached_future_builder.dart';
import 'profile_header_card.dart';
import 'profile_info_card.dart';
import 'profile_security_card.dart';

class ProfileTab extends StatelessWidget {
  final AuthService authService;
  final VoidCallback onChangePassword;
  final Function(Map<String, dynamic>) onEditProfile;

  const ProfileTab({
    super.key,
    required this.authService,
    required this.onChangePassword,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return CachedFutureBuilder<Map<String, dynamic>?>(
      future: () => authService.currentUser,
      cacheDuration: const Duration(minutes: 5),
      cacheKey: 'admin_profile',
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ProfileShimmer();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(
            child: Text(
              'Profil bilgileri yüklenemedi',
              style: TextStyle(fontSize: 16, color: Colors.red),
            ),
          );
        }

        final user = snapshot.data!;
        final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
        final padding = isTablet ? 32.0 : 16.0;

        return Padding(
          padding: EdgeInsets.all(padding),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar ve isim/ünvan başlığı
                ProfileHeaderCard(user: user),
                const SizedBox(height: 24),

                // Kullanıcı Bilgileri Kartı
                ProfileInfoCard(user: user, onEdit: () => onEditProfile(user)),
                const SizedBox(height: 24),

                // Güvenlik Kartı
                ProfileSecurityCard(onChangePassword: onChangePassword),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
