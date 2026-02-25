import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../screens/constants/colors.dart';

/// Kullanıcı bilgileri kartı widget'ı
class ProfileInfoCard extends StatelessWidget {
  final String? username;
  final TextEditingController usernameController;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController jobTitleController;
  final TextEditingController emailController;
  final String? usernameError;
  final bool isEditingProfile;
  final bool isLoading;
  final VoidCallback onEditToggle;
  final VoidCallback onSave;
  final Function(String) onUsernameChanged;

  const ProfileInfoCard({
    super.key,
    this.username,
    required this.usernameController,
    required this.firstNameController,
    required this.lastNameController,
    required this.jobTitleController,
    required this.emailController,
    this.usernameError,
    required this.isEditingProfile,
    required this.isLoading,
    required this.onEditToggle,
    required this.onSave,
    required this.onUsernameChanged,
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
                  isEditingProfile ? Icons.save_rounded : Icons.edit_rounded,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : primaryIndigo,
                  size: screenWidth * 0.06,
                ),
                onPressed: isLoading
                    ? null
                    : () {
                        if (!isEditingProfile) {
                          onEditToggle();
                        } else {
                          onSave();
                        }
                      },
                tooltip: isEditingProfile ? 'Kaydet' : 'Düzenle',
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.04),
          _buildTextField(
            context,
            controller: usernameController,
            label: 'Kullanıcı Adı',
            icon: Icons.person_outline,
            enabled: isEditingProfile,
            errorText: usernameError,
            maxLength: 30,
            onChanged: onUsernameChanged,
            isDark: isDark,
            screenWidth: screenWidth,
          ),
          SizedBox(height: screenWidth * 0.03),
          _buildTextField(
            context,
            controller: firstNameController,
            label: 'Ad',
            icon: Icons.person_outline,
            enabled: isEditingProfile,
            maxLength: 30,
            isDark: isDark,
            screenWidth: screenWidth,
          ),
          SizedBox(height: screenWidth * 0.03),
          _buildTextField(
            context,
            controller: lastNameController,
            label: 'Soyad',
            icon: Icons.person_outline,
            enabled: isEditingProfile,
            maxLength: 30,
            isDark: isDark,
            screenWidth: screenWidth,
          ),
          SizedBox(height: screenWidth * 0.03),
          _buildTextField(
            context,
            controller: jobTitleController,
            label: 'Yapılan İş',
            icon: Icons.work_outline,
            enabled: isEditingProfile,
            maxLength: 30,
            isDark: isDark,
            screenWidth: screenWidth,
          ),
          SizedBox(height: screenWidth * 0.03),
          _buildTextField(
            context,
            controller: emailController,
            label: 'Email Adresi',
            icon: Icons.email_outlined,
            enabled: isEditingProfile,
            keyboardType: TextInputType.emailAddress,
            isDark: isDark,
            screenWidth: screenWidth,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    required bool isDark,
    required double screenWidth,
    String? errorText,
    int? maxLength,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.white.withValues(alpha: 0.7) : primaryIndigo,
          size: screenWidth * 0.055,
        ),
        errorText: errorText,
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.shade300,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          borderSide: const BorderSide(color: primaryIndigo, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          borderSide: const BorderSide(color: Color(0xFFE89595)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          borderSide: const BorderSide(color: Color(0xFFE89595), width: 2),
        ),
        counterStyle: TextStyle(fontSize: screenWidth * 0.028),
      ),
      style: TextStyle(fontSize: screenWidth * 0.038),
      enabled: enabled,
      keyboardType: keyboardType,
      maxLength: maxLength,
      maxLengthEnforcement: maxLength != null
          ? MaxLengthEnforcement.enforced
          : null,
      onChanged: onChanged,
    );
  }
}
