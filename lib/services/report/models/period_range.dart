/// Rapor dönemi aralığı modeli
class PeriodRange {
  final DateTime startDate;
  final DateTime endDate;
  final String title;

  PeriodRange({
    required this.startDate,
    required this.endDate,
    required this.title,
  });
}

/// Rapor dönem tipleri
enum ReportPeriod { daily, weekly, monthly, quarterly, yearly, custom }
