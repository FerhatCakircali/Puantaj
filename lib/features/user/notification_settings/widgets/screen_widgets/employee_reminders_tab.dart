import 'package:flutter/material.dart';
import '../../../../../models/worker.dart';
import '../../../../../models/employee_reminder.dart';
import '../../../../../screens/constants/colors.dart';
import 'reminder_list_view.dart';
import 'worker_list_view.dart';

class EmployeeRemindersTab extends StatefulWidget {
  final TextEditingController searchController;
  final List<Worker> filteredWorkers;
  final List<EmployeeReminder> reminders;
  final bool isLoadingWorkers;
  final bool isLoadingReminders;
  final Function(String query) onSearchChanged;
  final VoidCallback onSearchClear;
  final Function(Worker worker) onWorkerTap;
  final VoidCallback onRefreshReminders;
  final Function(int index, EmployeeReminder reminder) onDeleteReminder;
  final VoidCallback onAddNewReminder;

  const EmployeeRemindersTab({
    super.key,
    required this.searchController,
    required this.filteredWorkers,
    required this.reminders,
    required this.isLoadingWorkers,
    required this.isLoadingReminders,
    required this.onSearchChanged,
    required this.onSearchClear,
    required this.onWorkerTap,
    required this.onRefreshReminders,
    required this.onDeleteReminder,
    required this.onAddNewReminder,
  });

  @override
  State<EmployeeRemindersTab> createState() => _EmployeeRemindersTabState();
}

class _EmployeeRemindersTabState extends State<EmployeeRemindersTab>
    with SingleTickerProviderStateMixin {
  late TabController _innerTabController;

  @override
  void initState() {
    super.initState();
    _innerTabController = TabController(length: 2, vsync: this);

    // Listen to tab changes to clear search when switching tabs
    _innerTabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_innerTabController.indexIsChanging) {
      widget.searchController.clear();
      widget.onSearchClear();
    }
  }

  @override
  void dispose() {
        _innerTabController.removeListener(_onTabChanged);
    _innerTabController.dispose();
    super.dispose();
  }

  void _switchToWorkersTab() {
    _innerTabController.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;
    final padding = isTablet ? 24.0 : 16.0;

    return Column(
      children: [
        // Modern Search Bar
        Padding(
          padding: EdgeInsets.all(padding),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.searchController,
            builder: (context, value, child) {
              return TextField(
                controller: widget.searchController,
                decoration: InputDecoration(
                  hintText: 'Çalışan ara...',
                  prefixIcon: const Icon(Icons.search, color: primaryIndigo),
                  suffixIcon: value.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            widget.searchController.clear();
                            widget.onSearchClear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.shade200,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.grey.shade200,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(
                      color: primaryIndigo,
                      width: 2,
                    ),
                  ),
                ),
                onChanged: widget.onSearchChanged,
              );
            },
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(horizontal: padding),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: TabBar(
                  controller: _innerTabController,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.notifications_active, size: 20),
                      text: 'Hatırlatıcılar',
                    ),
                    Tab(icon: Icon(Icons.people, size: 20), text: 'Çalışanlar'),
                  ],
                  labelColor: Colors.white,
                  unselectedLabelColor: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.grey.shade700,
                  indicator: BoxDecoration(
                    color: primaryIndigo,
                    borderRadius: BorderRadius.circular(4),
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
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  controller: _innerTabController,
                  children: [
                    ReminderListView(
                      reminders: widget.reminders,
                      isLoading: widget.isLoadingReminders,
                      onRefresh: widget.onRefreshReminders,
                      onDelete: widget.onDeleteReminder,
                      onAddNew: _switchToWorkersTab,
                    ),
                    WorkerListView(
                      workers: widget.filteredWorkers,
                      isLoading: widget.isLoadingWorkers,
                      onWorkerTap: widget.onWorkerTap,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
