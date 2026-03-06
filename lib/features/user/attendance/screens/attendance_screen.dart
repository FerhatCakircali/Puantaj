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
      resizeToAvoidBottomInset: false, // Klavye açıldığında ekranı küçültme
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
                            const SizedBox(height: 12),
                            _buildBulkActionButtons(context),
                            const SizedBox(height: 12),
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
          vertical: 10,
        ),
      ),
    );
  }

  Widget _buildBulkActionButtons(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Tüm çalışanların durumunu kontrol et
    bool allFullDay = true;
    bool allHalfDay = true;
    bool allAbsent = true;

    for (final employee in filteredEmployees) {
      final status =
          pendingChanges[employee.id] ?? attendanceMap[employee.id]?.status;
      if (status != attendance.AttendanceStatus.fullDay) allFullDay = false;
      if (status != attendance.AttendanceStatus.halfDay) allHalfDay = false;
      if (status != attendance.AttendanceStatus.absent) allAbsent = false;
    }

    return Row(
      children: [
        Expanded(
          child: _buildBulkButton(
            context,
            icon: Icons.check_circle,
            label: 'Tümü Tam Gün',
            color: const Color(0xFF4F5FBF),
            isDark: isDark,
            isActive: allFullDay,
            onTap: () => _showBulkActionDialog(
              context,
              'Tümü Tam Gün',
              'Tüm çalışanlar "Tam Gün" olarak işaretlenecek. Devam edilsin mi?',
              attendance.AttendanceStatus.fullDay,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildBulkButton(
            context,
            icon: Icons.schedule,
            label: 'Tümü Yarım Gün',
            color: const Color(0xFF8B9FE8),
            isDark: isDark,
            isActive: allHalfDay,
            onTap: () => _showBulkActionDialog(
              context,
              'Tümü Yarım Gün',
              'Tüm çalışanlar "Yarım Gün" olarak işaretlenecek. Devam edilsin mi?',
              attendance.AttendanceStatus.halfDay,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildBulkButton(
            context,
            icon: Icons.cancel,
            label: 'Tümü Gelmedi',
            color: const Color(0xFFE89595),
            isDark: isDark,
            isActive: allAbsent,
            onTap: () => _showBulkActionDialog(
              context,
              'Tümü Gelmedi',
              'Tüm çalışanlar "Gelmedi" olarak işaretlenecek. Devam edilsin mi?',
              attendance.AttendanceStatus.absent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulkButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isActive
          ? color.withValues(alpha: 0.25)
          : isDark
          ? color.withValues(alpha: 0.15)
          : color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      elevation: isActive ? 4 : 0,
      shadowColor: isActive ? color.withValues(alpha: 0.5) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isActive ? Border.all(color: color, width: 2) : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: isActive ? 28 : 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showBulkActionDialog(
    BuildContext context,
    String title,
    String message,
    attendance.AttendanceStatus status,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('⚠️ $title'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Devam Et'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await bulkChangeStatus(status);
    }
  }

  Widget _buildEmployeeList(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: filteredEmployees.length,
      // ⚡ PHASE 4: ListView optimizasyonları
      addAutomaticKeepAlives: false, // Memory optimizasyonu
      addRepaintBoundaries: true, // Repaint optimizasyonu
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final employee = filteredEmployees[index];
        final status =
            pendingChanges[employee.id] ?? attendanceMap[employee.id]?.status;

        return AttendanceEmployeeCard(
          employee: employee,
          status: status,
          onStatusChange: (newStatus) => changeStatus(employee.id, newStatus),
        );
      },
    );
  }
}
