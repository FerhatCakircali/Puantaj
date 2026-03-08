import 'package:flutter/foundation.dart';
import '../../../models/expense.dart';
import '../../../core/sync/offline_sync_mixin.dart';
import '../repositories/expense_repository.dart';

/// Masraf verilerini offline-first yaklaşımla senkronize eden helper sınıfı
class ExpenseSyncHelper with OfflineSyncMixin {
  final _repository = ExpenseRepository();

  /// Masrafı offline-first yaklaşımla ekler
  ///
  /// [expense] Masraf bilgisi
  /// [userId] Kullanıcı ID'si
  /// Returns: Eklenen masraf ID'si (temp veya real)
  Future<int> addExpenseWithSync(Expense expense, int userId) async {
    final tempId = DateTime.now().millisecondsSinceEpoch;

    // Not: HiveService'de expenses box'ı yok, cache kullanmıyoruz
    debugPrint('Masraf ekleniyor (temp ID: $tempId)');

    return await addWithSync(
      type: 'expense',
      data: expense.toMap(),
      tempId: tempId,
      onlineOperation: () async {
        final realId = await _repository.addExpense(expense, userId);
        debugPrint('Masraf veritabanına eklendi (ID: $realId)');
        return realId;
      },
    );
  }

  /// Masrafı offline-first yaklaşımla günceller
  ///
  /// [expense] Güncellenecek masraf
  /// [userId] Kullanıcı ID'si
  /// Returns: İşlem başarılı ise true
  Future<bool> updateExpenseWithSync(Expense expense, int userId) async {
    return await updateWithSync(
      type: 'expense',
      data: expense.toMap(),
      onlineOperation: () => _repository.updateExpense(expense, userId),
    );
  }

  /// Masrafı offline-first yaklaşımla siler
  ///
  /// [id] Silinecek masraf ID'si
  /// [userId] Kullanıcı ID'si
  /// Returns: İşlem başarılı ise true
  Future<bool> deleteExpenseWithSync(int id, int userId) async {
    return await deleteWithSync(
      type: 'expense',
      id: id,
      onlineOperation: () => _repository.deleteExpense(id, userId),
    );
  }
}
