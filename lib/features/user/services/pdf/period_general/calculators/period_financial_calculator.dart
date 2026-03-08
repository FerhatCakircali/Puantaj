import '../../../../../../models/payment.dart';
import '../../../../../../models/advance.dart';
import '../../../../../../models/expense.dart';

/// Dönem finansal hesaplama sınıfı
///
/// Dönem içindeki ödemeleri, avansları ve masrafları hesaplar
class PeriodFinancialCalculator {
  /// Hesaplama sonuçları
  final double totalPayments;
  final double totalAdvances;
  final double deductedAdvances;
  final double pendingAdvances;
  final double totalExpenses;
  final double totalSpending;

  const PeriodFinancialCalculator({
    required this.totalPayments,
    required this.totalAdvances,
    required this.deductedAdvances,
    required this.pendingAdvances,
    required this.totalExpenses,
    required this.totalSpending,
  });

  /// Dönem için finansal hesaplamaları yapar
  factory PeriodFinancialCalculator.calculate({
    required List<List<Payment>> allPayments,
    required List<List<Advance>> allAdvances,
    required List<Expense> expenses,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) {
    final totalPayments = _calculateTotalPayments(
      allPayments,
      periodStart,
      periodEnd,
    );

    final advanceResults = _calculateAdvances(
      allAdvances,
      periodStart,
      periodEnd,
    );

    final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);

    final totalSpending = totalPayments + advanceResults.total + totalExpenses;

    return PeriodFinancialCalculator(
      totalPayments: totalPayments,
      totalAdvances: advanceResults.total,
      deductedAdvances: advanceResults.deducted,
      pendingAdvances: advanceResults.pending,
      totalExpenses: totalExpenses,
      totalSpending: totalSpending,
    );
  }

  /// Toplam ödemeleri hesaplar
  static double _calculateTotalPayments(
    List<List<Payment>> allPayments,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    double total = 0;
    for (var payments in allPayments) {
      total += payments
          .where((p) => _isInPeriod(p.paymentDate, periodStart, periodEnd))
          .fold<double>(0, (sum, p) => sum + p.amount);
    }
    return total;
  }

  /// Avans hesaplamalarını yapar
  static _AdvanceResults _calculateAdvances(
    List<List<Advance>> allAdvances,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    double total = 0;
    double deducted = 0;
    double pending = 0;

    for (var advances in allAdvances) {
      final periodAdvances = advances
          .where((a) => _isInPeriod(a.advanceDate, periodStart, periodEnd))
          .toList();

      total += periodAdvances.fold<double>(0, (sum, a) => sum + a.amount);
      deducted += periodAdvances
          .where((a) => a.isDeducted)
          .fold<double>(0, (sum, a) => sum + a.amount);
      pending += periodAdvances
          .where((a) => !a.isDeducted)
          .fold<double>(0, (sum, a) => sum + a.amount);
    }

    return _AdvanceResults(total: total, deducted: deducted, pending: pending);
  }

  /// Tarihin dönem içinde olup olmadığını kontrol eder
  static bool _isInPeriod(
    DateTime date,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart = DateTime(
      periodStart.year,
      periodStart.month,
      periodStart.day,
    );
    final normalizedEnd = DateTime(
      periodEnd.year,
      periodEnd.month,
      periodEnd.day,
    );
    return !normalizedDate.isBefore(normalizedStart) &&
        !normalizedDate.isAfter(normalizedEnd);
  }
}

/// Avans hesaplama sonuçları
class _AdvanceResults {
  final double total;
  final double deducted;
  final double pending;

  const _AdvanceResults({
    required this.total,
    required this.deducted,
    required this.pending,
  });
}
