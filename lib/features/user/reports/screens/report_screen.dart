import 'package:flutter/material.dart';
import '../mixins/report_controller_mixin.dart';
import '../mixins/report_controller/report_controller_data_mixin.dart';
import '../mixins/report_controller/report_controller_date_mixin.dart';
import '../mixins/report_controller/report_controller_pdf_mixin.dart';
import '../widgets/employee_details_dialog.dart';
import '../widgets/screen_widgets/index.dart';

/// Rapor ekranı
/// Çalışan raporları ve dönemsel raporları yönetir
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
        ReportControllerPdfMixin {
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

    // Uygulama ön plana geldiğinde state'i koru
    if (state == AppLifecycleState.resumed) {
      // State zaten var, sadece UI'ı güncelle
      if (mounted) {
        setState(() {
          // UI refresh için setState çağır ama veriyi yeniden yükleme
        });
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
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = 24.0;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Modern Tab Bar
            Container(
              margin: EdgeInsets.fromLTRB(padding, 16, padding, 0),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: colorScheme.onPrimary,
                unselectedLabelColor: colorScheme.onSurfaceVariant,
                indicator: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(icon: Icon(Icons.people, size: 20), text: 'Çalışan'),
                  Tab(
                    icon: Icon(Icons.calendar_month, size: 20),
                    text: 'Dönemsel',
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(strokeWidth: 3),
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
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildEmployeeReportTab(
                          padding,
                          colorScheme,
                          screenWidth,
                        ),
                        _buildPeriodReportTab(
                          padding,
                          colorScheme,
                          screenWidth,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeReportTab(
    double padding,
    ColorScheme colorScheme,
    double screenWidth,
  ) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DateRangeSelector(
            startDate: startDate,
            endDate: endDate,
            onTap: () => selectDateRange(context),
          ),
          const SizedBox(height: 16),
          ReportSearchBar(
            controller: _searchController,
            onChanged: filterEmployees,
            onClear: () {
              _searchController.clear();
              filterEmployees('');
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: filteredEmployees.isEmpty
                ? _buildEmptyState(colorScheme, screenWidth)
                : ListView.separated(
                    itemCount: filteredEmployees.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final emp = filteredEmployees[index];
                      final stats = statsMap[emp.id] ?? {};
                      return EmployeeReportCard(
                        employee: emp,
                        stats: stats,
                        onTap: () => _showEmployeeDetails(emp),
                        isTablet:
                            MediaQuery.of(context).size.shortestSide >= 600,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, double screenWidth) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      child: SizedBox(
        height: screenHeight * 0.5,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _searchController.text.isEmpty
                      ? Icons.inbox_outlined
                      : Icons.search_off,
                  size: 64,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _searchController.text.isEmpty
                    ? 'Bu tarih aralığında kayıt yok'
                    : 'Sonuç bulunamadı',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchController.text.isEmpty
                    ? 'Farklı bir tarih aralığı seçin'
                    : 'Arama kriterlerinizi değiştirin',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodReportTab(
    double padding,
    ColorScheme colorScheme,
    double screenWidth,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PeriodSelectionCard(
            selectedPeriodType: selectedPeriodType,
            customStartDate: customStartDate,
            customEndDate: customEndDate,
            onPeriodChanged: (value) {
              setState(() => selectedPeriodType = value);
              updatePeriodDates(value);
            },
            onSelectCustomDate: selectCustomDate,
          ),
          const SizedBox(height: 16),
          EmployeeSelectionCard(
            isEmployeeSpecific: isEmployeeSpecific,
            selectedEmployee: selectedEmployee,
            filteredEmployees: filteredEmployees,
            employeeSearchController: _employeeSearchController,
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
          ),
          const SizedBox(height: 24),

          // Loading göstergesi
          ValueListenableBuilder<double>(
            valueListenable: progressNotifier,
            builder: (context, progress, child) {
              if (progress > 0 && progress < 1) {
                return Column(
                  children: [
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'PDF oluşturuluyor... ${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),

          FilledButton.icon(
            icon: const Icon(Icons.picture_as_pdf, size: 20),
            label: const Text('Rapor Oluştur'),
            onPressed: isEmployeeSpecific && selectedEmployee == null
                ? null
                : () => createPeriodReport(context),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.analytics_outlined, size: 20),
            label: const Text('Finansal Özet Raporu'),
            onPressed: isEmployeeSpecific
                ? null
                : () => createFinancialSummaryReport(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
