import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../mixins/index.dart';

/// Geçmiş ekranı - 3 tab (Yevmiye / Ödeme / Avans)
class WorkerAttendanceScreen extends StatefulWidget {
  final int? initialTab;

  const WorkerAttendanceScreen({super.key, this.initialTab});

  @override
  State<WorkerAttendanceScreen> createState() => _WorkerAttendanceScreenState();
}

class _WorkerAttendanceScreenState extends State<WorkerAttendanceScreen>
    with SingleTickerProviderStateMixin, WorkerAttendanceLogicMixin {
  @override
  void initState() {
    super.initState();
    initializeTab(widget.initialTab);
  }

  @override
  void dispose() {
    cleanupTab();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const primaryColor = Color(0xFF4338CA);

    if (!isInitialized) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    return Column(
      children: [
        // Modern Tab Bar
        Container(
          margin: EdgeInsets.symmetric(
            horizontal: w * 0.06,
            vertical: h * 0.015,
          ),
          padding: EdgeInsets.all(w * 0.01),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TabBar(
            controller: tabController,
            indicator: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Colors.white,
            unselectedLabelColor: theme.colorScheme.onSurface.withValues(
              alpha: 0.6,
            ),
            labelStyle: TextStyle(
              fontSize: w * 0.04,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: w * 0.035,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            labelPadding: EdgeInsets.symmetric(horizontal: w * 0.04),
            tabs: const [
              Tab(text: 'Yevmiye Geçmişi'),
              Tab(text: 'Ödeme Geçmişi'),
              Tab(text: 'Avans Geçmişi'),
            ],
          ),
        ),
        // Modern Date Range Picker
        Padding(
          padding: EdgeInsets.symmetric(horizontal: w * 0.06),
          child: InkWell(
            onTap: () => selectDateRange(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.04,
                vertical: h * 0.016,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? theme.colorScheme.outline.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(w * 0.02),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calendar_today,
                      size: w * 0.045,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(width: w * 0.03),
                  Expanded(
                    child: Text(
                      '${DateFormat('dd.MM.yyyy').format(startDate)} - ${DateFormat('dd.MM.yyyy').format(endDate)}',
                      style: TextStyle(
                        fontSize: w * 0.038,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_month,
                    color: primaryColor,
                    size: w * 0.055,
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: h * 0.015),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              WorkerAttendanceTab(
                isLoading: isLoading,
                attendanceHistory: attendanceHistory,
                onRefresh: loadData,
              ),
              WorkerPaymentTab(
                isLoading: isLoading,
                paymentHistory: paymentHistory,
                onRefresh: loadData,
              ),
              WorkerAdvanceTab(
                isLoading: isLoading,
                advanceHistory: advanceHistory,
                onRefresh: loadData,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
