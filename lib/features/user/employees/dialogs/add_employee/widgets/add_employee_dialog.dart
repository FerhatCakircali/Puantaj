import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../models/employee.dart';
import '../../../../../../data/services/password_hasher.dart';

class AddEmployeeDialog extends StatefulWidget {
  final Function(Employee) onAdd;

  const AddEmployeeDialog({super.key, required this.onAdd});

  static Future<void> show(
    BuildContext context, {
    required Function(Employee) onAdd,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEmployeeDialog(onAdd: onAdd),
    );
  }

  @override
  State<AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<AddEmployeeDialog> {
  final _nameController = TextEditingController();
  final _titleController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _titleController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;

    return Container(
      height: mediaQuery.size.height * 0.9,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle Bar
          Container(
            margin: EdgeInsets.only(top: screenWidth * 0.03),
            width: screenWidth * 0.1,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
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
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.person_add_alt_1,
                    color: theme.colorScheme.onPrimary,
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
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTextField(
                    controller: _nameController,
                    label: 'İsim Soyisim',
                    icon: Icons.person_outline,
                    screenWidth: screenWidth,
                  ),
                  SizedBox(height: screenWidth * 0.04),
                  _buildTextField(
                    controller: _titleController,
                    label: 'Unvan',
                    icon: Icons.work_outline,
                    screenWidth: screenWidth,
                  ),
                  SizedBox(height: screenWidth * 0.04),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Telefon',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    screenWidth: screenWidth,
                  ),
                  SizedBox(height: screenWidth * 0.04),
                  _buildTextField(
                    controller: _usernameController,
                    label: 'Kullanıcı Adı (min 3 karakter)',
                    icon: Icons.account_circle,
                    screenWidth: screenWidth,
                  ),
                  SizedBox(height: screenWidth * 0.04),
                  _buildPasswordField(screenWidth),
                  SizedBox(height: screenWidth * 0.04),
                  _buildDatePicker(screenWidth),
                ],
              ),
            ),
          ),
          // Actions
          Container(
            padding: EdgeInsets.all(screenWidth * 0.06),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
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
                    padding: EdgeInsets.symmetric(vertical: screenWidth * 0.04),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.03),
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
        ],
      ),
    );
  }

  Widget _buildPasswordField(double screenWidth) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
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
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    required double screenWidth,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        filled: true,
        fillColor: isDark
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildDatePicker(double screenWidth) {
    return InkWell(
      borderRadius: BorderRadius.circular(screenWidth * 0.03),
      onTap: () async {
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
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
          ),
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.02),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: Theme.of(context).colorScheme.primary,
              size: screenWidth * 0.05,
            ),
            SizedBox(width: screenWidth * 0.02),
            Expanded(
              child: Text(
                'Giriş Tarihi: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
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
    if (_nameController.text.isEmpty ||
        _titleController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }

    if (_usernameController.text.length < 3) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı adı en az 3 karakter olmalıdır'),
        ),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Şifre en az 6 karakter olmalıdır')),
      );
      return;
    }

    // Şifreyi hash'le
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
      startDate: _selectedDate,
      username: _usernameController.text.trim().toLowerCase(),
      password: passwordHash,
    );

    widget.onAdd(employee);
    if (mounted) {
      Navigator.pop(context);
    }
  }
}
