import 'package:flutter/foundation.dart';
import '../../../models/advance.dart';
import '../../../core/repositories/base_crud_repository.dart';
import '../../../core/constants/database_constants.dart';

/// Avans CRUD işlemlerini yöneten repository
class AdvanceRepository extends BaseCrudRepository<Advance> {
  @override
  String get tableName => DatabaseConstants.advancesTable;

  @override
  Map<String, dynamic> toMap(Advance entity) => entity.toMap();

  @override
  Advance fromMap(Map<String, dynamic> map) => Advance.fromMap(map);

  Future<List<Advance>> getAdvances(int userId) async {
    debugPrint('Avanslar getiriliyor...');
    final advances = await getAll(
      userId,
      orderBy: 'advance_date',
      ascending: false,
    );
    debugPrint('${advances.length} avans getirildi');
    return advances;
  }

  Future<List<Advance>> getWorkerAdvances(int userId, int workerId) async {
    return executeQuery(
      () async {
        debugPrint('Çalışan avansları getiriliyor: workerId=$workerId');
        final results = await supabase
            .from(tableName)
            .select()
            .eq(userIdField, userId)
            .eq('worker_id', workerId)
            .order('advance_date', ascending: false);
        final advances = results.map((map) => fromMap(map)).toList();
        debugPrint('${advances.length} avans getirildi');
        return advances;
      },
      [],
      context: 'AdvanceRepository.getWorkerAdvances',
    );
  }

  Future<double> getWorkerPendingAdvances(int workerId) async {
    return executeQuery(
      () async {
        debugPrint('Bekleyen avanslar hesaplanıyor: workerId=$workerId');
        final result = await supabase.rpc(
          'get_worker_pending_advances',
          params: {'worker_id_param': workerId},
        );
        return (result as num?)?.toDouble() ?? 0.0;
      },
      0.0,
      context: 'AdvanceRepository.getWorkerPendingAdvances',
    );
  }

  Future<int> addAdvance(Advance advance, int userId) => add(advance, userId);

  Future<bool> updateAdvance(Advance advance, int userId) =>
      update(advance, advance.id, userId);

  Future<bool> deleteAdvance(int id, int userId) => delete(id, userId);
}
