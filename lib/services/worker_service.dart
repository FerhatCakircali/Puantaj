import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/worker.dart';
import '../models/employee.dart';
import '../models/worker_with_unpaid_days.dart';
import '../utils/date_formatter.dart';
import '../core/error_logger.dart';
import '../data/local/hive_service.dart';
import '../data/local/sync_manager.dart';
import 'auth_service.dart';
import 'validation_service.dart';

class WorkerService {
  final AuthService _authService = AuthService();
  final _validationService = ValidationService.instance;
  final _hiveService = HiveService.instance;
  final _syncManager = SyncManager.instance;

  SupabaseClient get supabase => Supabase.instance.client;

  // Tüm çalışanları getir (Offline-First)
  Future<List<Employee>> getEmployees() async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        debugPrint(
          '⚠️ WorkerService.getEmployees: Kullanıcı oturumu bulunamadı',
        );
        return [];
      }

      // 1. Önce Hive'dan oku (optimistic read)
      final cachedEmployees =
          _hiveService.employees.values
              .where((e) => e.userId == userId)
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));

      // 2. Eğer online ise arka planda Supabase'den güncelle
      if (_syncManager.isOnline) {
        _fetchAndCacheEmployees(userId);
      }

      // 3. Cache'den döndür (UI hemen dolsun)
      if (cachedEmployees.isNotEmpty) {
        debugPrint(
          '✅ Hive cache\'den ${cachedEmployees.length} employee döndürüldü',
        );
        return cachedEmployees;
      }

      // 4. Cache boşsa ve online ise Supabase'den çek
      if (_syncManager.isOnline) {
        final response = await supabase
            .from('workers')
            .select('*, username')
            .eq('user_id', userId)
            .order('full_name');

        final employees = (response as List)
            .map((map) => Employee.fromMap(map as Map<String, dynamic>))
            .toList();

        // Hive'a kaydet
        for (var employee in employees) {
          await _hiveService.employees.put(employee.id, employee);
        }

        return employees;
      }

      return [];
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'WorkerService.getEmployees hatası',
        error: e,
        stackTrace: stackTrace,
      );

      // Hata durumunda cache'den döndür
      final cachedEmployees = _hiveService.employees.values.toList();
      return cachedEmployees;
    }
  }

  /// Arka planda Supabase'den çek ve cache'i güncelle
  Future<void> _fetchAndCacheEmployees(int userId) async {
    try {
      final response = await supabase
          .from('workers')
          .select('*, username')
          .eq('user_id', userId)
          .order('full_name');

      final employees = (response as List)
          .map((map) => Employee.fromMap(map as Map<String, dynamic>))
          .toList();

      // Hive'ı güncelle
      for (var employee in employees) {
        await _hiveService.employees.put(employee.id, employee);
      }

      debugPrint('🔄 Hive cache güncellendi: ${employees.length} employee');
    } catch (e) {
      // Sessizce başarısız ol (cache güncellenemedi ama UI etkilenmedi)
      debugPrint('Cache güncelleme başarısız: $e');
    }
  }

  Future<List<Worker>> getWorkers() async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final List<dynamic> data = await supabase
          .from('workers')
          .select()
          .eq('user_id', userId)
          .order('full_name', ascending: true);

      return data.map((worker) => Worker.fromMap(worker)).toList();
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'WorkerService.getWorkers hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Ödenmemiş gün bilgileriyle birlikte işçileri getirir (RPC)
    /// N+1 query problemini çözmek için Supabase RPC fonksiyonu kullanır.
  /// Performans: 15+ query → 1 query (%93 azalma)
    /// Saat Dilimi: Europe/Istanbul (UTC+3)
  Future<List<WorkerWithUnpaidDays>> getWorkersWithUnpaidDays() async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      debugPrint('getWorkersWithUnpaidDays: RPC çağrısı başlatılıyor...');

      final List<dynamic> data = await supabase.rpc(
        'get_workers_with_unpaid_days',
        params: {'p_user_id': userId},
      );

      debugPrint('getWorkersWithUnpaidDays: ${data.length} işçi getirildi');

      return data
          .map(
            (item) =>
                WorkerWithUnpaidDays.fromMap(item as Map<String, dynamic>),
          )
          .toList();
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'WorkerService.getWorkersWithUnpaidDays hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  // ID'ye göre çalışan getir (Worker) - Worker kendi profilini görüntülüyor
  Future<Worker?> getWorkerById(int workerId) async {
    try {
      debugPrint('getWorkerById: workerId=$workerId');

      // Worker kendi profilini görüntülüyorsa user_id kontrolü yapmaya gerek yok
      final data = await supabase
          .from('workers')
          .select()
          .eq('id', workerId)
          .single();

      debugPrint('✅ getWorkerById: Worker bulundu: ${data['full_name']}');
      return Worker.fromMap(data);
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'WorkerService.getWorkerById hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  // Çalışan ekle (Worker) - Offline-First
  Future<Worker?> addWorker(Worker worker) async {
    Worker? tempWorker;

    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      // Email kontrolü (eğer email varsa ve online ise)
      if (_syncManager.isOnline &&
          worker.email != null &&
          worker.email!.isNotEmpty) {
        final emailCheck = await _checkEmailAvailability(worker.email!);
        if (emailCheck != null) {
          debugPrint('addWorker: Email hatası: $emailCheck');
          throw Exception(emailCheck);
        }
      }

      final map = worker.toMap();
      map['user_id'] = userId;

      // 1. Optimistic update: Geçici ID ile Hive'a kaydet
      final tempId = DateTime.now().millisecondsSinceEpoch;
      tempWorker = Worker(
        id: tempId,
        userId: userId,
        username: worker.username,
        fullName: worker.fullName,
        title: worker.title,
        phone: worker.phone,
        email: worker.email,
        startDate: worker.startDate,
      );

      await _hiveService.workers.put(tempId, tempWorker);
      debugPrint('✅ Optimistic: Worker Hive\'a eklendi (temp ID: $tempId)');

      // 2. Online ise Supabase'e gönder
      if (_syncManager.isOnline) {
        try {
          final data = await supabase
              .from('workers')
              .insert(map)
              .select()
              .single();

          final realWorker = Worker.fromMap(data);

          // 3. Gerçek ID ile güncelle
          await _hiveService.workers.delete(tempId);
          await _hiveService.workers.put(realWorker.id!, realWorker);

          debugPrint(
            '✅ Worker Supabase\'e eklendi (real ID: ${realWorker.id})',
          );
          return realWorker;
        } catch (e) {
          // Supabase hatası: Pending sync'e ekle
          await _syncManager.addPendingSync(
            type: 'worker',
            data: map,
            operation: 'create',
          );

          debugPrint('⚠️ Offline: Worker pending sync\'e eklendi');
          return tempWorker;
        }
      } else {
        // 4. Offline: Pending sync'e ekle
        await _syncManager.addPendingSync(
          type: 'worker',
          data: map,
          operation: 'create',
        );

        debugPrint('📵 Offline: Worker pending sync\'e eklendi');
        return tempWorker;
      }
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'WorkerService.addWorker hatası',
        error: e,
        stackTrace: stackTrace,
      );

      // Rollback: Hive'dan sil
      if (tempWorker?.id != null) {
        await _hiveService.workers.delete(tempWorker!.id!);
        debugPrint('🔄 Rollback: Worker Hive\'dan silindi');
      }

      rethrow;
    }
  }

  // Çalışan ekle (Employee - backward compatibility)
  Future<int> addEmployee(Employee employee) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return -1;

      final response = await supabase
          .from('workers')
          .insert({
            'full_name': employee.name,
            'title': employee.title,
            'phone': employee.phone,
            'email': employee.email,
            'start_date': DateFormatter.toIso8601Date(employee.startDate),
            'user_id': userId,
            'username':
                employee.username ??
                employee.name.toLowerCase().replaceAll(' ', ''),
            'password_hash': employee.password ?? 'default123',
          })
          .select('id');
      return response.first['id'] as int;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'WorkerService.addEmployee hatası',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Kullanıcı adı kontrolü (ValidationService kullanarak)
  Future<bool> isUsernameExists(String username) async {
    try {
      debugPrint('isUsernameExists: Kontrol ediliyor: $username');

      final result = await _validationService.checkUsernameAvailability(
        username.toLowerCase(),
      );

      final exists = result != null;
      debugPrint('isUsernameExists: Sonuç: $exists');
      return exists;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'WorkerService.isUsernameExists hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  // E-posta kontrolü (ValidationService kullanarak)
  Future<bool> isEmailExists(String email) async {
    try {
      // Boş email kontrolü
      if (email.trim().isEmpty) return false;

      debugPrint('isEmailExists: Kontrol ediliyor: $email');

      final result = await _validationService.checkEmailAvailability(
        email.toLowerCase(),
      );

      final exists = result != null;
      debugPrint('isEmailExists: Sonuç: $exists');
      return exists;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'WorkerService.isEmailExists hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  // Çalışan güncelle (Worker) - Worker kendi profilini güncelliyor
  Future<bool> updateWorker(Worker worker) async {
    try {
      debugPrint('updateWorker: Güncelleniyor: ${worker.fullName}');

      // Email kontrolü (eğer email varsa)
      if (worker.email != null && worker.email!.isNotEmpty) {
        final emailCheck = await _checkEmailAvailability(
          worker.email!,
          workerId: worker.id,
        );
        if (emailCheck != null) {
          debugPrint('updateWorker: Email hatası: $emailCheck');
          throw Exception(emailCheck);
        }
      }

      // Worker kendi profilini güncelliyorsa user_id kontrolü yapmaya gerek yok
      await supabase
          .from('workers')
          .update(worker.toMap())
          .eq('id', worker.id!);

      debugPrint('updateWorker: Başarıyla güncellendi');
      return true;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'WorkerService.updateWorker hatası',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Email kullanılabilirlik kontrolü (hem users hem workers tablosunda)
  Future<String?> _checkEmailAvailability(String email, {int? workerId}) async {
    try {
      final lowercaseEmail = email.toLowerCase();

      // ValidationService kullanarak kontrol et
      return await _validationService.checkEmailAvailability(
        lowercaseEmail,
        excludeWorkerId: workerId,
      );
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'WorkerService._checkEmailAvailability hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return 'E-posta kontrolü sırasında bir hata oluştu';
    }
  }

  // Çalışan güncelle (Employee - backward compatibility)
  Future<int> updateEmployee(Employee employee) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      await supabase
          .from('workers')
          .update({
            'full_name': employee.name,
            'title': employee.title,
            'phone': employee.phone,
            'start_date': DateFormatter.toIso8601Date(employee.startDate),
            'is_active': employee.isActive,
            'is_trusted': employee.isTrusted,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', employee.id)
          .eq('user_id', userId);
      return employee.id;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'WorkerService.updateEmployee hatası',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  // Çalışan sil (Worker)
  Future<bool> deleteWorker(int workerId) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      await supabase
          .from('workers')
          .delete()
          .eq('id', workerId)
          .eq('user_id', userId);

      return true;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'WorkerService.deleteWorker hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  // Çalışan sil (Employee - backward compatibility)
  Future<int> deleteEmployee(int id) async {
    final userId = await _authService.getUserId();
    if (userId == null) return -1;

    try {
      await supabase
          .from('workers')
          .delete()
          .eq('id', id)
          .eq('user_id', userId);

      return 1;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'WorkerService.deleteEmployee hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return -1;
    }
  }

  // Tüm çalışanları sil (Employee - backward compatibility)
  Future<int> deleteAllEmployees() async {
    final userId = await _authService.getUserId();
    if (userId == null) return -1;

    try {
      // İlişkili kayıtları da sil (cascading delete yerine manuel silme)
      await supabase.from('paid_days').delete().eq('user_id', userId);

      await supabase.from('payments').delete().eq('user_id', userId);

      await supabase.from('attendance').delete().eq('user_id', userId);

      await supabase.from('workers').delete().eq('user_id', userId);

      return 1;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'WorkerService.deleteAllEmployees hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return -1;
    }
  }

  // İsme göre çalışan ara (Worker)
  Future<List<Worker>> searchWorkers(String query) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      final List<dynamic> data = await supabase
          .from('workers')
          .select()
          .eq('user_id', userId)
          .ilike('full_name', '%$query%')
          .order('full_name', ascending: true);

      return data.map((worker) => Worker.fromMap(worker)).toList();
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'WorkerService.searchWorkers hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  // Belirlenen tarihten öncesinde herhangi bir devam kaydı veya ödeme kaydı var mı
  Future<bool> hasRecordsBeforeDate(int workerId, DateTime date) async {
    final userId = await _authService.getUserId();
    if (userId == null) return false;

    final formattedDate = DateFormatter.toIso8601Date(date);

    try {
      // Devam kayıtlarını kontrol et
      final attendanceResults = await supabase
          .from('attendance')
          .select()
          .eq('user_id', userId)
          .eq('worker_id', workerId)
          .lt('date', formattedDate)
          .limit(1);

      if (attendanceResults.isNotEmpty) {
        return true;
      }

      // Ödeme kayıtlarını kontrol et
      final paymentResults = await supabase
          .from('paid_days')
          .select()
          .eq('user_id', userId)
          .eq('worker_id', workerId)
          .lt('date', formattedDate)
          .limit(1);

      return paymentResults.isNotEmpty;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'WorkerService.hasRecordsBeforeDate hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  // Belirlenen tarihten önce olan tüm kayıtları sil
  Future<void> deleteRecordsBeforeDate(int workerId, DateTime date) async {
    final userId = await _authService.getUserId();
    if (userId == null) return;

    final formattedDate = DateFormatter.toIso8601Date(date);

    try {
      // 1. Önce devam kayıtlarını sil
      await supabase
          .from('attendance')
          .delete()
          .eq('user_id', userId)
          .eq('worker_id', workerId)
          .lt('date', formattedDate);

      // 2. Ödemesi yapılmış günleri sil
      await supabase
          .from('paid_days')
          .delete()
          .eq('user_id', userId)
          .eq('worker_id', workerId)
          .lt('date', formattedDate);

      // 3. Belirli tarihten önceki ödeme kayıtlarını sil
      await supabase
          .from('payments')
          .delete()
          .eq('user_id', userId)
          .eq('worker_id', workerId)
          .lt('payment_date', formattedDate);

      // 4. Sahipsiz ödeme kayıtlarını sil
      await _deleteOrphanedPayments(userId, workerId);

      // 5. Kalan ödemeleri güncelle
      await _updateRemainingPayments(userId, workerId);
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'WorkerService.deleteRecordsBeforeDate hatası',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // Sahipsiz ödeme kayıtlarını silen yardımcı metod
  Future<void> _deleteOrphanedPayments(int userId, int workerId) async {
    try {
      final orphanedPayments = await supabase
          .from('payments')
          .select('id')
          .eq('user_id', userId)
          .eq('worker_id', workerId);

      if (orphanedPayments.isEmpty) return;

      List<int> paymentIds = orphanedPayments
          .map<int>((p) => p['id'] as int)
          .toList();

      for (final paymentId in paymentIds) {
        final paidDays = await supabase
            .from('paid_days')
            .select()
            .eq('payment_id', paymentId)
            .limit(1);

        if (paidDays.isEmpty) {
          await supabase.from('payments').delete().eq('id', paymentId);
        }
      }
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'WorkerService._deleteOrphanedPayments hatası',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // Kalan ödemelerin gün sayılarını güncelleyen yardımcı metod
  Future<void> _updateRemainingPayments(int userId, int workerId) async {
    try {
      final payments = await supabase
          .from('payments')
          .select('id')
          .eq('user_id', userId)
          .eq('worker_id', workerId);

      for (final payment in payments) {
        final paymentId = payment['id'] as int;

        final fullDaysResult = await supabase
            .from('paid_days')
            .select()
            .eq('payment_id', paymentId)
            .eq('status', 'fullDay');

        final fullDays = fullDaysResult.length;

        final halfDaysResult = await supabase
            .from('paid_days')
            .select()
            .eq('payment_id', paymentId)
            .eq('status', 'halfDay');

        final halfDays = halfDaysResult.length;

        await supabase
            .from('payments')
            .update({'full_days': fullDays, 'half_days': halfDays})
            .eq('id', paymentId);
      }
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'WorkerService._updateRemainingPayments hatası',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
