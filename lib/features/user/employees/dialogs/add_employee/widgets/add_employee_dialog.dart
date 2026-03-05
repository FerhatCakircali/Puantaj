import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import '../../../../../../models/employee.dart';
import '../../../../../../data/services/password_hasher.dart';

class AddEmployeeDialog extends StatefulWidget {
  final Function(Employee) onAdd;
  final Future<bool> Function(String) onCheckUsername;
  final Future<bool> Function(String) onCheckEmail;

  const AddEmployeeDialog({
    super.key,
    required this.onAdd,
    required this.onCheckUsername,
    required this.onCheckEmail,
  });

  static Future<void> show(
    BuildContext context, {
    required Function(Employee) onAdd,
    required Future<bool> Function(String) onCheckUsername,
    required Future<bool> Function(String) onCheckEmail,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => AddEmployeeDialog(
        onAdd: onAdd,
        onCheckUsername: onCheckUsername,
        onCheckEmail: onCheckEmail,
      ),
    );
  }

  @override
  State<AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<AddEmployeeDialog> {
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  // Real-time validation
  String? _usernameError;
  String? _emailError;
  Timer? _usernameDebounce;
  Timer? _emailDebounce;

  late final DateFormat _dateFmt;
  late final ScrollController _scrollController;

  final _nameKey = GlobalKey();
  final _titleKey = GlobalKey();
  final _phoneKey = GlobalKey();
  final _emailKey = GlobalKey();
  final _usernameKey = GlobalKey();
  final _passKey = GlobalKey();
  final _pass2Key = GlobalKey();
  final _dateKey = GlobalKey();

  late final FocusNode _nameFocus;
  late final FocusNode _titleFocus;
  late final FocusNode _phoneFocus;
  late final FocusNode _emailFocus;
  late final FocusNode _usernameFocus;
  late final FocusNode _passFocus;
  late final FocusNode _pass2Focus;

  Timer? _ensureTimer;
  bool _isEnsuring = false;

  @override
  void initState() {
    super.initState();
    _dateFmt = DateFormat('dd/MM/yyyy');
    _scrollController = ScrollController();

    _nameFocus = FocusNode();
    _titleFocus = FocusNode();
    _phoneFocus = FocusNode();
    _emailFocus = FocusNode();
    _usernameFocus = FocusNode();
    _passFocus = FocusNode();
    _pass2Focus = FocusNode();

    // Real-time validation listeners
    _usernameController.addListener(_onUsernameChanged);
    _emailController.addListener(_onEmailChanged);

    void bind(FocusNode node, GlobalKey key) {
      node.addListener(() {
        if (node.hasFocus) _scheduleEnsureVisible(key);
      });
    }

    bind(_nameFocus, _nameKey);
    bind(_titleFocus, _titleKey);
    bind(_phoneFocus, _phoneKey);
    bind(_emailFocus, _emailKey);
    bind(_usernameFocus, _usernameKey);
    bind(_passFocus, _passKey);
    bind(_pass2Focus, _pass2Key);
  }

  @override
  void dispose() {
    _ensureTimer?.cancel();
    _usernameDebounce?.cancel();
    _emailDebounce?.cancel();

    _usernameController.removeListener(_onUsernameChanged);
    _emailController.removeListener(_onEmailChanged);

    _nameController.dispose();
    _titleController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();

    _scrollController.dispose();

    _nameFocus.dispose();
    _titleFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _usernameFocus.dispose();
    _passFocus.dispose();
    _pass2Focus.dispose();

    super.dispose();
  }

  void _scheduleEnsureVisible(GlobalKey key) {
    // Focus değişimlerinde spam olmasın
    _ensureTimer?.cancel();
    _ensureTimer = Timer(const Duration(milliseconds: 90), () {
      _ensureVisible(key);
    });
  }

  Future<void> _ensureVisible(GlobalKey key) async {
    if (!mounted || !_scrollController.hasClients) return;
    if (_isEnsuring) return;

    _isEnsuring = true;
    try {
      // Klavye açılışının ilk frame'leri otursun
      await Future.delayed(const Duration(milliseconds: 120));
      if (!mounted || !_scrollController.hasClients) return;

      final ctx = key.currentContext;
      if (ctx == null) return;

      final renderObject = ctx.findRenderObject();
      if (renderObject == null) return;

      final viewport = RenderAbstractViewport.of(renderObject);
      // Alttaki alanlar için daha agresif yukarı taşı
      final isBottomField =
          identical(key, _pass2Key) || identical(key, _dateKey);

      final alignment = isBottomField ? 0.12 : 0.18;
      final extra = isBottomField ? 36.0 : 24.0;

      // Widget'ı scroll viewport içinde görünür yapacak offset
      final reveal = viewport.getOffsetToReveal(renderObject, alignment);

      final target = (reveal.offset - extra).clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent,
      );

      // Animasyon bazen jank'i artırıyor; jumpTo daha stabil
      final current = _scrollController.offset;
      if ((target - current).abs() > 2) {
        _scrollController.jumpTo(target);
      }
    } finally {
      _isEnsuring = false;
    }
  }

  void _onUsernameChanged() {
    final username = _usernameController.text.trim();

    // Debounce: 500ms bekle
    _usernameDebounce?.cancel();

    if (username.isEmpty) {
      setState(() => _usernameError = null);
      return;
    }

    if (username.length < 3) {
      setState(() => _usernameError = 'En az 3 karakter olmalı');
      return;
    }

    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      final exists = await widget.onCheckUsername(username.toLowerCase());
      if (mounted) {
        setState(() {
          _usernameError = exists
              ? 'Bu kullanıcı adı zaten kullanılıyor'
              : null;
        });
      }
    });
  }

  void _onEmailChanged() {
    final email = _emailController.text.trim();

    // Debounce: 500ms bekle
    _emailDebounce?.cancel();

    if (email.isEmpty) {
      setState(() => _emailError = null);
      return;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) {
      setState(() => _emailError = 'Geçerli bir e-posta adresi girin');
      return;
    }

    _emailDebounce = Timer(const Duration(milliseconds: 500), () async {
      final exists = await widget.onCheckEmail(email.toLowerCase());
      if (mounted) {
        setState(() {
          _emailError = exists ? 'Bu e-posta adresi zaten kullanılıyor' : null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.9),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(screenWidth * 0.07),
            ),
          ),
          child: Column(
            children: [
              // Handle Bar
              Container(
                margin: EdgeInsets.only(top: screenWidth * 0.03),
                width: screenWidth * 0.1,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              RepaintBoundary(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.06,
                    screenWidth * 0.05,
                    screenWidth * 0.06,
                    screenWidth * 0.04,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: screenWidth * 0.12,
                        height: screenWidth * 0.12,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.primary.withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.03,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.person_add_alt_1,
                          color: colorScheme.onPrimary,
                          size: screenWidth * 0.06,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yeni Çalışan',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Çalışan bilgilerini girin',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Divider(height: 1, color: colorScheme.outlineVariant),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  // ❗️SABİT padding: viewInsets yok → klavye animasyonu sırasında layout spam olmaz
                  padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.06,
                    screenWidth * 0.06,
                    screenWidth * 0.06,
                    screenWidth * 0.06,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        key: _nameKey,
                        child: _buildTextField(
                          controller: _nameController,
                          focusNode: _nameFocus,
                          label: 'İsim Soyisim',
                          icon: Icons.person_outline,
                          keyboardType: TextInputType.name,
                          colorScheme: colorScheme,
                          isDark: isDark,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.04),

                      Container(
                        key: _titleKey,
                        child: _buildTextField(
                          controller: _titleController,
                          focusNode: _titleFocus,
                          label: 'Unvan',
                          icon: Icons.work_outline,
                          keyboardType: TextInputType.text,
                          colorScheme: colorScheme,
                          isDark: isDark,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.04),

                      Container(
                        key: _phoneKey,
                        child: _buildTextField(
                          controller: _phoneController,
                          focusNode: _phoneFocus,
                          label: 'Telefon',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                          colorScheme: colorScheme,
                          isDark: isDark,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.04),

                      Container(
                        key: _emailKey,
                        child: _buildTextField(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          label: 'E-posta',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          colorScheme: colorScheme,
                          isDark: isDark,
                          errorText: _emailError,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.04),

                      Container(
                        key: _usernameKey,
                        child: _buildTextField(
                          controller: _usernameController,
                          focusNode: _usernameFocus,
                          label: 'Kullanıcı Adı (min 3 karakter)',
                          icon: Icons.account_circle,
                          keyboardType: TextInputType.text,
                          colorScheme: colorScheme,
                          isDark: isDark,
                          errorText: _usernameError,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.04),

                      Container(
                        key: _passKey,
                        child: _buildPasswordField(
                          colorScheme: colorScheme,
                          isDark: isDark,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.04),

                      Container(
                        key: _pass2Key,
                        child: _buildPasswordConfirmField(
                          colorScheme: colorScheme,
                          isDark: isDark,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.04),

                      Container(
                        key: _dateKey,
                        child: _buildDatePicker(
                          screenWidth: screenWidth,
                          colorScheme: colorScheme,
                          isDark: isDark,
                        ),
                      ),

                      // En altta ekstra nefes alanı: klavye varken de scroll yapabil
                      const SizedBox(height: 140),
                    ],
                  ),
                ),
              ),

              // Actions
              RepaintBoundary(
                child: Container(
                  padding: EdgeInsets.all(screenWidth * 0.06),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.1),
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        FilledButton.icon(
                          onPressed: _handleAdd,
                          icon: Icon(Icons.save, size: screenWidth * 0.045),
                          label: Text(
                            'Çalışan Ekle',
                            style: TextStyle(
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              vertical: screenWidth * 0.04,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.03,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.03),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('İptal'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    final fillColor = isDark
        ? colorScheme.surfaceContainerHighest
        : colorScheme.surfaceContainerHigh;
    const borderRadius = BorderRadius.all(Radius.circular(12));

    return TextField(
      controller: _passwordController,
      focusNode: _passFocus,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'Şifre (min 6 karakter)',
        prefixIcon: Icon(Icons.lock_outline, color: colorScheme.primary),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      onEditingComplete: () => _pass2Focus.requestFocus(),
    );
  }

  Widget _buildPasswordConfirmField({
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    final fillColor = isDark
        ? colorScheme.surfaceContainerHighest
        : colorScheme.surfaceContainerHigh;
    const borderRadius = BorderRadius.all(Radius.circular(12));

    return TextField(
      controller: _passwordConfirmController,
      focusNode: _pass2Focus,
      obscureText: _obscurePasswordConfirm,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: 'Şifre Tekrar',
        prefixIcon: Icon(Icons.lock_outline, color: colorScheme.primary),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePasswordConfirm
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () {
            setState(() => _obscurePasswordConfirm = !_obscurePasswordConfirm);
          },
        ),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    required ColorScheme colorScheme,
    required bool isDark,
    String? errorText,
  }) {
    final fillColor = isDark
        ? colorScheme.surfaceContainerHighest
        : colorScheme.surfaceContainerHigh;
    const borderRadius = BorderRadius.all(Radius.circular(12));

    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        errorText: errorText,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
      ),
      onEditingComplete: () {
        // sıradaki focus zaten OS tarafından da yönetilir; biz spamlemeyelim
        FocusScope.of(context).nextFocus();
      },
    );
  }

  Widget _buildDatePicker({
    required double screenWidth,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(screenWidth * 0.03),
      onTap: () async {
        _scheduleEnsureVisible(_dateKey);

        final pickedDate = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null && mounted) {
          setState(() => _selectedDate = pickedDate);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: screenWidth * 0.035,
          horizontal: screenWidth * 0.03,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
          ),
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.02),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: colorScheme.primary,
              size: screenWidth * 0.05,
            ),
            SizedBox(width: screenWidth * 0.02),
            Expanded(
              child: Text(
                'Giriş Tarihi: ${_dateFmt.format(_selectedDate)}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Icon(
              Icons.edit_calendar,
              color: Colors.grey,
              size: screenWidth * 0.05,
            ),
          ],
        ),
      ),
    );
  }

  void _handleAdd() async {
    // Real-time validation hatası varsa ekleme yapma
    if (_usernameError != null || _emailError != null) {
      if (!mounted) return;
      _showErrorSnackBar('Lütfen hataları düzeltin');
      return;
    }

    if (_nameController.text.isEmpty ||
        _titleController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _passwordConfirmController.text.isEmpty) {
      if (!mounted) return;
      _showErrorSnackBar('Lütfen tüm alanları doldurun');
      return;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(_emailController.text.trim())) {
      if (!mounted) return;
      _showErrorSnackBar('Geçerli bir e-posta adresi girin');
      return;
    }

    if (_usernameController.text.length < 3) {
      if (!mounted) return;
      _showErrorSnackBar('Kullanıcı adı en az 3 karakter olmalıdır');
      return;
    }

    if (_passwordController.text.length < 6) {
      if (!mounted) return;
      _showErrorSnackBar('Şifre en az 6 karakter olmalıdır');
      return;
    }

    if (_passwordController.text != _passwordConfirmController.text) {
      if (!mounted) return;
      _showErrorSnackBar('Şifreler eşleşmiyor');
      return;
    }

    // Kullanıcı adı kontrolü
    debugPrint(
      '🔍 Dialog: Kullanıcı adı kontrolü başlıyor: ${_usernameController.text.trim().toLowerCase()}',
    );
    final usernameExists = await widget.onCheckUsername(
      _usernameController.text.trim().toLowerCase(),
    );
    debugPrint('🔍 Dialog: Kullanıcı adı kontrolü sonucu: $usernameExists');
    if (!mounted) return;
    if (usernameExists) {
      _showErrorSnackBar('Bu kullanıcı adı zaten kullanılıyor');
      return;
    }

    // E-posta kontrolü
    debugPrint(
      '🔍 Dialog: E-posta kontrolü başlıyor: ${_emailController.text.trim().toLowerCase()}',
    );
    final emailExists = await widget.onCheckEmail(
      _emailController.text.trim().toLowerCase(),
    );
    debugPrint('🔍 Dialog: E-posta kontrolü sonucu: $emailExists');
    if (!mounted) return;
    if (emailExists) {
      _showErrorSnackBar('Bu e-posta adresi zaten kullanılıyor');
      return;
    }

    final passwordHasher = PasswordHasher.instance;
    final passwordHash = await passwordHasher.hashPassword(
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    final employee = Employee(
      id: 0,
      name: _nameController.text.trim(),
      title: _titleController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().toLowerCase(),
      startDate: _selectedDate,
      username: _usernameController.text.trim().toLowerCase(),
      password: passwordHash,
    );

    try {
      await widget.onAdd(employee);
      if (!mounted) return;

      _showSuccessSnackBar('Çalışan başarıyla eklendi');
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('❌ Hata: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
