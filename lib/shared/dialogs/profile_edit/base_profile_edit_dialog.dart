import 'dart:async';
import 'package:flutter/material.dart';
import 'controllers/profile_edit_controller.dart';
import 'models/profile_field_config.dart';
import 'widgets/profile_dialog_header.dart';
import 'widgets/profile_dialog_footer.dart';
import 'widgets/profile_text_field.dart';

/// Base profil düzenleme dialog'u
///
/// User ve Worker profil dialog'ları için ortak temel sınıf
abstract class BaseProfileEditDialog extends StatefulWidget {
  const BaseProfileEditDialog({super.key});
}

abstract class BaseProfileEditDialogState<T extends BaseProfileEditDialog>
    extends State<T> {
  late ProfileEditController controller;
  final Map<String, TextEditingController> textControllers = {};
  bool isSaving = false;
  String? usernameError;
  String? emailError;

  /// Alt sınıflar tarafından implement edilmesi gereken metodlar
  ProfileEditController createController();
  List<ProfileFieldEntry> getFieldEntries();
  Future<void> onSave();
  String getUsernameFieldKey();
  String? getEmailFieldKey();

  @override
  void initState() {
    super.initState();
    controller = createController();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (final entry in getFieldEntries()) {
      final textController = TextEditingController(text: entry.initialValue);
      textControllers[entry.key] = textController;

      if (entry.key == getUsernameFieldKey()) {
        textController.addListener(_validateUsername);
      } else if (getEmailFieldKey() != null &&
          entry.key == getEmailFieldKey()) {
        textController.addListener(_validateEmail);
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    for (final textController in textControllers.values) {
      textController.dispose();
    }
    super.dispose();
  }

  Future<void> _validateUsername() async {
    final username = textControllers[getUsernameFieldKey()]!.text.trim();
    final error = await controller.validateUsername(username);
    if (mounted) {
      setState(() => usernameError = error);
    }
  }

  Future<void> _validateEmail() async {
    final emailKey = getEmailFieldKey();
    if (emailKey == null) return;

    final email = textControllers[emailKey]!.text.trim();
    final entry = getFieldEntries().firstWhere((e) => e.key == emailKey);
    final error = await controller.validateEmail(
      email,
      isRequired: entry.config.isRequired,
    );
    if (mounted) {
      setState(() => emailError = error);
    }
  }

  Future<void> _handleSave() async {
    final validationError = _validateAllFields();
    if (validationError != null) {
      _showError(validationError);
      return;
    }

    if (usernameError != null) {
      _showError(usernameError!);
      return;
    }

    if (emailError != null) {
      _showError(emailError!);
      return;
    }

    setState(() => isSaving = true);

    try {
      await onSave();
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('BaseProfileEditDialog: Kaydetme hatası: $e');
      if (mounted) {
        _showError('Hata: $e');
        setState(() => isSaving = false);
      }
    }
  }

  String? _validateAllFields() {
    for (final entry in getFieldEntries()) {
      if (entry.config.isRequired) {
        final value = textControllers[entry.key]!.text.trim();
        if (value.isEmpty) {
          return '${entry.config.label} boş olamaz';
        }
      }
    }
    return null;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Dialog(
        backgroundColor: isDark ? const Color(0xFF0A0E1A) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
        ),
        child: Container(
          constraints: BoxConstraints(maxHeight: screenWidth * 1.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProfileDialogHeader(
                isSaving: isSaving,
                isDark: isDark,
                screenWidth: screenWidth,
                onClose: () => Navigator.pop(context),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _buildFields(theme, isDark, screenWidth),
                  ),
                ),
              ),
              ProfileDialogFooter(
                isSaving: isSaving,
                isDark: isDark,
                screenWidth: screenWidth,
                onCancel: () => Navigator.pop(context),
                onSave: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFields(ThemeData theme, bool isDark, double screenWidth) {
    final fields = <Widget>[];
    final entries = getFieldEntries();

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      String? errorText;

      if (entry.key == getUsernameFieldKey()) {
        errorText = usernameError;
      } else if (getEmailFieldKey() != null &&
          entry.key == getEmailFieldKey()) {
        errorText = emailError;
      }

      fields.add(
        ProfileTextField(
          controller: textControllers[entry.key]!,
          config: entry.config,
          errorText: errorText,
          theme: theme,
          isDark: isDark,
          screenWidth: screenWidth,
        ),
      );

      if (i < entries.length - 1) {
        fields.add(SizedBox(height: screenWidth * 0.04));
      }
    }

    return fields;
  }
}

/// Profil field entry
class ProfileFieldEntry {
  final String key;
  final ProfileFieldConfig config;
  final String initialValue;

  const ProfileFieldEntry({
    required this.key,
    required this.config,
    required this.initialValue,
  });
}
