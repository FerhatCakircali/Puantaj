import 'package:flutter/material.dart';
import '../mixins/employee_screen_mixin.dart';
import '../../../../models/employee.dart';
import '../widgets/employee_search_bar_widget.dart';
import '../widgets/employee_identity_card.dart';
import '../widgets/employee_empty_state.dart';
import '../widgets/employee_header.dart';
import '../dialogs/add_employee/widgets/add_employee_dialog.dart';
import '../dialogs/edit_employee/widgets/edit_employee_dialog.dart';
import '../dialogs/delete_employee/widgets/delete_employee_dialog.dart';
import '../dialogs/delete_employee/widgets/delete_all_employees_dialog.dart';

/// Çalışan yönetim ekranı
///
/// Çalışan listesi, arama, ekleme, düzenleme ve silme işlemlerini yönetir.
/// Feature-based modüler yapıda tasarlanmıştır.
class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => EmployeeScreenState();
}

class EmployeeScreenState extends State<EmployeeScreen>
    with EmployeeScreenMixin {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadEmployees();
    _searchController.addListener(() {
      filterEmployees(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void showAddEmployeeDialog() {
    AddEmployeeDialog.show(
      context,
      onAdd: (employee) async {
        await addEmployee(employee);
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : employees.isEmpty
            ? const EmployeeEmptyState()
            : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    EmployeeSearchBarWidget(
                      controller: _searchController,
                      onChanged: filterEmployees,
                      onClear: () {
                        _searchController.clear();
                        filterEmployees('');
                      },
                    ),
                    const SizedBox(height: 16),
                    EmployeeHeader(
                      employeeCount: filteredEmployees.length,
                      onDeleteAll: _showDeleteAllEmployeesDialog,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filteredEmployees.length,
                        padding: const EdgeInsets.only(bottom: 100),
                        separatorBuilder: (context, i) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final emp = filteredEmployees[index];
                          return EmployeeIdentityCard(
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
}
