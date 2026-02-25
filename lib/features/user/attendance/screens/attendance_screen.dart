import 'package:flutter/material.dart';
import '../../../../models/attendance.dart' as attendance;
import '../widgets/screen_widgets/index.dart';
import '../widgets/index.dart';
import '../mixins/attendance_logic_mixin.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with AttendanceLogicMixin {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final selectedDateNorm = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final isToday = selectedDateNorm.isAtSameMomentAs(todayDate);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  AttendanceCalendar(
                    selectedDate: selectedDate,
                    onCalendarTap: selectDate,
                    onDateSelected: onDateSelected,
                  ),
                  AttendanceStatsBar(
                    filteredEmployees: filteredEmployees,
                    pendingChanges: pendingChanges,
                    attendanceMap: attendanceMap,
                    isToday: isToday,
                    onSave: saveChanges,
                    onSendReminders: sendReminders,
                  ),
                  if (employees.isEmpty)
                    const Expanded(child: AttendanceEmptyState())
                  else
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            _buildSearchBar(context),
                            const SizedBox(height: 16),
                            Expanded(child: _buildEmployeeList(context)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextField(
      controller: searchController,
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
        suffixIcon: searchController.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.7)
                      : Colors.grey.shade700,
                ),
                onPressed: () {
                  searchController.clear();
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

  Widget _buildEmployeeList(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: filteredEmployees.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final employee = filteredEmployees[index];
        final status =
            pendingChanges[employee.id] ??
            attendanceMap[employee.id]?.status ??
            attendance.AttendanceStatus.absent;

        return AttendanceEmployeeCard(
          employee: employee,
          status: status,
          onStatusChange: (newStatus) => changeStatus(employee.id, newStatus),
        );
      },
    );
  }
}
