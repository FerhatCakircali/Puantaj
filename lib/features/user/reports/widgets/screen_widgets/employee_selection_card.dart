import 'package:flutter/material.dart';
import '../../../../../models/employee.dart';
import '../../../../../screens/constants/colors.dart';

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
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primaryIndigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.person, color: primaryIndigo, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Çalışan Seçimi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Belirli bir çalışan için rapor',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isEmployeeSpecific
                            ? 'Seçili çalışan için rapor oluşturulacak'
                            : 'Tüm çalışanlar için rapor oluşturulacak',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.6)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Switch(
                  value: isEmployeeSpecific,
                  onChanged: onEmployeeSpecificChanged,
                  activeColor: Colors.white,
                  activeTrackColor: primaryIndigo,
                  inactiveThumbColor: isDark
                      ? Colors.grey.shade300
                      : Colors.white,
                  inactiveTrackColor: isDark
                      ? Colors.grey.shade800
                      : Colors.grey.shade400,
                  trackOutlineColor: MaterialStateProperty.resolveWith((
                    states,
                  ) {
                    if (states.contains(MaterialState.selected)) {
                      return Colors.transparent;
                    }
                    return isDark ? Colors.grey.shade600 : Colors.grey.shade500;
                  }),
                ),
              ],
            ),
          ),
          if (isEmployeeSpecific) ...[
            const SizedBox(height: 16),
            TextField(
              controller: employeeSearchController,
              onChanged: onEmployeeSearch,
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
                suffixIcon: employeeSearchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.grey.shade700,
                        ),
                        onPressed: onSearchClear,
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryIndigo, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryIndigo, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryIndigo, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
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
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_search,
                              size: 40,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Çalışan bulunamadı',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.5)
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: filteredEmployees.length,
                      itemBuilder: (context, index) {
                        final employee = filteredEmployees[index];
                        final isSelected = selectedEmployee?.id == employee.id;
                        return GestureDetector(
                          onTap: () => onEmployeeSelected(employee),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryIndigo.withValues(alpha: 0.1)
                                  : (isDark
                                        ? Colors.white.withValues(alpha: 0.03)
                                        : Colors.grey.shade50),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isSelected
                                    ? primaryIndigo
                                    : (isDark
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : Colors.grey.shade300),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? primaryIndigo
                                        : (isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.1,
                                                )
                                              : Colors.grey.shade200),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: Text(
                                      employee.name[0].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark
                                                  ? Colors.white
                                                  : Colors.black),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        employee.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      if (employee.title.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          employee.title,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.6,
                                                  )
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: primaryIndigo,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
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
