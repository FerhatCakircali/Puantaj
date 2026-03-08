import 'package:flutter/foundation.dart';
import '../../../models/worker.dart';
import '../../../models/worker_with_unpaid_days.dart';
import '../../../core/repositories/base_supabase_repository.dart';
import '../../../utils/date_formatter.dart';
import '../constants/worker_constants.dart';

/// Çalışan verilerini veritabanından yöneten repository sınıfı
class WorkerRepository extends BaseSupabaseRepository {
  WorkerRepository(super.supabase);

  /// Kullanıcıya ait tüm çalışanları getirir
  ///
  /// [userId] Kullanıcı ID'si
  /// Returns: Çalışan listesi
  Future<List<Worker>> getWorkersByUserId(int userId) async {
    return executeQuery(
      () async {
        final List<dynamic> data = await supabase
            .from(WorkerConstants.tableName)
            .select()
            .eq(WorkerConstants.userIdColumn, userId)
            .order(WorkerConstants.fullNameColumn, ascending: true);

        return data.map((worker) => Worker.fromMap(worker)).toList();
      },
      [],
      context: 'WorkerRepository.getWorkersByUserId',
    );
  }

  /// Ödenmemiş gün bilgileriyle birlikte çalışanları getirir
  ///
  /// RPC fonksiyonu kullanarak N+1 query problemini çözer.
  ///
  /// [userId] Kullanıcı ID'si
  /// Returns: Ödenmemiş gün bilgili çalışan listesi
  Future<List<WorkerWithUnpaidDays>> getWorkersWithUnpaidDays(
    int userId,
  ) async {
    return executeQuery(
      () async {
        debugPrint('WorkerRepository: RPC çağrısı başlatılıyor...');

        final List<dynamic> data = await supabase.rpc(
          WorkerConstants.rpcGetWorkersWithUnpaidDays,
          params: {'p_user_id': userId},
        );

        debugPrint('WorkerRepository: ${data.length} çalışan getirildi');

        return data
            .map(
              (item) =>
                  WorkerWithUnpaidDays.fromMap(item as Map<String, dynamic>),
            )
            .toList();
      },
      [],
      context: 'WorkerRepository.getWorkersWithUnpaidDays',
    );
  }

  /// ID'ye göre çalışan getirir
  ///
  /// [workerId] Çalışan ID'si
  /// Returns: Çalışan bilgisi veya null
  Future<Worker?> getWorkerById(int workerId) async {
    return executeQuery(
      () async {
        debugPrint('WorkerRepository: workerId=$workerId');

        final data = await supabase
            .from(WorkerConstants.tableName)
            .select()
            .eq('id', workerId)
            .single();

        debugPrint('WorkerRepository: Çalışan bulundu: ${data['full_name']}');
        return Worker.fromMap(data);
      },
      null,
      context: 'WorkerRepository.getWorkerById',
    );
  }

  /// Yeni çalışan ekler
  ///
  /// [workerData] Çalışan verisi (map formatında)
  /// Returns: Eklenen çalışan bilgisi
  Future<Worker> insertWorker(Map<String, dynamic> workerData) async {
    return executeQueryWithThrow(() async {
      final data = await supabase
          .from(WorkerConstants.tableName)
          .insert(workerData)
          .select()
          .single();

      return Worker.fromMap(data);
    }, context: 'WorkerRepository.insertWorker');
  }

  /// Çalışan bilgilerini günceller
  ///
  /// [worker] Güncellenecek çalışan
  /// Returns: İşlem başarılı ise true
  Future<bool> updateWorker(Worker worker) async {
    return executeQueryWithThrow(() async {
      await supabase
          .from(WorkerConstants.tableName)
          .update(worker.toMap())
          .eq('id', worker.id!);

      debugPrint('WorkerRepository: Çalışan güncellendi');
      return true;
    }, context: 'WorkerRepository.updateWorker');
  }

  /// Çalışanı siler
  ///
  /// [workerId] Silinecek çalışanın ID'si
  /// [userId] Kullanıcı ID'si (yetki kontrolü için)
  /// Returns: İşlem başarılı ise true
  Future<bool> deleteWorker(int workerId, int userId) async {
    return executeQuery(
      () async {
        await supabase
            .from(WorkerConstants.tableName)
            .delete()
            .eq('id', workerId)
            .eq(WorkerConstants.userIdColumn, userId);

        return true;
      },
      false,
      context: 'WorkerRepository.deleteWorker',
    );
  }

  /// İsme göre çalışan arar
  ///
  /// [userId] Kullanıcı ID'si
  /// [query] Arama sorgusu
  /// Returns: Bulunan çalışan listesi
  Future<List<Worker>> searchWorkers(int userId, String query) async {
    return executeQuery(
      () async {
        final List<dynamic> data = await supabase
            .from(WorkerConstants.tableName)
            .select()
            .eq(WorkerConstants.userIdColumn, userId)
            .ilike(WorkerConstants.fullNameColumn, '%$query%')
            .order(WorkerConstants.fullNameColumn, ascending: true);

        return data.map((worker) => Worker.fromMap(worker)).toList();
      },
      [],
      context: 'WorkerRepository.searchWorkers',
    );
  }

  /// Belirtilen tarihten önce kayıt olup olmadığını kontrol eder
  ///
  /// [userId] Kullanıcı ID'si
  /// [workerId] Çalışan ID'si
  /// [date] Kontrol edilecek tarih
  /// Returns: Kayıt varsa true
  Future<bool> hasRecordsBeforeDate(
    int userId,
    int workerId,
    DateTime date,
  ) async {
    return executeQuery(
      () async {
        final formattedDate = DateFormatter.toIso8601Date(date);

        final attendanceResults = await supabase
            .from(WorkerConstants.attendanceTable)
            .select()
            .eq(WorkerConstants.userIdColumn, userId)
            .eq(WorkerConstants.workerIdColumn, workerId)
            .lt(WorkerConstants.dateColumn, formattedDate)
            .limit(1);

        if (attendanceResults.isNotEmpty) {
          return true;
        }

        final paymentResults = await supabase
            .from(WorkerConstants.paidDaysTable)
            .select()
            .eq(WorkerConstants.userIdColumn, userId)
            .eq(WorkerConstants.workerIdColumn, workerId)
            .lt(WorkerConstants.dateColumn, formattedDate)
            .limit(1);

        return paymentResults.isNotEmpty;
      },
      false,
      context: 'WorkerRepository.hasRecordsBeforeDate',
    );
  }

  /// Belirtilen tarihten önceki kayıtları siler
  ///
  /// [userId] Kullanıcı ID'si
  /// [workerId] Çalışan ID'si
  /// [date] Silinecek kayıtların son tarihi
  Future<void> deleteRecordsBeforeDate(
    int userId,
    int workerId,
    DateTime date,
  ) async {
    return executeQuery(
      () async {
        final formattedDate = DateFormatter.toIso8601Date(date);

        await supabase
            .from(WorkerConstants.attendanceTable)
            .delete()
            .eq(WorkerConstants.userIdColumn, userId)
            .eq(WorkerConstants.workerIdColumn, workerId)
            .lt(WorkerConstants.dateColumn, formattedDate);

        await supabase
            .from(WorkerConstants.paidDaysTable)
            .delete()
            .eq(WorkerConstants.userIdColumn, userId)
            .eq(WorkerConstants.workerIdColumn, workerId)
            .lt(WorkerConstants.dateColumn, formattedDate);
      },
      null,
      context: 'WorkerRepository.deleteRecordsBeforeDate',
    );
  }

  /// Kullanıcıya ait tüm çalışanları ve ilişkili kayıtları siler
  ///
  /// [userId] Kullanıcı ID'si
  Future<void> deleteAllWorkers(int userId) async {
    return executeQueryWithThrow(() async {
      await supabase
          .from(WorkerConstants.paidDaysTable)
          .delete()
          .eq(WorkerConstants.userIdColumn, userId);

      await supabase
          .from(WorkerConstants.paymentsTable)
          .delete()
          .eq(WorkerConstants.userIdColumn, userId);

      await supabase
          .from(WorkerConstants.attendanceTable)
          .delete()
          .eq(WorkerConstants.userIdColumn, userId);

      await supabase
          .from(WorkerConstants.tableName)
          .delete()
          .eq(WorkerConstants.userIdColumn, userId);
    }, context: 'WorkerRepository.deleteAllWorkers');
  }
}
