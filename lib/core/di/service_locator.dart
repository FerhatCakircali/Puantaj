import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/payment_service.dart';
import '../../services/payment/repositories/payment_repository.dart';
import '../../services/payment/repositories/paid_days_repository.dart';
import '../../services/payment/helpers/payment_calculator.dart';
import '../../services/payment/helpers/payment_sync_helper.dart';
import '../../services/payment/helpers/payment_user_helper.dart';
import '../../services/payment/validators/payment_validator.dart';
import '../../services/employee_service.dart';
import '../../services/employee/repositories/employee_repository.dart';
import '../../services/employee/helpers/employee_cleanup_helper.dart';
import '../../services/employee/helpers/employee_user_helper.dart';
import '../../services/employee/validators/employee_validator.dart';
import '../../services/shared/base_user_helper.dart';
import '../../services/advance/repositories/advance_repository.dart';
import '../../services/expense/repositories/expense_repository.dart';
import '../../services/attendance/repositories/attendance_repository.dart';
import '../../services/expense_service.dart';
import '../../services/advance_service.dart';
import '../../services/attendance_service.dart';
import '../../services/notification_service.dart';
import '../../services/worker/worker_service.dart';
import '../../services/worker/validators/worker_validator.dart';
import '../../services/worker/repositories/worker_repository.dart';
import '../../services/worker/repositories/employee_repository.dart'
    as worker_employee;
import '../../services/worker/helpers/worker_cache_helper.dart';
import '../../services/worker/helpers/worker_sync_helper.dart';
import '../../services/worker/helpers/worker_payment_helper.dart';
import '../../services/report/report_service.dart';
import '../../services/email_service.dart';
import '../../services/validation_service.dart';
import '../../services/cache_manager_service.dart';
import '../../services/database_cleanup_service.dart';
import '../../services/fcm_service.dart';
import '../../data/local/hive_service.dart';
import '../../data/local/sync_manager.dart';
import '../../data/services/local_storage_service.dart';
import '../../features/worker/services/worker_attendance_service.dart';
import '../../features/worker/services/worker_notification_service.dart';
import '../../features/user/services/employee_reminder_service.dart';
import '../../services/report/aggregators/period_summary_aggregator.dart';
import '../../services/report/calculators/attendance_summary_calculator.dart';

/// Dependency Injection container
///
/// GetIt kullanarak tüm servisleri merkezi bir yerden yönetir.
/// Singleton pattern ile tek instance garantisi sağlar.
final getIt = GetIt.instance;

/// Dependency Injection container'ını başlatır
///
/// Tüm servisleri ve bağımlılıklarını kaydeder.
/// Uygulama başlangıcında main.dart'tan çağrılmalıdır.
Future<void> setupServiceLocator() async {
  // Core dependencies
  getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  getIt.registerLazySingleton<HiveService>(() => HiveService.instance);

  getIt.registerLazySingleton<LocalStorageService>(
    () => LocalStorageService.instance,
  );

  // Auth service (diğer servislerin bağımlılığı)
  getIt.registerLazySingleton<AuthService>(() => AuthService());

  // Sync manager
  getIt.registerLazySingleton<SyncManager>(() => SyncManager.instance);

  // Payment modülü - DI ile bağımlılıklar
  getIt.registerLazySingleton<PaymentRepository>(
    () => PaymentRepository(getIt<SupabaseClient>()),
  );

  getIt.registerLazySingleton<PaidDaysRepository>(
    () => PaidDaysRepository(getIt<SupabaseClient>()),
  );

  getIt.registerLazySingleton<PaymentCalculator>(() => PaymentCalculator());

  getIt.registerLazySingleton<PaymentSyncHelper>(() => PaymentSyncHelper());

  getIt.registerLazySingleton<PaymentUserHelper>(
    () => PaymentUserHelper(getIt<AuthService>()),
  );

  getIt.registerLazySingleton<PaymentValidator>(() => PaymentValidator());

  getIt.registerLazySingleton<PaymentService>(
    () => PaymentService(
      authService: getIt<AuthService>(),
      repository: getIt<PaymentRepository>(),
      paidDaysRepository: getIt<PaidDaysRepository>(),
      calculator: getIt<PaymentCalculator>(),
      syncHelper: getIt<PaymentSyncHelper>(),
      userHelper: getIt<PaymentUserHelper>(),
      validator: getIt<PaymentValidator>(),
    ),
  );

  // Employee modülü - DI ile bağımlılıklar
  getIt.registerLazySingleton<EmployeeRepository>(
    () => EmployeeRepository(getIt<SupabaseClient>()),
  );

  getIt.registerLazySingleton<EmployeeCleanupHelper>(
    () => EmployeeCleanupHelper(),
  );

  getIt.registerLazySingleton<EmployeeUserHelper>(
    () => EmployeeUserHelper(getIt<AuthService>()),
  );

  getIt.registerLazySingleton<EmployeeValidator>(
    () => EmployeeValidator(getIt<SupabaseClient>()),
  );

  getIt.registerLazySingleton<EmployeeService>(
    () => EmployeeService(
      authService: getIt<AuthService>(),
      repository: getIt<EmployeeRepository>(),
      cleanupHelper: getIt<EmployeeCleanupHelper>(),
      userHelper: getIt<EmployeeUserHelper>(),
      validator: getIt<EmployeeValidator>(),
    ),
  );

  // Shared helper - tüm servisler için ortak
  getIt.registerLazySingleton<BaseUserHelper>(
    () => BaseUserHelper(getIt<AuthService>()),
  );

  // Advance modülü - DI ile bağımlılıklar
  getIt.registerLazySingleton<AdvanceRepository>(() => AdvanceRepository());

  getIt.registerLazySingleton<AdvanceService>(
    () => AdvanceService(
      authService: getIt<AuthService>(),
      repository: getIt<AdvanceRepository>(),
      userHelper: getIt<BaseUserHelper>(),
    ),
  );

  // Expense modülü - DI ile bağımlılıklar
  getIt.registerLazySingleton<ExpenseRepository>(() => ExpenseRepository());

  getIt.registerLazySingleton<ExpenseService>(
    () => ExpenseService(
      authService: getIt<AuthService>(),
      repository: getIt<ExpenseRepository>(),
      userHelper: getIt<BaseUserHelper>(),
    ),
  );

  // Attendance modülü - DI ile bağımlılıklar
  getIt.registerLazySingleton<AttendanceRepository>(
    () => AttendanceRepository(getIt<SupabaseClient>()),
  );

  getIt.registerLazySingleton<AttendanceService>(
    () => AttendanceService(
      authService: getIt<AuthService>(),
      repository: getIt<AttendanceRepository>(),
      userHelper: getIt<BaseUserHelper>(),
    ),
  );

  // Worker modülü - DI ile bağımlılıklar
  // ValidationService önce kaydedilmeli (WorkerValidator bağımlılığı)
  getIt.registerLazySingleton<ValidationService>(
    () => ValidationService(supabase: getIt<SupabaseClient>()),
  );

  getIt.registerLazySingleton<WorkerValidator>(
    () => WorkerValidator(validationService: getIt<ValidationService>()),
  );

  getIt.registerLazySingleton<WorkerRepository>(
    () => WorkerRepository(getIt<SupabaseClient>()),
  );

  getIt.registerLazySingleton<worker_employee.EmployeeRepository>(
    () => worker_employee.EmployeeRepository(getIt<SupabaseClient>()),
  );

  getIt.registerLazySingleton<WorkerCacheHelper>(() => WorkerCacheHelper());

  getIt.registerLazySingleton<WorkerSyncHelper>(() => WorkerSyncHelper());

  getIt.registerLazySingleton<WorkerPaymentHelper>(() => WorkerPaymentHelper());

  getIt.registerLazySingleton<WorkerService>(
    () => WorkerService(
      authService: getIt<AuthService>(),
      validator: getIt<WorkerValidator>(),
      repository: getIt<WorkerRepository>(),
      employeeRepository: getIt<worker_employee.EmployeeRepository>(),
      cacheHelper: getIt<WorkerCacheHelper>(),
      syncHelper: getIt<WorkerSyncHelper>(),
      paymentHelper: getIt<WorkerPaymentHelper>(),
      syncManager: getIt<SyncManager>(),
    ),
  );

  // Notification service - Singleton pattern korundu (mixin yapısı nedeniyle)
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());

  // Report service - DI ile refaktör edildi
  getIt.registerLazySingleton<ReportService>(() => ReportService());

  // Utility services - DI ile refaktör edildi
  getIt.registerLazySingleton<EmailService>(() => EmailService());

  getIt.registerLazySingleton<CacheManagerService>(() => CacheManagerService());

  getIt.registerLazySingleton<DatabaseCleanupService>(
    () => DatabaseCleanupService(supabase: getIt<SupabaseClient>()),
  );

  getIt.registerLazySingleton<FCMService>(() => FCMService.instance);

  // Worker feature services
  getIt.registerLazySingleton<WorkerAttendanceService>(
    () => WorkerAttendanceService(),
  );

  getIt.registerLazySingleton<WorkerNotificationService>(
    () => WorkerNotificationService(),
  );

  // User feature services
  getIt.registerLazySingleton<EmployeeReminderService>(
    () => EmployeeReminderService(),
  );

  // Report aggregators and calculators
  getIt.registerLazySingleton<PeriodSummaryAggregator>(
    () => PeriodSummaryAggregator(),
  );

  getIt.registerLazySingleton<AttendanceSummaryCalculator>(
    () => AttendanceSummaryCalculator(),
  );
}
