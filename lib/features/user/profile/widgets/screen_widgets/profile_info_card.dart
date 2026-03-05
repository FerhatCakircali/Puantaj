import 'package:flutter/material.dart';
import '../../../../../screens/constants/colors.dart';

/// Kullanıcı bilgileri kartı widget'ı
class ProfileInfoCard extends StatelessWidget {
  final String username;
  final String firstName;
  final String lastName;
  final String jobTitle;
  final String email;
  final VoidCallback onEdit;

  const ProfileInfoCard({
    super.key,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.jobTitle,
    required this.email,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final fullName = '$firstName $lastName';

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.1),
            blurRadius: screenWidth * 0.02,
            offset: Offset(0, screenWidth * 0.01),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: screenWidth * 0.1,
                    height: screenWidth * 0.1,
                    decoration: BoxDecoration(
                      color: primaryIndigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: primaryIndigo,
                      size: screenWidth * 0.05,
                    ),
                  ),
                  SizedBox(width: screenWidth * 0.03),
                  Text(
                    'Kullanıcı Bilgileri',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.edit_rounded,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : primaryIndigo,
                  size: screenWidth * 0.06,
                ),
                onPressed: onEdit,
                tooltip: 'Düzenle',
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.04),
          _buildInfoField(
            context,
            Icons.person_outline,
            'Kullanıcı Adı',
            username,
            isDark,
          ),
          SizedBox(height: screenWidth * 0.03),
          _buildInfoField(
            context,
            Icons.badge_outlined,
            'Ad Soyad',
            fullName,
            isDark,
          ),
          SizedBox(height: screenWidth * 0.03),
          _buildInfoField(
            context,
            Icons.work_outline,
            'Yapılan İş',
            jobTitle,
            isDark,
          ),
          SizedBox(height: screenWidth * 0.03),
          _buildInfoField(
            context,
            Icons.email_outlined,
            'E-posta',
            email,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoField(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    bool isDark,
  ) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.02),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : primaryIndigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(screenWidth * 0.015),
            ),
            child: Icon(
              icon,
              size: screenWidth * 0.045,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.7)
                  : primaryIndigo,
            ),
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: screenWidth * 0.005),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: screenWidth * 0.038,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
