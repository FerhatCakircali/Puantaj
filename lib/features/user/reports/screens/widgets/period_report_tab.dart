import 'package:flutter/material.dart';
import '../../widgets/screen_widgets/period_selection_card.dart';
import '../../widgets/screen_widgets/employee_selection_card.dart';
import '../../../../../models/employee.dart';
import 'report_loading_indicator.dart';

/// Dönemsel rapor sekmesi widget'ı
///
/// Dönem bazlı raporları oluşturur.
class PeriodReportTab extends StatelessWidget {
  final ReportPeriod selectedPeriodType;
  final DateTime customStartDate;
  final DateTime customEndDate;
  final bool isEmployeeSpecific;
  final Employee? selectedEmployee;
  final List<Employee> filteredEmployees;
  final TextEditingController employeeSearchController;
  final ValueNotifier<double> progressNotifier;
  final ValueChanged<ReportPeriod> onPeriodChanged;
  final Future<void> Function(bool) onSelectCustomDate;
  final ValueChanged<bool> onEmployeeSpecificChanged;
  final ValueChanged<String> onEmployeeSearch;
  final ValueChanged<Employee> onEmployeeSelected;
  final VoidCallback onSearchClear;
  final VoidCallback onCreateReport;
  final VoidCallback onCreateFinancialReport;

  const PeriodReportTab({
    super.key,
    required this.selectedPeriodType,
    required this.customStartDate,
    required this.customEndDate,
    required this.isEmployeeSpecific,
    required this.selectedEmployee,
    required this.filteredEmployees,
    required this.employeeSearchController,
    required this.progressNotifier,
    required this.onPeriodChanged,
    required this.onSelectCustomDate,
    required this.onEmployeeSpecificChanged,
    required this.onEmployeeSearch,
    required this.onEmployeeSelected,
    required this.onSearchClear,
    required this.onCreateReport,
    required this.onCreateFinancialReport,
  });

  @override
  Widget build(BuildContext context) {
    const padding = 24.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PeriodSelectionCard(
            selectedPeriodType: selectedPeriodType,
            customStartDate: customStartDate,
            customEndDate: customEndDate,
            onPeriodChanged: onPeriodChanged,
            onSelectCustomDate: onSelectCustomDate,
          ),
          const SizedBox(height: 16),
          EmployeeSelectionCard(
            isEmployeeSpecific: isEmployeeSpecific,
            selectedEmployee: selectedEmployee,
            filteredEmployees: filteredEmployees,
            employeeSearchController: employeeSearchController,
            onEmployeeSpecificChanged: onEmployeeSpecificChanged,
            onEmployeeSearch: onEmployeeSearch,
            onEmployeeSelected: onEmployeeSelected,
            onSearchClear: onSearchClear,
          ),
          const SizedBox(height: 24),
          ReportLoadingIndicator(progressNotifier: progressNotifier),
          _buildCreateReportButton(context),
          const SizedBox(height: 12),
          _buildFinancialReportButton(context),
        ],
      ),
    );
  }

  Widget _buildCreateReportButton(BuildContext context) {
    return FilledButton.icon(
      icon: const Icon(Icons.picture_as_pdf, size: 20),
      label: const Text('Rapor Oluştur'),
      onPressed: isEmployeeSpecific && selectedEmployee == null
          ? null
          : onCreateReport,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFinancialReportButton(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.analytics_outlined, size: 20),
      label: const Text('Finansal Özet Raporu'),
      onPressed: isEmployeeSpecific ? null : onCreateFinancialReport,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
