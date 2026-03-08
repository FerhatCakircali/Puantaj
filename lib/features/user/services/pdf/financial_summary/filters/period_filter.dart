import '../../../../../../models/payment.dart';
import '../../../../../../models/advance.dart';
import '../../../../../../models/expense.dart';

/// Dönem bazlı filtreleme işlemleri
class PeriodFilter {
  /// Ödemeleri döneme göre filtreler
  List<Payment> filterPayments(
    List<Payment> payments,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    return payments.where((payment) {
      final paymentDate = DateTime(
        payment.paymentDate.year,
        payment.paymentDate.month,
        payment.paymentDate.day,
      );
      final startDate = DateTime(
        periodStart.year,
        periodStart.month,
        periodStart.day,
      );
      final endDate = DateTime(periodEnd.year, periodEnd.month, periodEnd.day);
      return !paymentDate.isBefore(startDate) && !paymentDate.isAfter(endDate);
    }).toList();
  }

  /// Avansları döneme göre filtreler
  List<Advance> filterAdvances(
    List<Advance> advances,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    return advances.where((advance) {
      final advanceDate = DateTime(
        advance.advanceDate.year,
        advance.advanceDate.month,
        advance.advanceDate.day,
      );
      final startDate = DateTime(
        periodStart.year,
        periodStart.month,
        periodStart.day,
      );
      final endDate = DateTime(periodEnd.year, periodEnd.month, periodEnd.day);
      return !advanceDate.isBefore(startDate) && !advanceDate.isAfter(endDate);
    }).toList();
  }

  /// Masrafları döneme göre filtreler
  List<Expense> filterExpenses(
    List<Expense> expenses,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    return expenses.where((expense) {
      final expenseDate = DateTime(
        expense.expenseDate.year,
        expense.expenseDate.month,
        expense.expenseDate.day,
      );
      final startDate = DateTime(
        periodStart.year,
        periodStart.month,
        periodStart.day,
      );
      final endDate = DateTime(periodEnd.year, periodEnd.month, periodEnd.day);
      return !expenseDate.isBefore(startDate) && !expenseDate.isAfter(endDate);
    }).toList();
  }
}
