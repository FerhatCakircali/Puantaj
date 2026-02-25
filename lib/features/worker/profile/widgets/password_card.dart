import 'package:flutter/material.dart';
import '../../../../screens/constants/colors.dart';

/// Şifre değiştirme kartı - Kullanıcı paneli tasarımı
/// Güvenlik bölümünde şifre değiştirme butonu gösterir
class PasswordCard extends StatelessWidget {
  final bool isTablet;
  final VoidCallback onChangePassword;

  const PasswordCard({
    super.key,
    required this.isTablet,
    required this.onChangePassword,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

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
            children: [
              Container(
                width: screenWidth * 0.1,
                height: screenWidth * 0.1,
                decoration: BoxDecoration(
                  color: primaryIndigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                child: Icon(
                  Icons.lock_outline,
                  color: primaryIndigo,
                  size: screenWidth * 0.05,
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Text(
                'Güvenlik',
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.04),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onChangePassword,
              icon: Icon(Icons.lock_outline, size: screenWidth * 0.05),
              label: Text(
                'Şifre Değiştir',
                style: TextStyle(
                  fontSize: screenWidth * 0.038,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: primaryIndigo,
                padding: EdgeInsets.symmetric(vertical: screenWidth * 0.035),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                elevation: 2,
                shadowColor: primaryIndigo.withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
