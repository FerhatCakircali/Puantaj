import '../../../../../../models/payment.dart';
import '../../../../../../models/advance.dart';

/// Dönem bazlı filtreleme işlemleri
///
/// Ödeme ve avans kayıtlarını belirtilen dönem aralığına göre filtreler.
class PeriodFilter {
  PeriodFilter._();

  /// Ödemeleri döneme göre filtrele
  static List<Payment> filterPayments(
    List<Payment> payments,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    return payments.where((payment) {
      final paymentDate = _normalizeDate(payment.paymentDate);
      final startDate = _normalizeDate(periodStart);
      final endDate = _normalizeDate(periodEnd);
      return !paymentDate.isBefore(startDate) && !paymentDate.isAfter(endDate);
    }).toList();
  }

  /// Avansları döneme göre filtrele
  static List<Advance> filterAdvances(
    List<Advance> advances,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    return advances.where((advance) {
      final advanceDate = _normalizeDate(advance.advanceDate);
      final startDate = _normalizeDate(periodStart);
      final endDate = _normalizeDate(periodEnd);
      return !advanceDate.isBefore(startDate) && !advanceDate.isAfter(endDate);
    }).toList();
  }

  /// Tarihi normalize et (saat bilgisini sıfırla)
  static DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}
