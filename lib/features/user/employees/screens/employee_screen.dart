import 'package:flutter/material.dart';
import '../mixins/employee_screen_mixin.dart';
import '../../../../models/employee.dart';
import '../widgets/employee_identity_card.dart';
import '../widgets/employee_empty_state.dart';
import '../widgets/employee_header.dart';
import '../dialogs/add_employee/widgets/add_employee_dialog.dart';
import '../dialogs/edit_employee/widgets/edit_employee_dialog.dart';
import '../dialogs/delete_employee/widgets/delete_employee_dialog.dart';
import '../dialogs/delete_employee/widgets/delete_all_employees_dialog.dart';

/// Çalışan yönetim ekranı
/// Çalışan listesi, arama, ekleme, düzenleme ve silme işlemlerini yönetir.
/// Feature-based modüler yapıda tasarlanmıştır.
class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => EmployeeScreenState();
}

class EmployeeScreenState extends State<EmployeeScreen>
    with WidgetsBindingObserver, EmployeeScreenMixin {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadEmployees();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    filterEmployees(_searchController.text);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // ⚡ ÖNEMLİ: Memory leak önlemek için listener'ı kaldır
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Uygulama ön plana geldiğinde verileri yenile
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        // Çalışanları yeniden yükle (internet geri geldiyse güncel verileri alır)
        loadEmployees();
      }
    }
  }

  void showAddEmployeeDialog() {
    AddEmployeeDialog.show(
      context,
      onAdd: (employee) async {
        await addEmployee(employee);
      },
      onCheckUsername: (username) async {
        return await isUsernameExists(username);
      },
      onCheckEmail: (email) async {
        return await isEmailExists(email);
      },
    );
  }

  void _showEditEmployeeDialog(Employee employee) {
    EditEmployeeDialog.show(
      context,
      employee: employee,
      onCheckRecords: hasRecordsBeforeDate,
      onDeleteRecords: deleteRecordsBeforeDate,
      onUpdate: updateEmployee,
    );
  }

  void _showDeleteEmployeeDialog(Employee employee) {
    DeleteEmployeeDialog.show(
      context,
      employee: employee,
      onDelete: deleteEmployee,
      onComplete: () {
        if (mounted) {
          setState(() => isLoading = false);
        }
      },
    );
  }

  void _showDeleteAllEmployeesDialog() {
    DeleteAllEmployeesDialog.show(
      context,
      onDeleteAll: deleteAllEmployees,
      onComplete: () {
        if (mounted) {
          setState(() => isLoading = false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final w = size.width;
    final h = size.height;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : employees.isEmpty
            ? const EmployeeEmptyState()
            : Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.06,
                  vertical: h * 0.02,
                ),
                child: Column(
                  children: [
                    _buildSearchBar(theme),
                    SizedBox(height: h * 0.02),
                    EmployeeHeader(
                      employeeCount: filteredEmployees.length,
                      onDeleteAll: _showDeleteAllEmployeesDialog,
                    ),
                    SizedBox(height: h * 0.015),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filteredEmployees.length,
                        padding: EdgeInsets.only(bottom: h * 0.12),
                        separatorBuilder: (context, i) =>
                            SizedBox(height: h * 0.02),
                        itemBuilder: (context, index) {
                          final emp = filteredEmployees[index];
                          return EmployeeIdentityCard(
                            key: ValueKey('employee_${emp.id}'),
                            employee: emp,
                            onEdit: () => _showEditEmployeeDialog(emp),
                            onDelete: () => _showDeleteEmployeeDialog(emp),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return TextField(
      controller: _searchController,
      onChanged: filterEmployees,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: 'Çalışan ara...',
        hintStyle: TextStyle(
          color: isDark
              ? Colors.white.withValues(alpha: 0.5)
              : Colors.grey.shade600,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: isDark
              ? Colors.white.withValues(alpha: 0.7)
              : Colors.grey.shade700,
        ),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.grey.shade700,
                ),
                onPressed: () {
                  _searchController.clear();
                  filterEmployees('');
                },
              )
            : null,
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
