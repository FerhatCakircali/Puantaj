import 'package:flutter/material.dart';
import '../../../screens/constants/colors.dart';

/// Ortak profil bilgileri kartı
/// Hem worker hem user panelinde kullanılır
class SharedProfileInfoCard extends StatelessWidget {
  final String title; // Başlık parametresi eklendi
  final List<ProfileInfoField> fields;
  final VoidCallback onEdit;

  const SharedProfileInfoCard({
    super.key,
    this.title = 'Kullanıcı Bilgileri', // Varsayılan değer
    required this.fields,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;

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
                    title,
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
          ...fields.asMap().entries.map((entry) {
            final index = entry.key;
            final field = entry.value;
            return Column(
              children: [
                if (index > 0) SizedBox(height: screenWidth * 0.03),
                _buildInfoField(
                  context,
                  field.icon,
                  field.label,
                  field.value,
                  isDark,
                ),
              ],
            );
          }),
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

/// Profil bilgi alanı modeli
class ProfileInfoField {
  final IconData icon;
  final String label;
  final String value;

  const ProfileInfoField({
    required this.icon,
    required this.label,
    required this.value,
  });
}
