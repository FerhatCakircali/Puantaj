import 'package:flutter/foundation.dart';
import '../../../models/worker.dart';
import '../../../data/local/hive_service.dart';
import '../../../data/local/sync_manager.dart';
import '../../../core/di/service_locator.dart';
import '../repositories/worker_repository.dart';

/// Çalışan verilerini offline-first yaklaşımla senkronize eden helper sınıfı
class WorkerSyncHelper {
  final _hiveService = HiveService.instance;
  final _syncManager = SyncManager.instance;
  late final _repository = getIt<WorkerRepository>();

  /// Çalışanı offline-first yaklaşımla ekler
  ///
  /// Online ise direkt Supabase'e kaydeder.
  /// Offline ise local cache'e kaydedip senkronizasyon kuyruğuna ekler.
  ///
  /// [workerData] Çalışan verisi (map formatında)
  /// [userId] Kullanıcı ID'si
  /// Returns: Eklenen çalışan (temp veya real ID ile)
  Future<Worker> addWorkerWithSync(
    Map<String, dynamic> workerData,
    int userId,
  ) async {
    final tempId = DateTime.now().millisecondsSinceEpoch;
    final tempWorker = Worker(
      id: tempId,
      userId: userId,
      username: workerData['username'] as String,
      fullName: workerData['full_name'] as String,
      title: workerData['title'] as String?,
      phone: workerData['phone'] as String?,
      email: workerData['email'] as String?,
      startDate: workerData['start_date'] as String,
    );

    await _hiveService.workers.put(tempId, tempWorker);
    debugPrint('Çalışan cache\'e eklendi (temp ID: $tempId)');

    if (_syncManager.isOnline) {
      try {
        final realWorker = await _repository.insertWorker(workerData);

        await _hiveService.workers.delete(tempId);
        await _hiveService.workers.put(realWorker.id!, realWorker);

        debugPrint('Çalışan veritabanına eklendi (ID: ${realWorker.id})');
        return realWorker;
      } catch (e) {
        await _syncManager.addPendingSync(
          type: 'worker',
          data: workerData,
          operation: 'create',
        );

        debugPrint('Offline: Çalışan senkronizasyon kuyruğuna eklendi');
        return tempWorker;
      }
    } else {
      await _syncManager.addPendingSync(
        type: 'worker',
        data: workerData,
        operation: 'create',
      );

      debugPrint('Offline: Çalışan senkronizasyon kuyruğuna eklendi');
      return tempWorker;
    }
  }

  /// Hata durumunda temp worker'ı cache'den temizler
  ///
  /// [tempWorkerId] Silinecek temp worker ID'si
  Future<void> cleanupTempWorker(int? tempWorkerId) async {
    if (tempWorkerId != null) {
      await _hiveService.workers.delete(tempWorkerId);
      debugPrint('Temp çalışan cache\'den silindi');
    }
  }
}
