import 'package:flutter/material.dart';
import '../../../../../models/employee.dart';
import 'employee_selection_card/widgets/employee_selection_header.dart';
import 'employee_selection_card/widgets/employee_specific_toggle.dart';
import 'employee_selection_card/widgets/employee_search_field.dart';
import 'employee_selection_card/widgets/employee_empty_state.dart';
import 'employee_selection_card/widgets/employee_list_item.dart';

/// Çalışan seçim kartı
class EmployeeSelectionCard extends StatelessWidget {
  final bool isEmployeeSpecific;
  final Employee? selectedEmployee;
  final List<Employee> filteredEmployees;
  final TextEditingController employeeSearchController;
  final Function(bool) onEmployeeSpecificChanged;
  final Function(String) onEmployeeSearch;
  final Function(Employee) onEmployeeSelected;
  final VoidCallback onSearchClear;

  const EmployeeSelectionCard({
    super.key,
    required this.isEmployeeSpecific,
    required this.selectedEmployee,
    required this.filteredEmployees,
    required this.employeeSearchController,
    required this.onEmployeeSpecificChanged,
    required this.onEmployeeSearch,
    required this.onEmployeeSelected,
    required this.onSearchClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmployeeSelectionHeader(isDark: isDark),
          const SizedBox(height: 16),
          EmployeeSpecificToggle(
            isEmployeeSpecific: isEmployeeSpecific,
            onChanged: onEmployeeSpecificChanged,
            isDark: isDark,
          ),
          if (isEmployeeSpecific) ...[
            const SizedBox(height: 16),
            EmployeeSearchField(
              controller: employeeSearchController,
              onChanged: onEmployeeSearch,
              onClear: onSearchClear,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.25,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: filteredEmployees.isEmpty
                  ? EmployeeEmptyState(isDark: isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: filteredEmployees.length,
                      itemBuilder: (context, index) {
                        final employee = filteredEmployees[index];
                        final isSelected = selectedEmployee?.id == employee.id;
                        return EmployeeListItem(
                          employee: employee,
                          isSelected: isSelected,
                          onTap: () => onEmployeeSelected(employee),
                          isDark: isDark,
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
