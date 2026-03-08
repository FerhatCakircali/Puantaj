/// Dashboard için sabit değerler
class DashboardConstants {
  static const String attendanceTable = 'attendance';
  static const String attendanceRequestsTable = 'attendance_requests';
  static const String paymentsTable = 'payments';
  static const String notificationsTable = 'notifications';
  static const String employeeRemindersTable = 'employee_reminders';

  static const String statusFullDay = 'fullDay';
  static const String statusHalfDay = 'halfDay';
  static const String statusAbsent = 'absent';

  static const String requestStatusPending = 'pending';
  static const String requestStatusApproved = 'approved';

  static const String recipientTypeWorker = 'worker';

  static const int recentPaymentsLimit = 3;
  static const int upcomingRemindersLimit = 5;
  static const int monthlyTrendMonths = 3;

  static const List<String> monthNames = [
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara',
  ];
}
