import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

/// Avans model sınıfı
/// Çalışanlara verilen avansları temsil eder
class Advance {
  final int? id;
  final int userId;
  final int workerId;
  final double amount;
  final DateTime advanceDate;
  final String? description;
  final bool isDeducted;
  final int? deductedFromPaymentId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Advance({
    this.id,
    required this.userId,
    required this.workerId,
    required this.amount,
    required this.advanceDate,
    this.description,
    this.isDeducted = false,
    this.deductedFromPaymentId,
    this.createdAt,
    this.updatedAt,
  });

  /// Veritabanına kaydetmek için Map'e dönüştürür
  Map<String, dynamic> toMap() {
    // Tarihi local timezone'da formatla (Türkiye saati)
    final localDate = DateTime(
      advanceDate.year,
      advanceDate.month,
      advanceDate.day,
    );

    final formattedDate =
        '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';

    debugPrint('📅 Advance toMap - Original date: $advanceDate');
    debugPrint('📅 Advance toMap - Formatted date: $formattedDate');

    final map = {
      'user_id': userId,
      'worker_id': workerId,
      'amount': amount,
      'advance_date': formattedDate,
      'is_deducted': isDeducted,
    };

    // Opsiyonel alanlar
    if (description != null && description!.isNotEmpty) {
      map['description'] = description!;
    }

    if (deductedFromPaymentId != null) {
      map['deducted_from_payment_id'] = deductedFromPaymentId!;
    }

    // id değeri varsa VE 0'dan büyükse ekle, yoksa Supabase'in otomatik atamasına izin ver
    if (id != null && id! > 0) {
      map['id'] = id!;
    }

    return map;
  }

  /// Veritabanından gelen Map'i Advance nesnesine dönüştürür
  factory Advance.fromMap(Map<String, dynamic> map) {
    return Advance(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      workerId: map['worker_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      advanceDate: DateFormat(
        'yyyy-MM-dd',
      ).parse(map['advance_date'] as String),
      description: map['description'] as String?,
      isDeducted: map['is_deducted'] as bool? ?? false,
      deductedFromPaymentId: map['deducted_from_payment_id'] as int?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Avans nesnesinin kopyasını oluşturur (immutable pattern)
  Advance copyWith({
    int? id,
    int? userId,
    int? workerId,
    double? amount,
    DateTime? advanceDate,
    String? description,
    bool? isDeducted,
    int? deductedFromPaymentId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Advance(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workerId: workerId ?? this.workerId,
      amount: amount ?? this.amount,
      advanceDate: advanceDate ?? this.advanceDate,
      description: description ?? this.description,
      isDeducted: isDeducted ?? this.isDeducted,
      deductedFromPaymentId:
          deductedFromPaymentId ?? this.deductedFromPaymentId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Advance(id: $id, workerId: $workerId, amount: $amount, date: $advanceDate, isDeducted: $isDeducted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Advance &&
        other.id == id &&
        other.userId == userId &&
        other.workerId == workerId &&
        other.amount == amount &&
        other.advanceDate == advanceDate &&
        other.description == description &&
        other.isDeducted == isDeducted &&
        other.deductedFromPaymentId == deductedFromPaymentId;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      workerId,
      amount,
      advanceDate,
      description,
      isDeducted,
      deductedFromPaymentId,
    );
  }
}
