import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';
import 'user_edit/index.dart';

Future<bool?> showUserEditDialog({
  required BuildContext context,
  required Map<String, dynamic> user,
  required AuthService authService,
}) async {
  // System admin kontrolü
  final isTargetSystemAdmin = authService.isSystemAdmin(user);

  // System Administrator hiçbir şekilde düzenlenemez (kendisi bile)
  if (isTargetSystemAdmin) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('System Administrator bilgileri değiştirilemez.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
    return null;
  }

  final firstNameController = TextEditingController(
    text: user['first_name'] ?? '',
  );
  final lastNameController = TextEditingController(
    text: user['last_name'] ?? '',
  );
  final usernameController = TextEditingController(
    text: user['username'] ?? '',
  );
  final jobTitleController = TextEditingController(
    text: user['job_title'] ?? '',
  );
  bool isAdmin = user['is_admin'] == 1 || user['is_admin'] == true;
  bool isBlocked = user['is_blocked'] as bool;

  if (!context.mounted) return null;

  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) {
        // Debug için
        debugPrint('Dialog içinde isAdmin: $isAdmin');

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 16,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxWidth: 600,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                UserEditDialogHeader(
                  user: user,
                  onClose: () => Navigator.pop(context),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Kullanıcı Bilgileri Bölümü
                        UserInfoFormFields(
                          usernameController: usernameController,
                          firstNameController: firstNameController,
                          lastNameController: lastNameController,
                          jobTitleController: jobTitleController,
                        ),

                        const SizedBox(height: 24),

                        // Yetki ve Durum Bölümü
                        UserPermissionCards(
                          user: user,
                          authService: authService,
                          isAdmin: isAdmin,
                          isBlocked: isBlocked,
                          onAdminChanged: (value) {
                            setState(() {
                              isAdmin = value;
                            });
                          },
                          onBlockedChanged: (value) {
                            setState(() {
                              isBlocked = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer Actions
                UserEditDialogFooter(
                  user: user,
                  authService: authService,
                  usernameController: usernameController,
                  firstNameController: firstNameController,
                  lastNameController: lastNameController,
                  jobTitleController: jobTitleController,
                  isAdmin: isAdmin,
                  isBlocked: isBlocked,
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
