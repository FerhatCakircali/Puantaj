import 'package:flutter/material.dart';
import '../../../../screens/constants/colors.dart';

/// Profil avatar kartı - Kullanıcı paneli tasarımı
/// Çalışanın adını, unvanını ve avatar'ını gösterir
class ProfileAvatarCard extends StatelessWidget {
  final String fullName;
  final String? title;
  final bool isTablet;

  const ProfileAvatarCard({
    super.key,
    required this.fullName,
    this.title,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final initial = fullName.trim().isNotEmpty
        ? fullName.trim()[0].toUpperCase()
        : '?';

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.06),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: screenWidth * 0.2,
            height: screenWidth * 0.2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryIndigo, primaryIndigo.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(screenWidth * 0.04),
              boxShadow: [
                BoxShadow(
                  color: primaryIndigo.withValues(alpha: 0.3),
                  blurRadius: screenWidth * 0.03,
                  offset: Offset(0, screenWidth * 0.01),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: screenWidth * 0.08,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: screenWidth * 0.04),
          Text(
            fullName,
            style: TextStyle(
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : primaryIndigo,
            ),
            textAlign: TextAlign.center,
          ),
          if (title != null && title!.isNotEmpty) ...[
            SizedBox(height: screenWidth * 0.01),
            Text(
              title!,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
