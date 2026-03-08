import 'package:flutter/material.dart';
import '../mixins/report_controller_mixin.dart';
import '../mixins/report_controller/report_controller_data_mixin.dart';
import '../mixins/report_controller/report_controller_date_mixin.dart';
import '../pdf/mixins/report_pdf_mixin.dart';
import '../widgets/employee_details_dialog.dart';
import 'widgets/report_tab_bar.dart';
import 'widgets/employee_report_tab.dart';
import 'widgets/period_report_tab.dart';

/// Rapor ekranı
///
/// Çalışan raporları ve dönemsel raporları yönetir.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with
        SingleTickerProviderStateMixin,
        WidgetsBindingObserver,
        ReportControllerMixin,
        ReportControllerDataMixin,
        ReportControllerDateMixin,
        ReportPdfMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _employeeSearchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    _searchController.dispose();
    _employeeSearchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _showEmployeeDetails(dynamic employee) {
    showDialog(
      context: context,
      builder: (context) => EmployeeDetailsDialog(
        employee: employee,
        onPaymentComplete: loadData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ReportTabBar(controller: _tabController),
            Expanded(
              child: isLoading
                  ? _buildLoadingState(colorScheme)
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildEmployeeReportTab(),
                        _buildPeriodReportTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(strokeWidth: 3),
          const SizedBox(height: 16),
          ValueListenableBuilder<double>(
            valueListenable: progressNotifier,
            builder: (context, progress, child) {
              if (progress > 0 && progress < 1) {
                return Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeReportTab() {
    return EmployeeReportTab(
      startDate: startDate,
      endDate: endDate,
      filteredEmployees: filteredEmployees,
      statsMap: statsMap,
      searchController: _searchController,
      onDateRangeSelect: () => selectDateRange(context),
      onSearch: filterEmployees,
      onSearchClear: () {
        _searchController.clear();
        filterEmployees('');
      },
      onEmployeeTap: _showEmployeeDetails,
    );
  }

  Widget _buildPeriodReportTab() {
    return PeriodReportTab(
      selectedPeriodType: selectedPeriodType,
      customStartDate: customStartDate,
      customEndDate: customEndDate,
      isEmployeeSpecific: isEmployeeSpecific,
      selectedEmployee: selectedEmployee,
      filteredEmployees: filteredEmployees,
      employeeSearchController: _employeeSearchController,
      progressNotifier: progressNotifier,
      onPeriodChanged: (value) {
        setState(() => selectedPeriodType = value);
        updatePeriodDates(value);
      },
      onSelectCustomDate: selectCustomDate,
      onEmployeeSpecificChanged: (value) {
        setState(() {
          isEmployeeSpecific = value;
          if (!isEmployeeSpecific) selectedEmployee = null;
        });
      },
      onEmployeeSearch: filterEmployees,
      onEmployeeSelected: (employee) {
        setState(() => selectedEmployee = employee);
      },
      onSearchClear: () {
        _employeeSearchController.clear();
        filterEmployees('');
      },
      onCreateReport: () => createPeriodReport(context),
      onCreateFinancialReport: () => createFinancialSummaryReport(context),
    );
  }
}
