import 'package:flutter/material.dart';
import '../../../../screens/constants/colors.dart';

/// Profil dialog header widget'ı
///
/// Dialog başlığını ve kapat butonunu içerir
class ProfileDialogHeader extends StatelessWidget {
  final bool isSaving;
  final bool isDark;
  final double screenWidth;
  final VoidCallback onClose;

  const ProfileDialogHeader({
    super.key,
    required this.isSaving,
    required this.isDark,
    required this.screenWidth,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Row(
            children: [
              Container(
                width: screenWidth * 0.1,
                height: screenWidth * 0.1,
                decoration: BoxDecoration(
                  color: primaryIndigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                child: Icon(
                  Icons.edit_rounded,
                  color: primaryIndigo,
                  size: screenWidth * 0.05,
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Text(
                  'Profil Düzenle',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : primaryIndigo,
                  ),
                ),
              ),
              IconButton(
                onPressed: isSaving ? null : onClose,
                icon: Icon(
                  Icons.close,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.grey.shade700,
                  size: screenWidth * 0.06,
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.shade200,
        ),
      ],
    );
  }
}
