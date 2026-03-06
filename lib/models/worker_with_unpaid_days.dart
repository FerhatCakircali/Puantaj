/// İşçi ve ödenmemiş gün bilgilerini içeren model
/// RPC fonksiyonu `get_workers_with_unpaid_days` tarafından döndürülen
/// veri yapısını temsil eder. N+1 query problemini çözmek için
/// workers, attendance ve paid_days tablolarını tek sorguda birleştirir.
/// Saat Dilimi: Europe/Istanbul (UTC+3)
class WorkerWithUnpaidDays {
  /// İşçi ID'si
  final int workerId;

  /// İşçinin tam adı
  final String fullName;

  /// İşçinin ünvanı/görevi
  final String? title;

  /// İşe başlama tarihi
  final String startDate;

  /// Ödenmemiş tam gün sayısı
  final int unpaidFullDays;

  /// Ödenmemiş yarım gün sayısı
  final int unpaidHalfDays;

  /// Toplam ödenmemiş gün sayısı (tam + yarım*0.5)
  final double totalUnpaidDays;

  WorkerWithUnpaidDays({
    required this.workerId,
    required this.fullName,
    this.title,
    required this.startDate,
    required this.unpaidFullDays,
    required this.unpaidHalfDays,
    required this.totalUnpaidDays,
  });

  /// RPC fonksiyonundan dönen map'i model nesnesine dönüştürür
  factory WorkerWithUnpaidDays.fromMap(Map<String, dynamic> map) {
    return WorkerWithUnpaidDays(
      workerId: map['worker_id'] as int,
      fullName: map['full_name'] as String,
      title: map['title'] as String?,
      startDate: map['start_date'] as String,
      unpaidFullDays: map['unpaid_full_days'] as int,
      unpaidHalfDays: map['unpaid_half_days'] as int,
      totalUnpaidDays: (map['total_unpaid_days'] as num).toDouble(),
    );
  }

  /// Model nesnesini map'e dönüştürür
  Map<String, dynamic> toMap() {
    return {
      'worker_id': workerId,
      'full_name': fullName,
      'title': title,
      'start_date': startDate,
      'unpaid_full_days': unpaidFullDays,
      'unpaid_half_days': unpaidHalfDays,
      'total_unpaid_days': totalUnpaidDays,
    };
  }

  @override
  String toString() {
    return 'WorkerWithUnpaidDays(workerId: $workerId, fullName: $fullName, '
        'unpaidFullDays: $unpaidFullDays, unpaidHalfDays: $unpaidHalfDays, '
        'totalUnpaidDays: $totalUnpaidDays)';
  }
}
