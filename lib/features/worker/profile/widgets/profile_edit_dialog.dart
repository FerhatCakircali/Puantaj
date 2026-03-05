import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../screens/constants/colors.dart';
import '../../../../services/validation_service.dart';

/// Profil düzenleme dialog'u
/// Kullanıcı bilgilerini düzenleme formu
class ProfileEditDialog extends StatefulWidget {
  final int workerId; // Çalışan ID'si eklendi
  final String username;
  final String fullName;
  final String? title;
  final String? phone;
  final String? email;
  final Future<void> Function({
    required String username,
    required String fullName,
    String? title,
    String? phone,
    String? email,
  })
  onSave;

  const ProfileEditDialog({
    super.key,
    required this.workerId, // Zorunlu parametre
    required this.username,
    required this.fullName,
    this.title,
    this.phone,
    this.email,
    required this.onSave,
  });

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  final _validationService = ValidationService.instance;

  late TextEditingController _usernameController;
  late TextEditingController _fullNameController;
  late TextEditingController _titleController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  bool _isSaving = false;
  String? _usernameError;
  String? _emailError;
  Timer? _usernameDebounce;
  Timer? _emailDebounce;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.username);
    _fullNameController = TextEditingController(text: widget.fullName);
    _titleController = TextEditingController(text: widget.title ?? '');
    _phoneController = TextEditingController(text: widget.phone ?? '');
    _emailController = TextEditingController(text: widget.email ?? '');
    _usernameController.addListener(_validateUsername);
    _emailController.addListener(_validateEmail);
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _emailDebounce?.cancel();
    _usernameController.removeListener(_validateUsername);
    _emailController.removeListener(_validateEmail);
    _usernameController.dispose();
    _fullNameController.dispose();
    _titleController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _validateUsername() async {
    _usernameDebounce?.cancel();

    final username = _usernameController.text.trim();

    if (username.isEmpty) {
      setState(() => _usernameError = 'Kullanıcı adı gerekli');
      return;
    }

    // Format kontrolü
    final formatError = _validationService.validateUsernameFormat(username);
    if (formatError != null) {
      setState(() => _usernameError = formatError);
      return;
    }

    // Değişmemişse kontrol etme
    if (username.toLowerCase() == widget.username.toLowerCase()) {
      setState(() => _usernameError = null);
      return;
    }

    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      // ValidationService kullanarak kontrol et - kendi ID'sini hariç tut
      final availabilityError = await _validationService
          .checkUsernameAvailability(
            username,
            excludeWorkerId: widget.workerId,
          );

      if (mounted) {
        setState(() => _usernameError = availabilityError);
      }
    });
  }

  Future<void> _validateEmail() async {
    _emailDebounce?.cancel();

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _emailError = null);
      return;
    }

    // Format kontrolü
    final formatError = _validationService.validateEmailFormat(email);
    if (formatError != null) {
      setState(() => _emailError = formatError);
      return;
    }

    // Değişmemişse kontrol etme
    if (email.toLowerCase() == (widget.email ?? '').toLowerCase()) {
      setState(() => _emailError = null);
      return;
    }

    _emailDebounce = Timer(const Duration(milliseconds: 500), () async {
      // ValidationService kullanarak kontrol et - kendi ID'sini hariç tut
      final availabilityError = await _validationService.checkEmailAvailability(
        email,
        excludeWorkerId: widget.workerId,
      );

      if (mounted) {
        setState(() => _emailError = availabilityError);
      }
    });
  }

  Future<void> _handleSave() async {
    if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kullanıcı adı boş olamaz')));
      return;
    }

    if (_fullNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ad Soyad boş olamaz')));
      return;
    }

    if (_usernameError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_usernameError!)));
      return;
    }

    // Email validasyonu
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('E-posta adresi gerekli')));
      return;
    }

    if (_emailError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_emailError!)));
      return;
    }

    setState(() => _isSaving = true);

    try {
      await widget.onSave(
        username: _usernameController.text.trim(),
        fullName: _fullNameController.text.trim(),
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        email: _emailController.text.trim(),
      );

      // onSave başarılı olduysa dialog'u kapat
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      // Hata durumunda dialog'u kapatma, kullanıcıya göster
      debugPrint('❌ ProfileEditDialog: Kaydetme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata: $e')));
        setState(() => _isSaving = false);
      }
    }
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
              // Header
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
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.pop(context),
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
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildUsernameField(theme, isDark, screenWidth),
                      SizedBox(height: screenWidth * 0.04),
                      _buildFullNameField(theme, isDark, screenWidth),
                      SizedBox(height: screenWidth * 0.04),
                      _buildTitleField(theme, isDark, screenWidth),
                      SizedBox(height: screenWidth * 0.04),
                      _buildPhoneField(theme, isDark, screenWidth),
                      SizedBox(height: screenWidth * 0.04),
                      _buildEmailField(theme, isDark, screenWidth),
                    ],
                  ),
                ),
              ),
              // Bottom Actions - SafeArea ile navigation bar'dan korunuyor
              SafeArea(
                top: false,
                child: Container(
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.grey.shade50,
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: screenWidth * 0.035,
                            ),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.grey.shade300,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.02,
                              ),
                            ),
                          ),
                          child: Text(
                            'İptal',
                            style: TextStyle(
                              fontSize: screenWidth * 0.038,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isSaving ? null : _handleSave,
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryIndigo,
                            padding: EdgeInsets.symmetric(
                              vertical: screenWidth * 0.035,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.02,
                              ),
                            ),
                          ),
                          child: _isSaving
                              ? SizedBox(
                                  width: screenWidth * 0.04,
                                  height: screenWidth * 0.04,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Kaydet',
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.038,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameField(ThemeData theme, bool isDark, double screenWidth) {
    return TextField(
      controller: _usernameController,
      decoration: InputDecoration(
        labelText: 'Kullanıcı Adı *',
        hintText: 'En az 3 karakter',
        errorText: _usernameError,
        prefixIcon: Icon(
          Icons.account_circle_outlined,
          color: isDark
              ? Colors.white.withValues(alpha: 0.7)
              : theme.colorScheme.primary,
          size: screenWidth * 0.055,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          borderSide: BorderSide(color: primaryIndigo, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
        ),
        counterStyle: TextStyle(fontSize: screenWidth * 0.028),
      ),
      style: TextStyle(fontSize: screenWidth * 0.038),
      maxLength: 30,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
    );
  }

  Widget _buildFullNameField(ThemeData theme, bool isDark, double screenWidth) {
    return TextField(
      controller: _fullNameController,
      decoration: InputDecoration(
        labelText: 'Ad Soyad *',
        prefixIcon: Icon(
          Icons.person_outline,
          color: isDark
              ? Colors.white.withValues(alpha: 0.7)
              : theme.colorScheme.primary,
          size: screenWidth * 0.055,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          borderSide: BorderSide(color: primaryIndigo, width: 2),
        ),
        counterStyle: TextStyle(fontSize: screenWidth * 0.028),
      ),
      style: TextStyle(fontSize: screenWidth * 0.038),
      maxLength: 50,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
    );
  }

  Widget _buildTitleField(ThemeData theme, bool isDark, double screenWidth) {
    return TextField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'Yapılan İş',
        prefixIcon: Icon(
          Icons.work_outline,
          color: isDark
              ? Colors.white.withValues(alpha: 0.7)
              : theme.colorScheme.primary,
          size: screenWidth * 0.055,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          borderSide: BorderSide(color: primaryIndigo, width: 2),
        ),
        counterStyle: TextStyle(fontSize: screenWidth * 0.028),
      ),
      style: TextStyle(fontSize: screenWidth * 0.038),
      maxLength: 30,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
    );
  }

  Widget _buildPhoneField(ThemeData theme, bool isDark, double screenWidth) {
    return TextField(
      controller: _phoneController,
      decoration: InputDecoration(
        labelText: 'Telefon',
        prefixIcon: Icon(
          Icons.phone,
          color: isDark
              ? Colors.white.withValues(alpha: 0.7)
              : theme.colorScheme.primary,
          size: screenWidth * 0.055,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          borderSide: BorderSide(color: primaryIndigo, width: 2),
        ),
        counterStyle: TextStyle(fontSize: screenWidth * 0.028),
      ),
      style: TextStyle(fontSize: screenWidth * 0.038),
      keyboardType: TextInputType.phone,
      maxLength: 15,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
    );
  }

  Widget _buildEmailField(ThemeData theme, bool isDark, double screenWidth) {
    return TextField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: 'E-posta Adresi',
        errorText: _emailError,
        prefixIcon: Icon(
          Icons.email_outlined,
          color: isDark
              ? Colors.white.withValues(alpha: 0.7)
              : theme.colorScheme.primary,
          size: screenWidth * 0.055,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          borderSide: BorderSide(color: primaryIndigo, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.02),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
        ),
      ),
      style: TextStyle(fontSize: screenWidth * 0.038),
      keyboardType: TextInputType.emailAddress,
    );
  }
}
