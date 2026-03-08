/// Ödeme servisi için sabit değerler
class PaymentConstants {
  PaymentConstants._();

  static const String paymentsTable = 'payments';
  static const String paidDaysTable = 'paid_days';
  static const String attendanceTable = 'attendance';
  static const String advancesTable = 'advances';
  static const String notificationsTable = 'notifications';
  static const String workersTable = 'workers';

  static const String userIdColumn = 'user_id';
  static const String workerIdColumn = 'worker_id';
  static const String paymentIdColumn = 'payment_id';
  static const String dateColumn = 'date';
  static const String statusColumn = 'status';
  static const String paymentDateColumn = 'payment_date';
  static const String advanceDateColumn = 'advance_date';

  static const String statusFullDay = 'fullDay';
  static const String statusHalfDay = 'halfDay';

  static const String rpcUpdatePayment = 'update_payment';
  static const String rpcDeletePayment = 'delete_payment';
  static const String rpcGetPaymentSummary = 'get_payment_summary';

  static const String notificationTypePaymentReceived = 'payment_received';
  static const String notificationTitlePaymentMade = 'Ödeme Yapıldı';
  static const String senderTypeUser = 'user';
  static const String recipientTypeWorker = 'worker';
}
