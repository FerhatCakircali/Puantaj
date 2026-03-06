import '../models/payment.dart';
import 'auth_service.dart';
import '../models/attendance.dart';
import '../core/app_globals.dart';
import '../utils/date_formatter.dart';
import '../utils/currency_formatter.dart';
import '../core/error_logger.dart';
import 'package:flutter/foundation.dart';

class PaymentService {
  final _authService = AuthService();

  Future<int?> addPayment(Payment payment) async {
    try {
      debugPrint(
        '💰 Yeni ödeme ekleniyor: Tarih=${payment.paymentDate}, Tutar=${payment.amount}',
      );

      // Ödeme kaydını ekle
      final paymentMap = payment.toMap();
      debugPrint('💰 Ödeme map: $paymentMap');

      final paymentResponse = await supabase
          .from('payments')
          .insert(paymentMap)
          .select('id, payment_date')
          .single();

      debugPrint('💰 Veritabanına kaydedilen: $paymentResponse');

      final paymentId = paymentResponse['id'] as int;

      // Ödeme yapılan çalışan için henüz ödenmemiş günleri al
      final attendance = await _getUnpaidAttendanceForWorker(payment.workerId);

      debugPrint('💰 Ödenmemiş gün sayısı: ${attendance.length}');

      // Ödenecek tam ve yarım günlerin sayısı
      int fullDaysToMark = payment.fullDays;
      int halfDaysToMark = payment.halfDays;

      // Hangi günlerin ödendiğini kaydet
      for (var record in attendance) {
        if (record.status == AttendanceStatus.fullDay && fullDaysToMark > 0) {
          // Bu tam günü ödenmiş olarak işaretle
          await _markDayAsPaid(record, paymentId);
          fullDaysToMark--;
          debugPrint('💰 Tam gün işaretlendi: ${record.date}');
        } else if (record.status == AttendanceStatus.halfDay &&
            halfDaysToMark > 0) {
          // Bu yarım günü ödenmiş olarak işaretle
          await _markDayAsPaid(record, paymentId);
          halfDaysToMark--;
          debugPrint('💰 Yarım gün işaretlendi: ${record.date}');
        }

        // Tüm günler işaretlendiyse döngüden çık
        if (fullDaysToMark <= 0 && halfDaysToMark <= 0) break;
      }

      debugPrint('✅ Ödeme başarıyla tamamlandı (ID: $paymentId)');

      // ⚡ YENİ: Çalışana ödeme bildirimi gönder
      await _sendPaymentNotification(payment);

      // Payment ID'yi döndür
      return paymentId;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'PaymentService.addPayment hatası',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow; // Hatayı yukarı fırlat ki dialog'da yakalansın
    }
  }

  /// Çalışana ödeme bildirimi gönder
  Future<void> _sendPaymentNotification(Payment payment) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return;

      // Bildirim mesajı oluştur
      final message =
          '${payment.fullDays} Tam Gün, ${payment.halfDays} Yarım Gün - Toplam ${CurrencyFormatter.formatWithSymbol(payment.amount)} ödendi';

      debugPrint('📢 Ödeme bildirimi gönderiliyor: $message');

      // Bildirim ekle
      await supabase.from('notifications').insert({
        'sender_id': userId,
        'sender_type': 'user',
        'recipient_id': payment.workerId,
        'recipient_type': 'worker',
        'notification_type': 'payment_received',
        'title': 'Ödeme Yapıldı',
        'message': message,
        'related_id': payment.workerId,
        'scheduled_time': null,
      });

      debugPrint('✅ Ödeme bildirimi gönderildi');
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'PaymentService._sendPaymentNotification hatası',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _markDayAsPaid(Attendance record, int paymentId) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        ErrorLogger.instance.logWarning(
          'PaymentService._markDayAsPaid: userId null',
        );
        return;
      }

      await supabase.from('paid_days').insert({
        'user_id': userId,
        'worker_id': record.workerId,
        'date': DateFormatter.toIso8601Date(record.date),
        'status': record.status == AttendanceStatus.fullDay
            ? 'fullDay'
            : 'halfDay',
        'payment_id': paymentId,
      });
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'PaymentService._markDayAsPaid hatası',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<Attendance>> _getUnpaidAttendanceForWorker(int workerId) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        ErrorLogger.instance.logWarning(
          'PaymentService._getUnpaidAttendanceForWorker: userId null',
        );
        return [];
      }

      final allAttendanceResults = await supabase
          .from('attendance')
          .select()
          .eq('worker_id', workerId)
          .eq('user_id', userId)
          .or('status.eq.fullDay,status.eq.halfDay')
          .order('date');

      final paidDaysResults = await supabase
          .from('paid_days')
          .select('date, status')
          .eq('worker_id', workerId)
          .eq('user_id', userId);

      final paidDays = paidDaysResults
          .map(
            (row) => {
              'date': row['date'] as String,
              'status': row['status'] as String,
            },
          )
          .toList();

      final unpaidAttendance = allAttendanceResults
          .where((record) {
            final recordDate = DateFormatter.toIso8601Date(
              DateTime.parse(record['date'] as String),
            );
            final recordStatus = record['status'] as String;

            return !paidDays.any(
              (paidDay) =>
                  paidDay['date'] == recordDate &&
                  paidDay['status'] == recordStatus,
            );
          })
          .map((map) => Attendance.fromMap(map))
          .toList();

      return unpaidAttendance;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'PaymentService._getUnpaidAttendanceForWorker hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  Future<List<Payment>> getPaymentsByWorker(int workerId) async {
    try {
      final currentUser = await _authService.currentUser;
      if (currentUser == null) {
        ErrorLogger.instance.logWarning(
          'PaymentService.getPaymentsByWorker: currentUser null',
        );
        return [];
      }

      final maps = await supabase
          .from('payments')
          .select()
          .eq('worker_id', workerId)
          .eq('user_id', currentUser['id']);

      return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'PaymentService.getPaymentsByWorker hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  Future<List<Payment>> getPaymentsByWorkerId(int workerId) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        ErrorLogger.instance.logWarning(
          'PaymentService.getPaymentsByWorkerId: userId null',
        );
        return [];
      }

      final maps = await supabase
          .from('payments')
          .select()
          .eq('worker_id', workerId)
          .eq('user_id', userId)
          .order('payment_date', ascending: false);

      return List.generate(maps.length, (i) => Payment.fromMap(maps[i]));
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'PaymentService.getPaymentsByWorkerId hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  Future<Map<String, int>> getUnpaidDays(int workerId) async {
    try {
      final unpaidAttendance = await _getUnpaidAttendanceForWorker(workerId);

      int fullDays = 0;
      int halfDays = 0;

      for (var record in unpaidAttendance) {
        if (record.status == AttendanceStatus.fullDay) {
          fullDays++;
        } else if (record.status == AttendanceStatus.halfDay) {
          halfDays++;
        }
      }

      return {'fullDays': fullDays, 'halfDays': halfDays};
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'PaymentService.getUnpaidDays hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return {'fullDays': 0, 'halfDays': 0};
    }
  }

  /// Belirli bir ödemeyi hariç tutarak ödenmemiş günleri getir
  ///
  /// Ödeme düzenlenirken kullanılır. Düzenlenen ödemenin günlerini
  /// ödenmemiş günlere ekleyerek maksimum değeri hesaplar.
  Future<Map<String, int>> getUnpaidDaysExcludingPayment(
    int workerId,
    int excludePaymentId,
  ) async {
    final userId = await _authService.getUserId();
    if (userId == null) return {'fullDays': 0, 'halfDays': 0};

    // Tüm yevmiye kayıtlarını al
    final allAttendanceResults = await supabase
        .from('attendance')
        .select()
        .eq('worker_id', workerId)
        .eq('user_id', userId)
        .or('status.eq.fullDay,status.eq.halfDay')
        .order('date');

    // Belirli ödeme hariç tüm ödenmiş günleri al
    final paidDaysResults = await supabase
        .from('paid_days')
        .select('date, status')
        .eq('worker_id', workerId)
        .eq('user_id', userId)
        .neq('payment_id', excludePaymentId); // Bu ödemeyi hariç tut

    final paidDays = paidDaysResults
        .map(
          (row) => {
            'date': row['date'] as String,
            'status': row['status'] as String,
          },
        )
        .toList();

    debugPrint(
      '🔍 [getUnpaidDaysExcludingPayment] excludePaymentId: $excludePaymentId',
    );
    debugPrint('🔍 Toplam yevmiye: ${allAttendanceResults.length}');
    debugPrint(
      '🔍 Ödenmiş günler (excludePaymentId hariç): ${paidDays.length}',
    );

    // Ödenmemiş günleri filtrele
    final unpaidAttendance = allAttendanceResults.where((record) {
      final recordDate = DateFormatter.toIso8601Date(
        DateTime.parse(record['date'] as String),
      );
      final recordStatus = record['status'] as String;

      return !paidDays.any(
        (paidDay) =>
            paidDay['date'] == recordDate && paidDay['status'] == recordStatus,
      );
    }).toList();

    int fullDays = 0;
    int halfDays = 0;

    for (var record in unpaidAttendance) {
      final status = record['status'] as String;
      if (status == 'fullDay') {
        fullDays++;
      } else if (status == 'halfDay') {
        halfDays++;
      }
    }

    debugPrint(
      '🔍 Ödenmemiş günler (düzenlenen ödeme dahil): $fullDays Tam, $halfDays Yarım',
    );

    return {'fullDays': fullDays, 'halfDays': halfDays};
  }

  Future<bool> isDayPaid(
    int workerId,
    DateTime date,
    AttendanceStatus status,
  ) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) {
        ErrorLogger.instance.logWarning(
          'PaymentService.isDayPaid: userId null',
        );
        return false;
      }

      final formattedDate = DateFormatter.toIso8601Date(date);
      final statusStr = status == AttendanceStatus.fullDay
          ? 'fullDay'
          : 'halfDay';

      final results = await supabase
          .from('paid_days')
          .select()
          .eq('worker_id', workerId)
          .eq('user_id', userId)
          .eq('date', formattedDate)
          .eq('status', statusStr);

      return results.isNotEmpty;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'PaymentService.isDayPaid hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Ödeme kaydını güncelle ve çalışana bildirim gönder
  Future<bool> updatePayment({
    required int paymentId,
    required int fullDays,
    required int halfDays,
    required double amount,
  }) async {
    try {
      debugPrint('💰 Ödeme güncelleniyor: ID=$paymentId');

      final result = await supabase.rpc(
        'update_payment',
        params: {
          'payment_id_param': paymentId,
          'full_days_param': fullDays,
          'half_days_param': halfDays,
          'amount_param': amount,
        },
      );

      if (result == true) {
        debugPrint('✅ Ödeme başarıyla güncellendi');
        return true;
      } else {
        debugPrint('❌ Ödeme güncellenemedi');
        return false;
      }
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'PaymentService.updatePayment hatası',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Ödeme kaydını sil ve çalışana bildirim gönder
  Future<bool> deletePayment(int paymentId) async {
    try {
      debugPrint('💰 Ödeme siliniyor: ID=$paymentId');

      final result = await supabase.rpc(
        'delete_payment',
        params: {'payment_id_param': paymentId},
      );

      if (result == true) {
        debugPrint('✅ Ödeme başarıyla silindi');
        return true;
      } else {
        debugPrint('❌ Ödeme silinemedi');
        return false;
      }
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'PaymentService.deletePayment hatası',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Kullanıcının (yöneticinin) tüm ödemelerini ve avanslarını getir
  Future<List<Map<String, dynamic>>> getUserPaymentHistory({
    required DateTime startDate,
    required DateTime endDate,
    String? workerNameFilter,
  }) async {
    try {
      final userId = await _authService.getUserId();
      if (userId == null) return [];

      debugPrint('💰 Ödeme geçmişi getiriliyor: $startDate - $endDate');

      // Ödemeleri getir
      var paymentsQuery = supabase
          .from('payments')
          .select('*, workers!inner(full_name)')
          .eq('user_id', userId)
          .gte('payment_date', DateFormatter.toIso8601Date(startDate))
          .lte('payment_date', DateFormatter.toIso8601Date(endDate));

      final paymentsResults = await paymentsQuery;

      // Avansları getir
      var advancesQuery = supabase
          .from('advances')
          .select('*, workers!inner(full_name)')
          .eq('user_id', userId)
          .gte('advance_date', DateFormatter.toIso8601Date(startDate))
          .lte('advance_date', DateFormatter.toIso8601Date(endDate));

      final advancesResults = await advancesQuery;

      // Avansları ödeme formatına dönüştür
      final advancesAsPayments = advancesResults.map((advance) {
        return {
          'id': advance['id'],
          'user_id': advance['user_id'],
          'worker_id': advance['worker_id'],
          'amount': advance['amount'],
          'payment_date': advance['advance_date'],
          'created_at': advance['created_at'],
          'updated_at': advance['updated_at'],
          'workers': advance['workers'],
          'full_days': 0, // Avanslar için gün bilgisi yok
          'half_days': 0,
          'is_advance': true, // Avans olduğunu belirtmek için
          'description': advance['description'],
        };
      }).toList();

      // Ödemelere avans bayrağı ekle
      final paymentsWithFlag = paymentsResults.map((payment) {
        return {...payment, 'is_advance': false};
      }).toList();

      // İki listeyi birleştir
      final combined = [...paymentsWithFlag, ...advancesAsPayments];

      // Tarihe göre sırala (en yeni en üstte)
      combined.sort((a, b) {
        final dateA = DateTime.parse(a['payment_date'] as String);
        final dateB = DateTime.parse(b['payment_date'] as String);
        return dateB.compareTo(dateA);
      });

      // Filtre uygula
      if (workerNameFilter != null && workerNameFilter.isNotEmpty) {
        final filtered = combined.where((item) {
          final workerName = item['workers']['full_name'] as String;
          return workerName.toLowerCase().contains(
            workerNameFilter.toLowerCase(),
          );
        }).toList();

        debugPrint('✅ Filtrelenmiş kayıt sayısı: ${filtered.length}');
        return filtered;
      }

      debugPrint(
        '✅ Ödeme geçmişi getirildi: ${combined.length} kayıt (${paymentsResults.length} ödeme, ${advancesResults.length} avans)',
      );
      return combined;
    } catch (e, stackTrace) {
      ErrorLogger.instance.logError(
        'PaymentService.getUserPaymentHistory hatası',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }
}
