import 'package:intl/intl.dart';

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
    final map = {
      'user_id': userId,
      'worker_id': workerId,
      'full_days': fullDays,
      'half_days': halfDays,
      'payment_date': DateFormat('yyyy-MM-dd').format(paymentDate),
      'amount': amount,
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
}
