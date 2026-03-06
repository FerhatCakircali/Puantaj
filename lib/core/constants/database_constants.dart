/// Veritabanı tablo ve alan isimleri
/// Single Responsibility: Sadece veritabanı sabitlerini tutar
/// Bu sayede tablo/alan isimleri değiştiğinde tek yerden güncellenir
class DatabaseConstants {
  // Private constructor - utility class
  DatabaseConstants._();

  // ==================== TABLO İSİMLERİ ====================

  static const String workersTable = 'workers';
  static const String usersTable = 'users';
  static const String attendanceTable = 'attendance';
  static const String attendanceRequestsTable = 'attendance_requests';
  static const String notificationsTable = 'notifications';
  static const String notificationSettingsTable = 'notification_settings';
  static const String paymentsTable = 'payments';

  // ==================== WORKERS ALANLARI ====================

  static const String workerId = 'id';
  static const String workerUserId = 'user_id';
  static const String workerUsername = 'username';
  static const String workerPasswordHash = 'password_hash';
  static const String workerFullName = 'full_name';
  static const String workerTitle = 'title';
  static const String workerPhone = 'phone';
  static const String workerStartDate = 'start_date';
  static const String workerIsActive = 'is_active';
  static const String workerIsTrusted = 'is_trusted';
  static const String workerLastLogin = 'last_login';
  static const String workerCreatedAt = 'created_at';
  static const String workerUpdatedAt = 'updated_at';

  // ==================== USERS ALANLARI ====================

  static const String userId = 'id';
  static const String userPasswordHash = 'password_hash';
  static const String userName = 'name';
  static const String userRole = 'role';
  static const String userIsBlocked = 'is_blocked';
  static const String userCreatedAt = 'created_at';
  static const String userUpdatedAt = 'updated_at';

  // ==================== ATTENDANCE ALANLARI ====================

  static const String attendanceId = 'id';
  static const String attendanceWorkerId = 'worker_id';
  static const String attendanceUserId = 'user_id';
  static const String attendanceDate = 'date';
  static const String attendanceStatus = 'status';
  static const String attendanceCreatedBy = 'created_by';
  static const String attendanceCreatedAt = 'created_at';

  // ==================== ATTENDANCE_REQUESTS ALANLARI ====================

  static const String requestId = 'id';
  static const String requestWorkerId = 'worker_id';
  static const String requestUserId = 'user_id';
  static const String requestDate = 'date';
  static const String requestStatus = 'status';
  static const String requestRequestStatus = 'request_status';
  static const String requestRequestedAt = 'requested_at';
  static const String requestReviewedAt = 'reviewed_at';
  static const String requestReviewedBy = 'reviewed_by';
  static const String requestRejectionReason = 'rejection_reason';

  // ==================== NOTIFICATIONS ALANLARI ====================

  static const String notificationId = 'id';
  static const String notificationSenderId = 'sender_id';
  static const String notificationSenderType = 'sender_type';
  static const String notificationRecipientId = 'recipient_id';
  static const String notificationRecipientType = 'recipient_type';
  static const String notificationType = 'notification_type';
  static const String notificationTitle = 'title';
  static const String notificationMessage = 'message';
  static const String notificationIsRead = 'is_read';
  static const String notificationRelatedId = 'related_id';
  static const String notificationCreatedAt = 'created_at';

  // ==================== NOTIFICATION_SETTINGS ALANLARI ====================

  static const String settingsUserId = 'user_id';
  static const String settingsEnabled = 'enabled';
  static const String settingsTime = 'time';
  static const String settingsAutoApproveTrusted = 'auto_approve_trusted';
  static const String settingsLastUpdated = 'last_updated';

  // ==================== PAYMENTS ALANLARI ====================

  static const String paymentId = 'id';
  static const String paymentWorkerId = 'worker_id';
  static const String paymentUserId = 'user_id';
  static const String paymentAmount = 'amount';
  static const String paymentPaymentDate = 'payment_date';
  static const String paymentDescription = 'description';
  static const String paymentCreatedAt = 'created_at';

  // ==================== ENUM DEĞERLERİ ====================

  // Attendance Status
  static const String statusFullDay = 'fullDay';
  static const String statusHalfDay = 'halfDay';
  static const String statusAbsent = 'absent';

  // Request Status
  static const String requestStatusPending = 'pending';
  static const String requestStatusApproved = 'approved';
  static const String requestStatusRejected = 'rejected';

  // Status Type
  static const String statusTypeNone = 'none';
  static const String statusTypePending = 'pending';
  static const String statusTypeApproved = 'approved';
  static const String statusTypeRejected = 'rejected';
  static const String statusTypeManagerEntered = 'manager_entered';

  // Notification Type
  static const String notificationTypeAttendanceRequest = 'attendance_request';
  static const String notificationTypeAttendanceReminder =
      'attendance_reminder';
  static const String notificationTypeAttendanceApproved =
      'attendance_approved';
  static const String notificationTypeAttendanceRejected =
      'attendance_rejected';
  static const String notificationTypeGeneral = 'general';

  // Sender/Recipient Type
  static const String senderTypeUser = 'user';
  static const String senderTypeWorker = 'worker';
  static const String senderTypeSystem = 'system';

  // User Role
  static const String roleAdmin = 'admin';
  static const String roleUser = 'user';

  // ==================== RPC FONKSİYONLARI ====================

  static const String rpcCheckWorkerTodayStatus =
      'check_worker_today_attendance_status';
  static const String rpcSendAttendanceReminder =
      'send_attendance_reminder_to_workers';
  static const String rpcApproveRequest = 'approve_attendance_request';
  static const String rpcRejectRequest = 'reject_attendance_request';
  static const String rpcApproveAllPending = 'approve_all_pending_requests';
  static const String rpcGetMonthlyStats = 'get_worker_monthly_stats';
  static const String rpcGetTotalPayments = 'get_worker_total_payments';
  static const String rpcGetAttendanceHistory = 'get_worker_attendance_history';
  static const String rpcChangeWorkerPassword = 'change_worker_password';
  static const String rpcChangeUserPassword = 'change_user_password';
}
