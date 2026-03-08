import 'package:flutter/foundation.dart';
import '../../data/local/hive_service.dart';
import '../../data/local/sync_manager.dart';

/// Offline-first senkronizasyon için ortak mixin
///
/// Tüm sync helper'ların kullanabileceği ortak metodları sağlar.
/// Kod tekrarını elimine eder ve tutarlı offline-first davranış sağlar.
mixin OfflineSyncMixin {
  HiveService get hiveService => HiveService.instance;
  SyncManager get syncManager => SyncManager.instance;

  /// Online durumunu kontrol eder
  bool get isOnline => syncManager.isOnline;

  /// Veriyi offline-first yaklaşımla ekler
  ///
  /// [type] Veri tipi (worker, payment, advance, expense)
  /// [data] Eklenecek veri
  /// [onlineOperation] Online ise çalıştırılacak operasyon
  /// [tempId] Temp ID (opsiyonel, verilmezse timestamp kullanılır)
  /// Returns: Eklenen veri ID'si (temp veya real)
  Future<int> addWithSync({
    required String type,
    required Map<String, dynamic> data,
    required Future<int> Function() onlineOperation,
    int? tempId,
  }) async {
    final effectiveTempId = tempId ?? DateTime.now().millisecondsSinceEpoch;

    if (isOnline) {
      try {
        final realId = await onlineOperation();
        debugPrint('$type veritabanına eklendi (ID: $realId)');
        return realId;
      } catch (e) {
        await _addToPendingSync(type, data, 'create');
        debugPrint('Offline: $type senkronizasyon kuyruğuna eklendi');
        return effectiveTempId;
      }
    } else {
      await _addToPendingSync(type, data, 'create');
      debugPrint('Offline: $type senkronizasyon kuyruğuna eklendi');
      return effectiveTempId;
    }
  }

  /// Veriyi offline-first yaklaşımla günceller
  ///
  /// [type] Veri tipi
  /// [data] Güncellenecek veri
  /// [onlineOperation] Online ise çalıştırılacak operasyon
  /// Returns: İşlem başarılı ise true
  Future<bool> updateWithSync({
    required String type,
    required Map<String, dynamic> data,
    required Future<bool> Function() onlineOperation,
  }) async {
    if (isOnline) {
      try {
        final success = await onlineOperation();
        if (success) {
          debugPrint('$type veritabanında güncellendi');
        }
        return success;
      } catch (e) {
        await _addToPendingSync(type, data, 'update');
        debugPrint(
          'Offline: $type güncelleme senkronizasyon kuyruğuna eklendi',
        );
        return true;
      }
    } else {
      await _addToPendingSync(type, data, 'update');
      debugPrint('Offline: $type güncelleme senkronizasyon kuyruğuna eklendi');
      return true;
    }
  }

  /// Veriyi offline-first yaklaşımla siler
  ///
  /// [type] Veri tipi
  /// [id] Silinecek veri ID'si
  /// [onlineOperation] Online ise çalıştırılacak operasyon
  /// Returns: İşlem başarılı ise true
  Future<bool> deleteWithSync({
    required String type,
    required int id,
    required Future<bool> Function() onlineOperation,
  }) async {
    if (isOnline) {
      try {
        final success = await onlineOperation();
        if (success) {
          debugPrint('$type veritabanından silindi (ID: $id)');
        }
        return success;
      } catch (e) {
        await _addToPendingSync(type, {'id': id}, 'delete');
        debugPrint('Offline: $type silme senkronizasyon kuyruğuna eklendi');
        return true;
      }
    } else {
      await _addToPendingSync(type, {'id': id}, 'delete');
      debugPrint('Offline: $type silme senkronizasyon kuyruğuna eklendi');
      return true;
    }
  }

  /// Pending sync'e veri ekler
  Future<void> _addToPendingSync(
    String type,
    Map<String, dynamic> data,
    String operation,
  ) async {
    await syncManager.addPendingSync(
      type: type,
      data: data,
      operation: operation,
    );
  }
}
