/// Ödeme özet bilgilerini içeren model
/// RPC fonksiyonu `get_payment_summary` tarafından döndürülen
/// veri yapısını temsil eder. N+1 query problemini çözmek için
/// payments ve workers tablolarını tek sorguda birleştirir.
/// Saat Dilimi: Europe/Istanbul (UTC+3)
class PaymentSummary {
  /// Toplam ödeme sayısı
  final int totalPayments;

  /// Toplam ödeme tutarı
  final double totalAmount;

  /// Toplam avans sayısı
  final int totalAdvances;

  /// Toplam avans tutarı
  final double totalAdvanceAmount;

  /// Toplam maaş ödemesi sayısı
  final int totalSalaries;

  /// Toplam maaş tutarı
  final double totalSalaryAmount;

  /// Ödeme alan benzersiz çalışan sayısı
  final int uniqueWorkers;

  /// Ortalama ödeme tutarı
  final double avgPaymentAmount;

  PaymentSummary({
    required this.totalPayments,
    required this.totalAmount,
    required this.totalAdvances,
    required this.totalAdvanceAmount,
    required this.totalSalaries,
    required this.totalSalaryAmount,
    required this.uniqueWorkers,
    required this.avgPaymentAmount,
  });

  /// RPC fonksiyonundan dönen map'i model nesnesine dönüştürür
  factory PaymentSummary.fromMap(Map<String, dynamic> map) {
    return PaymentSummary(
      totalPayments: map['total_payments'] as int,
      totalAmount: (map['total_amount'] as num).toDouble(),
      totalAdvances: map['total_advances'] as int,
      totalAdvanceAmount: (map['total_advance_amount'] as num).toDouble(),
      totalSalaries: map['total_salaries'] as int,
      totalSalaryAmount: (map['total_salary_amount'] as num).toDouble(),
      uniqueWorkers: map['unique_workers'] as int,
      avgPaymentAmount: (map['avg_payment_amount'] as num).toDouble(),
    );
  }

  /// Model nesnesini map'e dönüştürür
  Map<String, dynamic> toMap() {
    return {
      'total_payments': totalPayments,
      'total_amount': totalAmount,
      'total_advances': totalAdvances,
      'total_advance_amount': totalAdvanceAmount,
      'total_salaries': totalSalaries,
      'total_salary_amount': totalSalaryAmount,
      'unique_workers': uniqueWorkers,
      'avg_payment_amount': avgPaymentAmount,
    };
  }

  @override
  String toString() {
    return 'PaymentSummary(totalPayments: $totalPayments, totalAmount: $totalAmount, '
        'totalAdvances: $totalAdvances, totalAdvanceAmount: $totalAdvanceAmount, '
        'totalSalaries: $totalSalaries, totalSalaryAmount: $totalSalaryAmount, '
        'uniqueWorkers: $uniqueWorkers, avgPaymentAmount: $avgPaymentAmount)';
  }
}
