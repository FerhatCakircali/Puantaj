import 'package:flutter/material.dart';
import '../../../../../../models/employee.dart';
import '../controllers/add_employee_controller.dart';
import '../helpers/scroll_helper.dart';
import '../../../../../../shared/helpers/snackbar_helper.dart';
import 'employee_form_fields.dart';
import 'employee_date_picker.dart';
import '../../../../../../shared/widgets/dialog/dialog_handle_bar.dart';
import '../../../../../../shared/widgets/dialog/dialog_header.dart';
import '../../../../../../shared/widgets/dialog/dialog_actions.dart';

/// Yeni çalışan ekleme dialog'u
///
/// Çalışan bilgilerini toplar, validate eder ve kayıt işlemini gerçekleştirir.
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
  late final AddEmployeeController _controller;
  late final ScrollHelper _scrollHelper;

  final _nameKey = GlobalKey();
  final _titleKey = GlobalKey();
  final _phoneKey = GlobalKey();
  final _emailKey = GlobalKey();
  final _usernameKey = GlobalKey();
  final _passKey = GlobalKey();
  final _pass2Key = GlobalKey();
  final _dateKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AddEmployeeController(
      onCheckUsername: widget.onCheckUsername,
      onCheckEmail: widget.onCheckEmail,
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );

    _scrollHelper = ScrollHelper(_controller.scrollController);

    _scrollHelper.bindFocusNode(_controller.nameFocus, _nameKey);
    _scrollHelper.bindFocusNode(_controller.titleFocus, _titleKey);
    _scrollHelper.bindFocusNode(_controller.phoneFocus, _phoneKey);
    _scrollHelper.bindFocusNode(_controller.emailFocus, _emailKey);
    _scrollHelper.bindFocusNode(_controller.usernameFocus, _usernameKey);
    _scrollHelper.bindFocusNode(_controller.passFocus, _passKey);
    _scrollHelper.bindFocusNode(_controller.pass2Focus, _pass2Key);
  }

  @override
  void dispose() {
    _scrollHelper.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
              DialogHandleBar(
                screenWidth: screenWidth,
                colorScheme: colorScheme,
              ),
              DialogHeader(
                screenWidth: screenWidth,
                theme: theme,
                colorScheme: colorScheme,
                title: 'Yeni Çalışan',
                subtitle: 'Çalışan bilgilerini girin',
                icon: Icons.person_add_alt_1,
                onClose: () => Navigator.pop(context),
              ),
              Divider(height: 1, color: colorScheme.outlineVariant),
              Expanded(child: _buildContent(screenWidth)),
              DialogActions(
                screenWidth: screenWidth,
                colorScheme: colorScheme,
                saveLabel: 'Çalışan Ekle',
                saveIcon: Icons.save,
                onSave: _handleAdd,
                onCancel: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(double screenWidth) {
    return SingleChildScrollView(
      controller: _controller.scrollController,
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
            child: EmployeeFormField(
              controller: _controller.nameController,
              focusNode: _controller.nameFocus,
              label: 'İsim Soyisim',
              icon: Icons.person_outline,
              keyboardType: TextInputType.name,
            ),
          ),
          SizedBox(height: screenWidth * 0.04),
          Container(
            key: _titleKey,
            child: EmployeeFormField(
              controller: _controller.titleController,
              focusNode: _controller.titleFocus,
              label: 'Unvan',
              icon: Icons.work_outline,
              keyboardType: TextInputType.text,
            ),
          ),
          SizedBox(height: screenWidth * 0.04),
          Container(
            key: _phoneKey,
            child: EmployeeFormField(
              controller: _controller.phoneController,
              focusNode: _controller.phoneFocus,
              label: 'Telefon',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
          ),
          SizedBox(height: screenWidth * 0.04),
          Container(
            key: _emailKey,
            child: EmployeeFormField(
              controller: _controller.emailController,
              focusNode: _controller.emailFocus,
              label: 'E-posta',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              errorText: _controller.validator.emailError,
            ),
          ),
          SizedBox(height: screenWidth * 0.04),
          Container(
            key: _usernameKey,
            child: EmployeeFormField(
              controller: _controller.usernameController,
              focusNode: _controller.usernameFocus,
              label: 'Kullanıcı Adı (min 3 karakter)',
              icon: Icons.account_circle,
              keyboardType: TextInputType.text,
              errorText: _controller.validator.usernameError,
            ),
          ),
          SizedBox(height: screenWidth * 0.04),
          Container(
            key: _passKey,
            child: PasswordFormField(
              controller: _controller.passwordController,
              focusNode: _controller.passFocus,
              label: 'Şifre (min 6 karakter)',
              obscureText: _controller.obscurePassword,
              onToggleVisibility: _controller.togglePasswordVisibility,
              onEditingComplete: () => _controller.pass2Focus.requestFocus(),
            ),
          ),
          SizedBox(height: screenWidth * 0.04),
          Container(
            key: _pass2Key,
            child: PasswordFormField(
              controller: _controller.passwordConfirmController,
              focusNode: _controller.pass2Focus,
              label: 'Şifre Tekrar',
              obscureText: _controller.obscurePasswordConfirm,
              onToggleVisibility: _controller.togglePasswordConfirmVisibility,
            ),
          ),
          SizedBox(height: screenWidth * 0.04),
          Container(
            key: _dateKey,
            child: EmployeeDatePicker(
              selectedDate: _controller.selectedDate,
              onDateSelected: _controller.updateSelectedDate,
            ),
          ),
          const SizedBox(height: 140),
        ],
      ),
    );
  }

  Future<void> _handleAdd() async {
    final error = await _controller.validateAndPrepare();
    if (error != null) {
      if (!mounted) return;
      SnackBarHelper.showError(context, error);
      return;
    }

    try {
      final employee = await _controller.createEmployee();
      await widget.onAdd(employee);
      if (!mounted) return;

      SnackBarHelper.showSuccess(context, 'Çalışan başarıyla eklendi');
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Hata: $e');
    }
  }
}
