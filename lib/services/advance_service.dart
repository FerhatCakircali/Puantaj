import 'package:flutter/foundation.dart';
import '../models/advance.dart';
import '../core/app_globals.dart';
import '../utils/date_formatter.dart';
import '../utils/currency_formatter.dart';
import '../core/error_logger.dart';
import 'auth_service.dart';

/// Avans yönetimi servisi
/// Çalışanlara verilen avansların CRUD işlemlerini yönetir
class AdvanceService {
  final _authService = AuthService();

  /// Yöneticinin tüm avanslarını getir
  Future<List<Advance>> getAdvances() async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        ErrorLogger.instance.logWarning(
          'AdvanceService.getAdvances: userId null',
        );
        return [];
      }

      debugPrint('💰 Avanslar getiriliyor...');

      final results = await supabase
          .from('advances')
          .select()
          .eq('user_id', userId)
          .order('advance_date', ascending: false);

      final advances = results.map((map) => Advance.fromMap(map)).toList();

      debugPrint('✅ ${advances.length} avans getirildi');
      return advances;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'AdvanceService.getAdvances hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Belirli bir çalışanın avanslarını getir
  Future<List<Advance>> getWorkerAdvances(int workerId) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        ErrorLogger.instance.logWarning(
          'AdvanceService.getWorkerAdvances: userId null',
        );
        return [];
      }

      debugPrint('💰 Çalışan avansları getiriliyor: workerId=$workerId');

      final results = await supabase
          .from('advances')
          .select()
          .eq('user_id', userId)
          .eq('worker_id', workerId)
          .order('advance_date', ascending: false);

      final advances = results.map((map) => Advance.fromMap(map)).toList();

      debugPrint('✅ ${advances.length} avans getirildi');
      return advances;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'AdvanceService.getWorkerAdvances hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Çalışanın bekleyen (düşülmemiş) avanslarını getir
  Future<double> getWorkerPendingAdvances(int workerId) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        ErrorLogger.instance.logWarning(
          'AdvanceService.getWorkerPendingAdvances: userId null',
        );
        return 0.0;
      }

      debugPrint('💰 Bekleyen avanslar hesaplanıyor: workerId=$workerId');

      final result = await supabase.rpc(
        'get_worker_pending_advances',
        params: {'worker_id_param': workerId},
      );

      final pendingAmount = (result as num?)?.toDouble() ?? 0.0;

      debugPrint(
        '✅ Bekleyen avans: ${CurrencyFormatter.formatWithSymbol(pendingAmount)}',
      );
      return pendingAmount;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'AdvanceService.getWorkerPendingAdvances hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return 0.0;
    }
  }

  /// Çalışanın toplam avansını getir
  Future<double> getWorkerTotalAdvances(int workerId) async {
    try {
      debugPrint('💰 Toplam avans hesaplanıyor: workerId=$workerId');

      final result = await supabase.rpc(
        'get_worker_total_advances',
        params: {'worker_id_param': workerId},
      );

      final totalAmount = (result as num?)?.toDouble() ?? 0.0;

      debugPrint(
        '✅ Toplam avans: ${CurrencyFormatter.formatWithSymbol(totalAmount)}',
      );
      return totalAmount;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'AdvanceService.getWorkerTotalAdvances hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return 0.0;
    }
  }

  /// Yeni avans ekle
  Future<Advance> addAdvance(Advance advance) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        ErrorLogger.instance.logError('AdvanceService.addAdvance: userId null');
        throw Exception('Kullanıcı oturumu bulunamadı');
      }

      debugPrint('💰 Yeni avans ekleniyor: ${advance.amount}');

      final advanceMap = advance.copyWith(userId: userId).toMap();
      debugPrint('💰 Avans map: $advanceMap');

      final result = await supabase
          .from('advances')
          .insert(advanceMap)
          .select()
          .single();

      final newAdvance = Advance.fromMap(result);

      debugPrint('✅ Avans başarıyla eklendi (ID: ${newAdvance.id})');

      // Çalışana bildirim gönder
      await _sendAdvanceNotification(newAdvance);

      return newAdvance;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'AdvanceService.addAdvance hatası',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Avans güncelle
  Future<void> updateAdvance(Advance advance) async {
    try {
      if (advance.id == null) {
        throw Exception('Avans ID bulunamadı');
      }

      debugPrint('💰 Avans güncelleniyor: ID=${advance.id}');

      final advanceMap = advance.toMap();
      advanceMap.remove('id'); // ID'yi güncelleme map'inden çıkar

      await supabase.from('advances').update(advanceMap).eq('id', advance.id!);

      debugPrint('✅ Avans başarıyla güncellendi');
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'AdvanceService.updateAdvance hatası',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Avans sil
  Future<void> deleteAdvance(int advanceId) async {
    try {
      debugPrint('💰 Avans siliniyor: ID=$advanceId');

      await supabase.from('advances').delete().eq('id', advanceId);

      debugPrint('✅ Avans başarıyla silindi');
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'AdvanceService.deleteAdvance hatası',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Avansı ödemeden düşülmüş olarak işaretle
  Future<void> markAsDeducted(int advanceId, int paymentId) async {
    try {
      debugPrint(
        '💰 Avans düşülüyor: advanceId=$advanceId, paymentId=$paymentId',
      );

      await supabase
          .from('advances')
          .update({'is_deducted': true, 'deducted_from_payment_id': paymentId})
          .eq('id', advanceId);

      debugPrint('✅ Avans başarıyla düşüldü');
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'AdvanceService.markAsDeducted hatası',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Aylık avans toplamını getir
  Future<double> getMonthlyAdvances(
    DateTime monthStart,
    DateTime monthEnd,
  ) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        ErrorLogger.instance.logWarning(
          'AdvanceService.getMonthlyAdvances: userId null',
        );
        return 0.0;
      }

      debugPrint('💰 Aylık avans hesaplanıyor: $monthStart - $monthEnd');

      final result = await supabase.rpc(
        'get_monthly_advances',
        params: {
          'user_id_param': userId,
          'month_start': DateFormatter.toIso8601Date(monthStart),
          'month_end': DateFormatter.toIso8601Date(monthEnd),
        },
      );

      final monthlyTotal = (result as num?)?.toDouble() ?? 0.0;

      debugPrint(
        '✅ Aylık avans: ${CurrencyFormatter.formatWithSymbol(monthlyTotal)}',
      );
      return monthlyTotal;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'AdvanceService.getMonthlyAdvances hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return 0.0;
    }
  }

  /// Çalışana avans bildirimi gönder
  Future<void> _sendAdvanceNotification(Advance advance) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        ErrorLogger.instance.logWarning(
          'AdvanceService._sendAdvanceNotification: userId null',
        );
        return;
      }

      final message =
          '${CurrencyFormatter.formatWithSymbol(advance.amount)} avans verildi';

      debugPrint('📢 Avans bildirimi gönderiliyor: $message');

      await supabase.from('notifications').insert({
        'sender_id': userId,
        'sender_type': 'user',
        'recipient_id': advance.workerId,
        'recipient_type': 'worker',
        'notification_type': 'general',
        'title': 'Avans Verildi',
        'message': message,
        'related_id': advance.id,
      });

      debugPrint('✅ Avans bildirimi gönderildi');
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'AdvanceService._sendAdvanceNotification hatası',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
