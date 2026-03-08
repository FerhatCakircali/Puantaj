import 'package:flutter/foundation.dart';
import '../../../models/advance.dart';
import '../../../core/sync/offline_sync_mixin.dart';
import '../repositories/advance_repository.dart';

/// Avans verilerini offline-first yaklaşımla senkronize eden helper sınıfı
class AdvanceSyncHelper with OfflineSyncMixin {
  final _repository = AdvanceRepository();

  /// Avansı offline-first yaklaşımla ekler
  ///
  /// [advance] Avans bilgisi
  /// [userId] Kullanıcı ID'si
  /// Returns: Eklenen avans ID'si (temp veya real)
  Future<int> addAdvanceWithSync(Advance advance, int userId) async {
    final tempId = DateTime.now().millisecondsSinceEpoch;

    // Not: HiveService'de advances box'ı yok, cache kullanmıyoruz
    debugPrint('Avans ekleniyor (temp ID: $tempId)');

    return await addWithSync(
      type: 'advance',
      data: advance.toMap(),
      tempId: tempId,
      onlineOperation: () async {
        final realId = await _repository.addAdvance(advance, userId);
        debugPrint('Avans veritabanına eklendi (ID: $realId)');
        return realId;
      },
    );
  }

  /// Avansı offline-first yaklaşımla günceller
  ///
  /// [advance] Güncellenecek avans
  /// [userId] Kullanıcı ID'si
  /// Returns: İşlem başarılı ise true
  Future<bool> updateAdvanceWithSync(Advance advance, int userId) async {
    return await updateWithSync(
      type: 'advance',
      data: advance.toMap(),
      onlineOperation: () => _repository.updateAdvance(advance, userId),
    );
  }

  /// Avansı offline-first yaklaşımla siler
  ///
  /// [id] Silinecek avans ID'si
  /// [userId] Kullanıcı ID'si
  /// Returns: İşlem başarılı ise true
  Future<bool> deleteAdvanceWithSync(int id, int userId) async {
    return await deleteWithSync(
      type: 'advance',
      id: id,
      onlineOperation: () => _repository.deleteAdvance(id, userId),
    );
  }
}
