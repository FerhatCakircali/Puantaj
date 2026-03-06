import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class Payment {
  final int? id;
  final int userId;
  final int workerId;
  final int fullDays;
  final int halfDays;
  final DateTime paymentDate;
  final double amount;

  Payment({
    this.id,
    required this.userId,
    required this.workerId,
    required this.fullDays,
    required this.halfDays,
    required this.paymentDate,
    this.amount = 0.0,
  });

  // PDF için getter, daha sonra silinen çalışan raporları için
  DateTime get date => paymentDate;

  Map<String, dynamic> toMap() {
    // Tarihi local timezone'da formatla (Türkiye saati)
    // DateTime.now() zaten cihazın local timezone'unda
    // Sadece tarih kısmını al
    final localDate = DateTime(
      paymentDate.year,
      paymentDate.month,
      paymentDate.day,
    );

    final formattedDate =
        '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';

    debugPrint('📅 Payment toMap - Original date: $paymentDate');
    debugPrint('📅 Payment toMap - Formatted date: $formattedDate');

    final map = {
      'user_id': userId,
      'worker_id': workerId,
      'full_days': fullDays,
      'half_days': halfDays,
      'payment_date': formattedDate,
      'amount': amount,
      // ⚡ FIX: 'notes' kolonu database'de yok, kaldırıldı
    };

    // id değeri varsa ekle, yoksa Supabase'in otomatik atamasına izin ver
    if (id != null) {
      map['id'] = id as int;
    }

    return map;
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int,
      userId: map['user_id'] as int,
      workerId: map['worker_id'] as int,
      fullDays: map['full_days'] as int,
      halfDays: map['half_days'] as int,
      paymentDate: DateFormat(
        'yyyy-MM-dd',
      ).parse(map['payment_date'] as String),
      amount: map['amount'] != null ? (map['amount'] as num).toDouble() : 0.0,
    );
  }

  /// Payment kopyasını oluşturur (immutable pattern)
  Payment copyWith({
    int? id,
    int? userId,
    int? workerId,
    int? fullDays,
    int? halfDays,
    DateTime? paymentDate,
    double? amount,
  }) {
    return Payment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workerId: workerId ?? this.workerId,
      fullDays: fullDays ?? this.fullDays,
      halfDays: halfDays ?? this.halfDays,
      paymentDate: paymentDate ?? this.paymentDate,
      amount: amount ?? this.amount,
    );
  }
}
