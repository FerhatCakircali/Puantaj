import 'package:flutter/foundation.dart';
import '../models/advance.dart';
import '../core/app_globals.dart';
import 'auth_service.dart';

/// Avans yönetimi servisi
/// Çalışanlara verilen avansların CRUD işlemlerini yönetir
class AdvanceService {
  final _authService = AuthService();

  /// Tarih formatı helper
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Tutarı binlik ayırıcı ile formatla (₺600.234)
  String _formatAmount(double amount) {
    final intAmount = amount.toInt();
    final str = intAmount.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }

    return buffer.toString();
  }

  /// Yöneticinin tüm avanslarını getir
  Future<List<Advance>> getAdvances() async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return [];

      debugPrint('💰 Avanslar getiriliyor...');

      final results = await supabase
          .from('advances')
          .select()
          .eq('user_id', userId)
          .order('advance_date', ascending: false);

      final advances = results.map((map) => Advance.fromMap(map)).toList();

      debugPrint('✅ ${advances.length} avans getirildi');
      return advances;
    } catch (e) {
      debugPrint('❌ Avans getirme hatası: $e');
      return [];
    }
  }

  /// Belirli bir çalışanın avanslarını getir
  Future<List<Advance>> getWorkerAdvances(int workerId) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return [];

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
    } catch (e) {
      debugPrint('❌ Çalışan avansları getirme hatası: $e');
      return [];
    }
  }

  /// Çalışanın bekleyen (düşülmemiş) avanslarını getir
  Future<double> getWorkerPendingAdvances(int workerId) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return 0.0;

      debugPrint('💰 Bekleyen avanslar hesaplanıyor: workerId=$workerId');

      final result = await supabase.rpc(
        'get_worker_pending_advances',
        params: {'worker_id_param': workerId},
      );

      final pendingAmount = (result as num?)?.toDouble() ?? 0.0;

      debugPrint('✅ Bekleyen avans: ₺${_formatAmount(pendingAmount)}');
      return pendingAmount;
    } catch (e) {
      debugPrint('❌ Bekleyen avans hesaplama hatası: $e');
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

      debugPrint('✅ Toplam avans: ₺${_formatAmount(totalAmount)}');
      return totalAmount;
    } catch (e) {
      debugPrint('❌ Toplam avans hesaplama hatası: $e');
      return 0.0;
    }
  }

  /// Yeni avans ekle
  Future<Advance> addAdvance(Advance advance) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
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
      debugPrint('❌ Avans ekleme hatası: $e');
      debugPrint('Stack trace: $stackTrace');
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
    } catch (e) {
      debugPrint('❌ Avans güncelleme hatası: $e');
      rethrow;
    }
  }

  /// Avans sil
  Future<void> deleteAdvance(int advanceId) async {
    try {
      debugPrint('💰 Avans siliniyor: ID=$advanceId');

      await supabase.from('advances').delete().eq('id', advanceId);

      debugPrint('✅ Avans başarıyla silindi');
    } catch (e) {
      debugPrint('❌ Avans silme hatası: $e');
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
    } catch (e) {
      debugPrint('❌ Avans düşme hatası: $e');
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
      if (userId == null) return 0.0;

      debugPrint('💰 Aylık avans hesaplanıyor: $monthStart - $monthEnd');

      final result = await supabase.rpc(
        'get_monthly_advances',
        params: {
          'user_id_param': userId,
          'month_start': _formatDate(monthStart),
          'month_end': _formatDate(monthEnd),
        },
      );

      final monthlyTotal = (result as num?)?.toDouble() ?? 0.0;

      debugPrint('✅ Aylık avans: ₺${_formatAmount(monthlyTotal)}');
      return monthlyTotal;
    } catch (e) {
      debugPrint('❌ Aylık avans hesaplama hatası: $e');
      return 0.0;
    }
  }

  /// Çalışana avans bildirimi gönder
  Future<void> _sendAdvanceNotification(Advance advance) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return;

      final message = '₺${_formatAmount(advance.amount)} avans verildi';

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
    } catch (e) {
      debugPrint('⚠️ Avans bildirimi gönderilemedi: $e');
    }
  }
}
