import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

/// Masraf kategorileri enum
enum ExpenseCategory {
  malzeme('malzeme', 'Malzeme'),
  ulasim('ulasim', 'Ulaşım'),
  ekipman('ekipman', 'Ekipman'),
  diger('diger', 'Diğer');

  final String value;
  final String displayName;

  const ExpenseCategory(this.value, this.displayName);

  /// String değerden enum'a dönüştürür
  static ExpenseCategory fromString(String value) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ExpenseCategory.diger,
    );
  }

  /// Tüm kategorilerin display name'lerini döndürür
  static List<String> get displayNames {
    return ExpenseCategory.values.map((e) => e.displayName).toList();
  }
}

/// Masraf model sınıfı
/// İş masraflarını (malzeme, ulaşım vb.) temsil eder
class Expense {
  final int? id;
  final int userId;
  final String expenseType;
  final ExpenseCategory category;
  final double amount;
  final DateTime expenseDate;
  final String? description;
  final String? receiptUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Expense({
    this.id,
    required this.userId,
    required this.expenseType,
    required this.category,
    required this.amount,
    required this.expenseDate,
    this.description,
    this.receiptUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// Veritabanına kaydetmek için Map'e dönüştürür
  Map<String, dynamic> toMap() {
    // Tarihi local timezone'da formatla (Türkiye saati)
    final localDate = DateTime(
      expenseDate.year,
      expenseDate.month,
      expenseDate.day,
    );

    final formattedDate =
        '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';

    debugPrint('Expense toMap - Original date: $expenseDate');
    debugPrint('Expense toMap - Formatted date: $formattedDate');

    final map = {
      'user_id': userId,
      'expense_type': expenseType,
      'category': category.value,
      'amount': amount,
      'expense_date': formattedDate,
    };

    // Opsiyonel alanlar
    if (description != null && description!.isNotEmpty) {
      map['description'] = description!;
    }

    if (receiptUrl != null && receiptUrl!.isNotEmpty) {
      map['receipt_url'] = receiptUrl!;
    }

    // id değeri varsa VE 0'dan büyükse ekle, yoksa Supabase'in otomatik atamasına izin ver
    if (id != null && id! > 0) {
      map['id'] = id!;
    }

    return map;
  }

  /// Veritabanından gelen Map'i Expense nesnesine dönüştürür
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      expenseType: map['expense_type'] as String,
      category: ExpenseCategory.fromString(map['category'] as String),
      amount: (map['amount'] as num).toDouble(),
      expenseDate: DateFormat(
        'yyyy-MM-dd',
      ).parse(map['expense_date'] as String),
      description: map['description'] as String?,
      receiptUrl: map['receipt_url'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Masraf nesnesinin kopyasını oluşturur (immutable pattern)
  Expense copyWith({
    int? id,
    int? userId,
    String? expenseType,
    ExpenseCategory? category,
    double? amount,
    DateTime? expenseDate,
    String? description,
    String? receiptUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      expenseType: expenseType ?? this.expenseType,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      expenseDate: expenseDate ?? this.expenseDate,
      description: description ?? this.description,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Expense(id: $id, type: $expenseType, category: ${category.displayName}, amount: $amount, date: $expenseDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Expense &&
        other.id == id &&
        other.userId == userId &&
        other.expenseType == expenseType &&
        other.category == category &&
        other.amount == amount &&
        other.expenseDate == expenseDate &&
        other.description == description &&
        other.receiptUrl == receiptUrl;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      expenseType,
      category,
      amount,
      expenseDate,
      description,
      receiptUrl,
    );
  }
}
