import '../../models/worker.dart';
import '../../models/employee.dart';
import '../../models/worker_with_unpaid_days.dart';
import '../../core/error_handling/error_handler_mixin.dart';
import '../../core/auth/base_auth_helper.dart';
import '../../core/di/service_locator.dart';
import '../../data/local/sync_manager.dart';
import '../auth_service.dart';
import 'validators/worker_validator.dart';
import 'repositories/worker_repository.dart';
import 'repositories/employee_repository.dart';
import 'helpers/worker_cache_helper.dart';
import 'helpers/worker_sync_helper.dart';
import 'helpers/worker_payment_helper.dart';

/// Çalışan yönetimi için ana servis sınıfı
class WorkerService extends BaseAuthHelper with ErrorHandlerMixin {
  final WorkerValidator _validator;
  final WorkerRepository _repository;
  final EmployeeRepository _employeeRepository;
  final WorkerCacheHelper _cacheHelper;
  final WorkerSyncHelper _syncHelper;
  final WorkerPaymentHelper _paymentHelper;
  final SyncManager _syncManager;

  WorkerService({
    required AuthService authService,
    WorkerValidator? validator,
    WorkerRepository? repository,
    EmployeeRepository? employeeRepository,
    WorkerCacheHelper? cacheHelper,
    WorkerSyncHelper? syncHelper,
    WorkerPaymentHelper? paymentHelper,
    SyncManager? syncManager,
  }) : _validator = validator ?? WorkerValidator(),
       _repository = repository ?? getIt<WorkerRepository>(),
       _employeeRepository = employeeRepository ?? getIt<EmployeeRepository>(),
       _cacheHelper = cacheHelper ?? WorkerCacheHelper(),
       _syncHelper = syncHelper ?? WorkerSyncHelper(),
       _paymentHelper = paymentHelper ?? WorkerPaymentHelper(),
       _syncManager = syncManager ?? SyncManager.instance,
       super(authService);

  /// Tüm çalışanları offline-first yaklaşımla getirir
  ///
  /// Önce cache'den döner, arka planda Supabase'den günceller.
  ///
  /// Returns: Çalışan listesi
  Future<List<Employee>> getEmployees() async {
    return handleError(
      () async {
        final userId = await getUserId();
        if (userId == null) return [];

        final cachedEmployees = _cacheHelper.getCachedEmployees(userId);

        if (_syncManager.isOnline) {
          _cacheHelper.fetchAndCacheEmployees(userId);
        }

        if (cachedEmployees.isNotEmpty) return cachedEmployees;
        if (_syncManager.isOnline) {
          return await _cacheHelper.fetchEmployees(userId);
        }

        return [];
      },
      _cacheHelper.getAllCachedEmployees(),
      context: 'WorkerService.getEmployees',
    );
  }

  /// Kullanıcıya ait tüm çalışanları getirir
  ///
  /// Returns: Çalışan listesi
  Future<List<Worker>> getWorkers() async {
    return handleError(
      () =>
          executeWithUserId((userId) => _repository.getWorkersByUserId(userId)),
      [],
      context: 'WorkerService.getWorkers',
    );
  }

  /// Ödenmemiş gün bilgileriyle birlikte çalışanları getirir
  ///
  /// RPC fonksiyonu kullanarak performanslı veri çeker.
  ///
  /// Returns: Ödenmemiş gün bilgili çalışan listesi
  Future<List<WorkerWithUnpaidDays>> getWorkersWithUnpaidDays() async {
    return handleError(
      () => executeWithUserId(
        (userId) => _repository.getWorkersWithUnpaidDays(userId),
      ),
      [],
      context: 'WorkerService.getWorkersWithUnpaidDays',
    );
  }

  /// ID'ye göre çalışan getirir
  ///
  /// [workerId] Çalışan ID'si
  /// Returns: Çalışan bilgisi veya null
  Future<Worker?> getWorkerById(int workerId) async {
    return handleError(
      () async => await _repository.getWorkerById(workerId),
      null,
      context: 'WorkerService.getWorkerById',
    );
  }

  /// Yeni çalışan ekler (offline-first)
  ///
  /// [worker] Eklenecek çalışan
  /// Returns: Eklenen çalışan (temp veya real ID ile)
  Future<Worker?> addWorker(Worker worker) async {
    Worker? tempWorker;

    return handleErrorWithThrow(
      () => executeWithUserId((userId) async {
        if (_syncManager.isOnline &&
            worker.email != null &&
            worker.email!.isNotEmpty) {
          final emailCheck = await _validator.checkEmailAvailability(
            worker.email!,
          );
          if (emailCheck != null) throw Exception(emailCheck);
        }

        final map = worker.toMap();
        map['user_id'] = userId;

        tempWorker = await _syncHelper.addWorkerWithSync(map, userId);
        return tempWorker;
      }),
      context: 'WorkerService.addWorker',
      userMessage: 'Çalışan eklenirken hata oluştu',
    ).catchError((error) async {
      await _syncHelper.cleanupTempWorker(tempWorker?.id);
      throw error;
    });
  }

  /// Çalışan bilgilerini günceller
  ///
  /// [worker] Güncellenecek çalışan
  /// Returns: İşlem başarılı ise true
  Future<bool> updateWorker(Worker worker) async {
    return handleErrorWithThrow(
      () async {
        if (worker.email != null && worker.email!.isNotEmpty) {
          final emailCheck = await _validator.checkEmailAvailability(
            worker.email!,
            workerId: worker.id,
          );
          if (emailCheck != null) {
            throw Exception(emailCheck);
          }
        }

        return await _repository.updateWorker(worker);
      },
      context: 'WorkerService.updateWorker',
      userMessage: 'Çalışan güncellenirken hata oluştu',
    );
  }

  /// Çalışanı siler
  ///
  /// [workerId] Silinecek çalışanın ID'si
  /// Returns: İşlem başarılı ise true
  Future<bool> deleteWorker(int workerId) async {
    return handleError(
      () => executeWithUserId(
        (userId) => _repository.deleteWorker(workerId, userId),
      ),
      false,
      context: 'WorkerService.deleteWorker',
    );
  }

  /// İsme göre çalışan arar
  ///
  /// [query] Arama sorgusu
  /// Returns: Bulunan çalışan listesi
  Future<List<Worker>> searchWorkers(String query) async {
    return handleError(
      () => executeWithUserId(
        (userId) => _repository.searchWorkers(userId, query),
      ),
      [],
      context: 'WorkerService.searchWorkers',
    );
  }

  /// Kullanıcı adının kullanılıp kullanılmadığını kontrol eder
  ///
  /// [username] Kontrol edilecek kullanıcı adı
  /// Returns: Kullanılıyorsa true
  Future<bool> isUsernameExists(String username) async {
    return await _validator.isUsernameExists(username);
  }

  /// E-posta adresinin kullanılıp kullanılmadığını kontrol eder
  ///
  /// [email] Kontrol edilecek e-posta adresi
  /// Returns: Kullanılıyorsa true
  Future<bool> isEmailExists(String email) async {
    return await _validator.isEmailExists(email);
  }

  /// Belirtilen tarihten önce kayıt olup olmadığını kontrol eder
  ///
  /// [workerId] Çalışan ID'si
  /// [date] Kontrol edilecek tarih
  /// Returns: Kayıt varsa true
  Future<bool> hasRecordsBeforeDate(int workerId, DateTime date) async {
    final userId = await getUserId();
    if (userId == null) return false;
    return await _repository.hasRecordsBeforeDate(userId, workerId, date);
  }

  /// Belirtilen tarihten önceki kayıtları siler ve ödemeleri günceller
  ///
  /// [workerId] Çalışan ID'si
  /// [date] Silinecek kayıtların son tarihi
  Future<void> deleteRecordsBeforeDate(int workerId, DateTime date) async {
    final userId = await getUserId();
    if (userId == null) return;
    await _repository.deleteRecordsBeforeDate(userId, workerId, date);
    await _paymentHelper.deleteOrphanedPayments(userId, workerId);
    await _paymentHelper.updateRemainingPayments(userId, workerId);
  }

  // Backward compatibility metodları (Employee modeli için)

  /// Yeni employee ekler (backward compatibility)
  Future<int> addEmployee(Employee employee) async {
    return handleErrorWithThrow(
      () => executeWithUserId(
        (userId) => _employeeRepository.insertEmployee(employee, userId),
      ),
      context: 'WorkerService.addEmployee',
      userMessage: 'Employee eklenirken hata oluştu',
    );
  }

  /// Employee bilgilerini günceller (backward compatibility)
  Future<int> updateEmployee(Employee employee) async {
    return handleErrorWithThrow(
      () => executeWithUserId(
        (userId) => _employeeRepository.updateEmployee(employee, userId),
      ),
      context: 'WorkerService.updateEmployee',
      userMessage: 'Employee güncellenirken hata oluştu',
    );
  }

  /// Employee'yi siler (backward compatibility)
  Future<int> deleteEmployee(int id) async {
    return handleError(
      () => executeWithUserId(
        (userId) => _employeeRepository.deleteEmployee(id, userId),
      ),
      -1,
      context: 'WorkerService.deleteEmployee',
    );
  }

  /// Tüm employee'leri siler (backward compatibility)
  Future<int> deleteAllEmployees() async {
    return handleError(
      () => executeWithUserId((userId) async {
        await _repository.deleteAllWorkers(userId);
        return 1;
      }),
      -1,
      context: 'WorkerService.deleteAllEmployees',
    );
  }
}
