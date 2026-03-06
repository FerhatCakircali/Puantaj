import 'package:flutter/material.dart';
import '../../../../models/notification_settings.dart';
import '../../../../models/employee_reminder.dart';
import '../../../../models/worker.dart';
import '../../../../services/notification_service.dart' as old_ns;
import '../../services/employee_reminder_service.dart';
import '../../../../services/worker_service.dart';
import '../../../../services/auth_service.dart';

/// Notification Settings ekranı için state management mixin'i
/// Bu mixin, NotificationSettingsScreen'in tüm state değişkenlerini
/// ve controller'larını yönetir.
mixin NotificationStateMixin<T extends StatefulWidget>
    on State<T>, SingleTickerProviderStateMixin<T> {
  // Services
  final old_ns.NotificationService notificationService =
      old_ns.NotificationService();
  final old_ns.NotificationService notificationServiceV2 =
      old_ns.NotificationService();
  final EmployeeReminderService reminderService = EmployeeReminderService();
  final WorkerService workerService = WorkerService();
  final AuthService authService = AuthService();

  // Controllers
  late TabController tabController;
  final TextEditingController searchController = TextEditingController();

  // Loading states
  bool isLoading = true;
  bool isLoadingWorkers = false;
  bool isLoadingReminders = false;

  // Settings states
  bool isEnabled = false;
  bool autoApproveTrusted = false;
  bool attendanceRequestsEnabled = true;
  String selectedTime = '18:00';
  NotificationSettings? settings;

  // Workers and reminders
  List<Worker> workers = [];
  List<Worker> filteredWorkers = [];
  List<EmployeeReminder> reminders = [];
  List<EmployeeReminder> filteredReminders = [];
  final Set<int> pendingDeleteReminderIds = <int>{};

  // Request tracking
  int remindersLoadRequestId = 0;

  // Permission state
  bool hasNotificationPermission = false;

  /// Initialize state mixin
  void initializeNotificationState() {
    tabController = TabController(length: 2, vsync: this);
  }

  /// Dispose state mixin
  void disposeNotificationState() {
    tabController.dispose();
    searchController.dispose();
  }

  /// Show snackbar message
  void showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
