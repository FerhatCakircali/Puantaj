import 'package:flutter/material.dart';
import '../../widgets/screen_widgets/date_range_selector.dart';
import '../../widgets/screen_widgets/report_search_bar.dart';
import '../../widgets/screen_widgets/employee_report_card.dart';
import 'report_empty_state.dart';

/// Çalışan raporu sekmesi widget'ı
///
/// Çalışan bazlı raporları listeler.
class EmployeeReportTab extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final List<dynamic> filteredEmployees;
  final Map<int, Map<String, dynamic>> statsMap;
  final TextEditingController searchController;
  final VoidCallback onDateRangeSelect;
  final ValueChanged<String> onSearch;
  final VoidCallback onSearchClear;
  final ValueChanged<dynamic> onEmployeeTap;

  const EmployeeReportTab({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.filteredEmployees,
    required this.statsMap,
    required this.searchController,
    required this.onDateRangeSelect,
    required this.onSearch,
    required this.onSearchClear,
    required this.onEmployeeTap,
  });

  @override
  Widget build(BuildContext context) {
    const padding = 24.0;

    return Padding(
      padding: const EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DateRangeSelector(
            startDate: startDate,
            endDate: endDate,
            onTap: onDateRangeSelect,
          ),
          const SizedBox(height: 16),
          ReportSearchBar(
            controller: searchController,
            onChanged: onSearch,
            onClear: onSearchClear,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filteredEmployees.isEmpty
                ? ReportEmptyState(
                    hasSearchQuery: searchController.text.isNotEmpty,
                  )
                : _buildEmployeeList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeList(BuildContext context) {
    return ListView.separated(
      itemCount: filteredEmployees.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final emp = filteredEmployees[index];
        final stats = statsMap[emp.id] ?? {};
        return EmployeeReportCard(
          employee: emp,
          stats: stats,
          onTap: () => onEmployeeTap(emp),
          isTablet: MediaQuery.of(context).size.shortestSide >= 600,
        );
      },
    );
  }
}
