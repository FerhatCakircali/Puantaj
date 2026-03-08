/// Devam oranı hesaplama sınıfı
///
/// Aylık devam istatistiklerinden devam oranını hesaplar.
class AttendanceRateCalculator {
  /// Devam oranını hesaplar
  ///
  /// Tam günler 1.0, yarım günler 0.5 olarak hesaplanır.
  static double calculate(Map<String, dynamic> monthlyStats) {
    final fullDays = monthlyStats['total_full_days'] ?? 0;
    final halfDays = monthlyStats['total_half_days'] ?? 0;
    final absentDays = monthlyStats['total_absent_days'] ?? 0;

    final totalDays = fullDays + halfDays + absentDays;
    if (totalDays == 0) return 0.0;

    return (fullDays + halfDays * 0.5) / totalDays * 100;
  }
}
