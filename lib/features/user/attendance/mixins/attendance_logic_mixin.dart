import 'package:flutter/material.dart';
import '../../../../models/attendance.dart' as attendance;
import '../../../../models/employee.dart';
import '../data/attendance_data_loader.dart';
import '../filters/employee_filter.dart';
import '../handlers/attendance_save_handler.dart';
import '../handlers/attendance_reminder_handler.dart';
import '../handlers/attendance_bulk_operations.dart';
import '../widgets/attendance_notification_handler.dart';

/// Yevmiye ekranı business logic mixin'i
///
/// Yoklama işlemlerini koordine eder
mixin AttendanceLogicMixin<T extends StatefulWidget> on State<T> {
  final AttendanceDataLoader _dataLoader = AttendanceDataLoader();
  final AttendanceSaveHandler _saveHandler = AttendanceSaveHandler();
  final AttendanceReminderHandler _reminderHandler =
      AttendanceReminderHandler();
  final AttendanceBulkOperations _bulkOperations = AttendanceBulkOperations();

  DateTime selectedDate = DateTime.now();
  List<Employee> employees = [];
  List<Employee> filteredEmployees = [];
  Map<int, attendance.Attendance> attendanceMap = {};
  final Map<int, attendance.AttendanceStatus> pendingChanges = {};
  bool isLoading = true;
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
    AttendanceNotificationHandler.checkAndClearAttendanceNotification();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  /// Verileri yükler
  Future<void> loadData() async {
    setState(() => isLoading = true);
    try {
      final data = await _dataLoader.loadData(selectedDate);

      if (mounted) {
        setState(() {
          employees = data.employees;
          filteredEmployees = data.filteredEmployees;
          attendanceMap = data.attendanceMap;
          pendingChanges.clear();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  /// Çalışanları filtreler
  void filterEmployees(String query) {
    setState(() {
      filteredEmployees = EmployeeFilter.filter(employees, query);
    });
  }

  /// Tarih seçici gösterir
  Future<void> selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        selectedDate = pickedDate;
        isLoading = true;
        pendingChanges.clear();
        searchController.clear();
      });
      await loadData();
    }
  }

  /// Tarih seçildiğinde çağrılır
  void onDateSelected(DateTime day) {
    setState(() {
      selectedDate = day;
      isLoading = true;
      pendingChanges.clear();
      searchController.clear();
    });
    loadData();
  }

  /// Değişiklikleri kaydeder
  Future<void> saveChanges() async {
    if (!mounted) return;

    final result = await _saveHandler.saveChanges(
      context: context,
      selectedDate: selectedDate,
      filteredEmployees: filteredEmployees,
      attendanceMap: attendanceMap,
      pendingChanges: pendingChanges,
      allEmployees: employees,
    );

    if (!mounted) return;

    if (result.isCancelled || result.hasNoChanges) {
      return;
    }

    if (result.isSuccess) {
      await loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.getSuccessMessage()),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yevmiye kaydetme hatası: ${result.errorMessage}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Yevmiye yapmamış çalışanlara hatırlatma gönderir
  Future<void> sendReminders() async {
    if (!mounted) return;

    final result = await _reminderHandler.sendReminders(
      context: context,
      selectedDate: selectedDate,
      employees: employees,
      pendingChanges: pendingChanges,
      attendanceMap: attendanceMap,
    );

    if (!mounted) return;

    if (result.message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message!),
          backgroundColor: result.backgroundColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Tek bir çalışanın durumunu değiştirir
  Future<void> changeStatus(
    int workerId,
    attendance.AttendanceStatus value,
  ) async {
    if (!mounted) return;

    final result = await _bulkOperations.changeStatus(
      context: context,
      workerId: workerId,
      selectedDate: selectedDate,
      employees: employees,
      pendingChanges: pendingChanges,
      attendanceMap: attendanceMap,
      value: value,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() {});
      await _updateTodayNotificationIfNeeded();
    } else if (result.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.errorMessage!,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: result.backgroundColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Tüm çalışanların durumunu toplu olarak değiştirir
  Future<void> bulkChangeStatus(attendance.AttendanceStatus status) async {
    if (!mounted) return;

    final result = await _bulkOperations.bulkChangeStatus(
      context: context,
      selectedDate: selectedDate,
      filteredEmployees: filteredEmployees,
      pendingChanges: pendingChanges,
      attendanceMap: attendanceMap,
      status: status,
    );

    setState(() {});

    if (!mounted) return;

    if (result.hasPaidEmployees) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.getPaidEmployeesMessage(),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    }

    if (result.hasNotStartedEmployees) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.getNotStartedEmployeesMessage(),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    if (result.hasChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.getSuccessMessage()),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Bugünün yevmiyesi değiştiyse bildirim durumunu günceller
  Future<void> _updateTodayNotificationIfNeeded() async {
    final today = DateTime.now();
    final selectedToday = DateTime(today.year, today.month, today.day);
    final selectedDateNorm = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    if (selectedDateNorm.isAtSameMomentAs(selectedToday)) {
      debugPrint(
        'Bugünün yevmiye durumu değiştirildi, bildirim durumunu güncelliyorum',
      );

      try {
        await AttendanceNotificationHandler.markTodayAttendanceDone();
        debugPrint('Bildirim durumu başarıyla güncellendi');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Bugünün yevmiye girişi yapıldı olarak işaretlendi',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        debugPrint('Bildirim durumu güncellenirken hata: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bildirim durumu güncellenirken hata: $e'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
}
