import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../../models/employee.dart';
import 'date_change_warning.dart';
import 'delete_records_confirmation_dialog.dart';
import 'trusted_status_switch.dart';
import '../controllers/edit_employee_controller.dart';
import 'edit_employee_header.dart';
import 'edit_employee_actions.dart';
import 'edit_employee_text_field.dart';
import 'edit_employee_date_selector.dart';

/// Çalışan düzenleme dialog'u - Modüler tasarım
class EditEmployeeDialog extends StatefulWidget {
  final Employee employee;
  final Future<bool> Function(int employeeId, DateTime date) onCheckRecords;
  final Future<void> Function(int employeeId, DateTime date) onDeleteRecords;
  final Future<void> Function(Employee employee) onUpdate;

  const EditEmployeeDialog({
    super.key,
    required this.employee,
    required this.onCheckRecords,
    required this.onDeleteRecords,
    required this.onUpdate,
  });

  /// Dialog'u göster
  static Future<void> show(
    BuildContext context, {
    required Employee employee,
    required Future<bool> Function(int employeeId, DateTime date)
    onCheckRecords,
    required Future<void> Function(int employeeId, DateTime date)
    onDeleteRecords,
    required Future<void> Function(Employee employee) onUpdate,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => EditEmployeeDialog(
        employee: employee,
        onCheckRecords: onCheckRecords,
        onDeleteRecords: onDeleteRecords,
        onUpdate: onUpdate,
      ),
    );
  }

  @override
  State<EditEmployeeDialog> createState() => _EditEmployeeDialogState();
}

class _EditEmployeeDialogState extends State<EditEmployeeDialog> {
  final _controller = EditEmployeeController();
  late TextEditingController nameController;
  late TextEditingController titleController;
  late TextEditingController phoneController;
  late TextEditingController usernameController;
  late TextEditingController emailController;
  late DateTime selectedDate;
  late bool isActive;
  late bool isTrusted;
  bool isStartDateChanged = false;
  bool hasRecordsBeforeNewDate = false;
  bool isProcessing = false;
  late final ScrollController _scrollController;

  final _usernameKey = GlobalKey();
  final _emailKey = GlobalKey();
  final _nameKey = GlobalKey();
  final _titleKey = GlobalKey();
  final _phoneKey = GlobalKey();
  final _dateKey = GlobalKey();

  late final FocusNode _nameFocus;
  late final FocusNode _titleFocus;
  late final FocusNode _phoneFocus;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.employee.name);
    titleController = TextEditingController(text: widget.employee.title);
    phoneController = TextEditingController(text: widget.employee.phone);
    usernameController = TextEditingController(
      text: widget.employee.username ?? 'Kullanıcı adı yok',
    );
    emailController = TextEditingController(
      text: widget.employee.email ?? 'Email yok',
    );
    selectedDate = widget.employee.startDate;
    isActive = widget.employee.isActive;
    isTrusted = widget.employee.isTrusted;
    _scrollController = ScrollController();
    _nameFocus = FocusNode();
    _titleFocus = FocusNode();
    _phoneFocus = FocusNode();

    _nameFocus.addListener(() {
      if (_nameFocus.hasFocus) _ensureVisible(_nameKey);
    });
    _titleFocus.addListener(() {
      if (_titleFocus.hasFocus) _ensureVisible(_titleKey);
    });
    _phoneFocus.addListener(() {
      if (_phoneFocus.hasFocus) _ensureVisible(_phoneKey);
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    titleController.dispose();
    phoneController.dispose();
    usernameController.dispose();
    emailController.dispose();
    _scrollController.dispose();
    _nameFocus.dispose();
    _titleFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  Future<void> _ensureVisible(GlobalKey key) async {
    await Future.delayed(const Duration(milliseconds: 60));
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      alignment: 0.2,
    );
  }

  Future<void> _handleDateSelection() async {
    _ensureVisible(_dateKey);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null || !mounted) return;

    final result = await _controller.handleDateChange(
      newDate: pickedDate,
      originalDate: widget.employee.startDate,
      employeeId: widget.employee.id,
      onCheckRecords: widget.onCheckRecords,
    );

    if (!result.isChanged) return;

    if (!mounted) return;

    setState(() {
      selectedDate = pickedDate;
      isStartDateChanged = result.isChanged;
      hasRecordsBeforeNewDate = result.hasRecordsBeforeNewDate;
    });

    if (result.hasRecordsBeforeNewDate && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'UYARI: Seçilen yeni giriş tarihinden önce bu çalışana ait kayıtlar mevcut. '
            'Değişikliği kaydetmeniz veri tutarsızlığına yol açabilir!',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _handleSave() async {
    // Validasyon
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İsim Soyisim alanı boş bırakılamaz'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unvan alanı boş bırakılamaz'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Telefon alanı boş bırakılamaz'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final updatedEmployee = Employee(
      id: widget.employee.id,
      name: nameController.text.trim(),
      title: titleController.text.trim(),
      phone: phoneController.text.trim(),
      startDate: selectedDate,
      userId: widget.employee.userId,
      isActive: isActive,
      isTrusted: isTrusted,
    );

    if (isStartDateChanged && hasRecordsBeforeNewDate) {
      final shouldContinue = await _showDeleteConfirmation();
      if (!shouldContinue || !mounted) return;

      setState(() => isProcessing = true);

      try {
        await _controller.updateWithRecordDeletion(
          employee: updatedEmployee,
          newStartDate: selectedDate,
          onDeleteRecords: widget.onDeleteRecords,
          onUpdate: widget.onUpdate,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Çalışan bilgileri güncellendi. ${DateFormat('dd/MM/yyyy').format(selectedDate)} tarihinden önceki kayıtlar silindi.',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;

        debugPrint(
          'EditEmployeeDialog: Güncelleme hatası (kayıt silme ile): $e',
        );

        // Oturum hatası kontrolü
        final errorMessage = e.toString();
        if (errorMessage.contains('Kullanıcı oturumu bulunamadı')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Oturumunuz sonlanmış. Lütfen tekrar giriş yapın.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          // Kullanıcıyı login sayfasına yönlendir
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('İşlem sırasında bir hata oluştu: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }

        // Hata durumunda dialog'u kapatma, isProcessing'i false yap
        setState(() => isProcessing = false);
      }
    } else {
      setState(() => isProcessing = true);

      try {
        await _controller.updateEmployee(
          employee: updatedEmployee,
          onUpdate: widget.onUpdate,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Çalışan bilgileri başarıyla güncellendi', style: const TextStyle(color: Colors.white))),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;

        debugPrint('EditEmployeeDialog: Güncelleme hatası: $e');

        // Oturum hatası kontrolü
        final errorMessage = e.toString();
        if (errorMessage.contains('Kullanıcı oturumu bulunamadı')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Oturumunuz sonlanmış. Lütfen tekrar giriş yapın.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
          // Kullanıcıyı login sayfasına yönlendir
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('İşlem sırasında bir hata oluştu: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }

        // Hata durumunda dialog'u kapatma, isProcessing'i false yap
        setState(() => isProcessing = false);
      }
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await DeleteRecordsConfirmationDialog.show(
      context,
      employeeName: widget.employee.name,
      newStartDate: selectedDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.sizeOf(context);
    final screenHeight = screenSize.height;
    final screenWidth = screenSize.width;

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.9),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(screenWidth * 0.08),
            ),
          ),
          child: Column(
            children: [
              RepaintBoundary(
                child: EditEmployeeHeader(
                  onClose: () => Navigator.pop(context),
                  isProcessing: isProcessing,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: EdgeInsets.all(screenWidth * 0.06),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        key: _usernameKey,
                        child: EditEmployeeTextField(
                          controller: usernameController,
                          label: 'Kullanıcı Adı',
                          icon: Icons.account_circle,
                          enabled: false,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Container(
                        key: _emailKey,
                        child: EditEmployeeTextField(
                          controller: emailController,
                          label: 'E-posta',
                          icon: Icons.email_outlined,
                          enabled: false,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Container(
                        key: _nameKey,
                        child: EditEmployeeTextField(
                          controller: nameController,
                          focusNode: _nameFocus,
                          label: 'İsim Soyisim',
                          icon: Icons.person_outline,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Container(
                        key: _titleKey,
                        child: EditEmployeeTextField(
                          controller: titleController,
                          focusNode: _titleFocus,
                          label: 'Unvan',
                          icon: Icons.work_outline,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Container(
                        key: _phoneKey,
                        child: EditEmployeeTextField(
                          controller: phoneController,
                          focusNode: _phoneFocus,
                          label: 'Telefon',
                          icon: Icons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      Container(
                        key: _dateKey,
                        child: EditEmployeeDateSelector(
                          selectedDate: selectedDate,
                          onTap: _handleDateSelection,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),
                      TrustedStatusSwitch(
                        isTrusted: isTrusted,
                        onChanged: (value) {
                          setState(() => isTrusted = value);
                        },
                      ),
                      if (isStartDateChanged && hasRecordsBeforeNewDate)
                        Padding(
                          padding: EdgeInsets.only(top: screenHeight * 0.02),
                          child: const DateChangeWarning(),
                        ),
                    ],
                  ),
                ),
              ),
              RepaintBoundary(
                child: EditEmployeeActions(
                  onSave: _handleSave,
                  onCancel: () => Navigator.pop(context),
                  isProcessing: isProcessing,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
