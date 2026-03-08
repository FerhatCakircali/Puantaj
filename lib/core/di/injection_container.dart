import 'package:get_it/get_it.dart';
import '../../data/datasources/supabase_datasource.dart';
import '../../data/datasources/local_datasource.dart';
import '../../data/services/supabase_service.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/repositories/i_employee_repository.dart';
import '../../domain/repositories/i_attendance_repository.dart';
import '../../domain/repositories/i_payment_repository.dart';
import '../../domain/repositories/i_notification_repository.dart';
import '../../domain/repositories/i_worker_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/employee_repository_impl.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../data/repositories/worker_repository_impl.dart';
import '../../domain/services/i_storage_service.dart';
import '../../domain/services/i_theme_service.dart';
import '../../data/services/storage_service_impl.dart';
import '../../data/services/theme_service_impl.dart';
import '../../domain/usecases/auth/sign_in_usecase.dart';
import '../../domain/usecases/auth/sign_up_usecase.dart';
import '../../domain/usecases/auth/sign_out_usecase.dart';
import '../../domain/usecases/auth/get_current_user_usecase.dart';
import '../../domain/usecases/employee/get_employees_usecase.dart';
import '../../domain/usecases/employee/create_employee_usecase.dart';
import '../../domain/usecases/employee/update_employee_usecase.dart';
import '../../domain/usecases/employee/delete_employee_usecase.dart';
import '../../domain/usecases/attendance/get_attendance_usecase.dart';
import '../../domain/usecases/attendance/create_attendance_usecase.dart';
import '../../domain/usecases/attendance/update_attendance_usecase.dart';
import '../../domain/usecases/attendance/approve_attendance_usecase.dart';
import '../../domain/usecases/notification/get_notifications_usecase.dart';
import '../../domain/usecases/notification/mark_notification_read_usecase.dart';
import '../../presentation/controllers/auth/auth_controller.dart';
import '../../presentation/controllers/home/home_controller.dart';
import '../../presentation/controllers/employee/employee_controller.dart';
import '../../presentation/controllers/attendance/attendance_controller.dart';

/// Dependency Injection Container
/// Centralizes all dependency registrations and provides a single initialization point.
/// Uses GetIt as the service locator.
/// Usage:
/// ```dart
/// // Initialize at app startup
/// await InjectionContainer.instance.init();
/// // Retrieve dependencies
/// final authRepo = InjectionContainer.instance.get<IAuthRepository>();
/// ```
class InjectionContainer {
  InjectionContainer._();

  static final InjectionContainer _instance = InjectionContainer._();
  static InjectionContainer get instance => _instance;

  final GetIt _getIt = GetIt.instance;

  /// Initialize all dependencies
  /// Should be called once at app startup before any other operations.
  Future<void> init() async {
    // Register data sources
    _registerDataSources();

    // Register repositories
    _registerRepositories();

    // Register services
    _registerServices();

    // Register use cases
    _registerUseCases();

    // Register controllers
    _registerControllers();
  }

  /// Register data sources (Supabase, SharedPreferences, etc.)
  void _registerDataSources() {
    // Register SupabaseDataSource as singleton
    _getIt.registerLazySingleton<SupabaseDataSource>(
      () => SupabaseDataSourceImpl(SupabaseService.instance),
    );

    // Register LocalDataSource as singleton
    _getIt.registerLazySingleton<LocalDataSource>(() => LocalDataSourceImpl());
  }

  /// Register repository implementations
  void _registerRepositories() {
    // Register IAuthRepository → AuthRepositoryImpl as singleton
    _getIt.registerLazySingleton<IAuthRepository>(
      () => AuthRepositoryImpl(_getIt<SupabaseDataSource>()),
    );

    // Register IEmployeeRepository → EmployeeRepositoryImpl as singleton
    _getIt.registerLazySingleton<IEmployeeRepository>(
      () => EmployeeRepositoryImpl(_getIt<SupabaseDataSource>()),
    );

    // Register IAttendanceRepository → AttendanceRepositoryImpl as singleton
    _getIt.registerLazySingleton<IAttendanceRepository>(
      () => AttendanceRepositoryImpl(_getIt<SupabaseDataSource>()),
    );

    // Register IPaymentRepository → PaymentRepositoryImpl as singleton
    _getIt.registerLazySingleton<IPaymentRepository>(
      () => PaymentRepositoryImpl(_getIt<SupabaseDataSource>()),
    );

    // Register INotificationRepository → NotificationRepositoryImpl as singleton
    _getIt.registerLazySingleton<INotificationRepository>(
      () => NotificationRepositoryImpl(_getIt<SupabaseDataSource>()),
    );

    // Register IWorkerRepository → WorkerRepositoryImpl as singleton
    _getIt.registerLazySingleton<IWorkerRepository>(
      () => WorkerRepositoryImpl(_getIt<SupabaseDataSource>()),
    );
  }

  /// Register service implementations
  void _registerServices() {
    // Register IStorageService → StorageServiceImpl as singleton
    _getIt.registerLazySingleton<IStorageService>(() => StorageServiceImpl());

    // Register IThemeService → ThemeServiceImpl as singleton
    _getIt.registerLazySingleton<IThemeService>(
      () => ThemeServiceImpl(_getIt<IStorageService>()),
    );
  }

  /// Use case'leri kaydet
  void _registerUseCases() {
    // Auth use case'leri
    _getIt.registerFactory<SignInUseCase>(
      () => SignInUseCase(_getIt<IAuthRepository>()),
    );

    _getIt.registerFactory<SignUpUseCase>(
      () => SignUpUseCase(_getIt<IAuthRepository>()),
    );

    _getIt.registerFactory<SignOutUseCase>(
      () => SignOutUseCase(_getIt<IAuthRepository>()),
    );

    _getIt.registerFactory<GetCurrentUserUseCase>(
      () => GetCurrentUserUseCase(_getIt<IAuthRepository>()),
    );

    // Employee use case'leri
    _getIt.registerFactory<GetEmployeesUseCase>(
      () => GetEmployeesUseCase(_getIt<IEmployeeRepository>()),
    );

    _getIt.registerFactory<CreateEmployeeUseCase>(
      () => CreateEmployeeUseCase(_getIt<IEmployeeRepository>()),
    );

    _getIt.registerFactory<UpdateEmployeeUseCase>(
      () => UpdateEmployeeUseCase(_getIt<IEmployeeRepository>()),
    );

    _getIt.registerFactory<DeleteEmployeeUseCase>(
      () => DeleteEmployeeUseCase(_getIt<IEmployeeRepository>()),
    );

    // Attendance use case'leri
    _getIt.registerFactory<GetAttendanceUseCase>(
      () => GetAttendanceUseCase(_getIt<IAttendanceRepository>()),
    );

    _getIt.registerFactory<CreateAttendanceUseCase>(
      () => CreateAttendanceUseCase(_getIt<IAttendanceRepository>()),
    );

    _getIt.registerFactory<UpdateAttendanceUseCase>(
      () => UpdateAttendanceUseCase(_getIt<IAttendanceRepository>()),
    );

    _getIt.registerFactory<ApproveAttendanceUseCase>(
      () => ApproveAttendanceUseCase(_getIt<IAttendanceRepository>()),
    );

    // Notification use case'leri
    _getIt.registerFactory<GetNotificationsUseCase>(
      () => GetNotificationsUseCase(_getIt<INotificationRepository>()),
    );

    _getIt.registerFactory<MarkNotificationReadUseCase>(
      () => MarkNotificationReadUseCase(_getIt<INotificationRepository>()),
    );

    // Not: ScheduleReminderUseCase INotificationService'e ihtiyaç duyuyor
    // INotificationService henüz implement edilmediği için şimdilik yorum satırında
    // _getIt.registerFactory<ScheduleReminderUseCase>(
    //   () => ScheduleReminderUseCase(_getIt<INotificationService>()),
    // );
  }

  /// Controller'ları kaydet
  void _registerControllers() {
    // AuthController - factory (her seferinde yeni instance)
    _getIt.registerFactory<AuthController>(
      () => AuthController(
        signInUseCase: _getIt<SignInUseCase>(),
        signUpUseCase: _getIt<SignUpUseCase>(),
        signOutUseCase: _getIt<SignOutUseCase>(),
        getCurrentUserUseCase: _getIt<GetCurrentUserUseCase>(),
      ),
    );

    // HomeController - factory
    _getIt.registerFactory<HomeController>(
      () => HomeController(
        getNotificationsUseCase: _getIt<GetNotificationsUseCase>(),
      ),
    );

    // EmployeeController - factory
    _getIt.registerFactory<EmployeeController>(
      () => EmployeeController(
        getEmployeesUseCase: _getIt<GetEmployeesUseCase>(),
        createEmployeeUseCase: _getIt<CreateEmployeeUseCase>(),
        updateEmployeeUseCase: _getIt<UpdateEmployeeUseCase>(),
        deleteEmployeeUseCase: _getIt<DeleteEmployeeUseCase>(),
      ),
    );

    // AttendanceController - factory
    _getIt.registerFactory<AttendanceController>(
      () => AttendanceController(
        getAttendanceUseCase: _getIt<GetAttendanceUseCase>(),
        createAttendanceUseCase: _getIt<CreateAttendanceUseCase>(),
        updateAttendanceUseCase: _getIt<UpdateAttendanceUseCase>(),
        approveAttendanceUseCase: _getIt<ApproveAttendanceUseCase>(),
      ),
    );
  }

  /// Get a registered dependency
  /// Throws if the dependency is not registered.
  T get<T extends Object>() => _getIt.get<T>();

  /// Check if a dependency is registered
  bool isRegistered<T extends Object>() => _getIt.isRegistered<T>();

  /// Reset all registrations (for testing)
  Future<void> reset() async {
    await _getIt.reset();
  }
}
