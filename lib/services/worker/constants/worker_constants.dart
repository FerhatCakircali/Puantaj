/// Çalışan servisi için sabit değerler
class WorkerConstants {
  WorkerConstants._();

  static const String tableName = 'workers';
  static const String attendanceTable = 'attendance';
  static const String paymentsTable = 'payments';
  static const String paidDaysTable = 'paid_days';

  static const String userIdColumn = 'user_id';
  static const String workerIdColumn = 'worker_id';
  static const String fullNameColumn = 'full_name';
  static const String dateColumn = 'date';
  static const String paymentIdColumn = 'payment_id';
  static const String statusColumn = 'status';

  static const String statusFullDay = 'fullDay';
  static const String statusHalfDay = 'halfDay';

  static const String rpcGetWorkersWithUnpaidDays =
      'get_workers_with_unpaid_days';
}
