/// Çalışan raporu sabitleri
///
/// PDF oluşturma için kullanılan sabit değerler
class EmployeeReportConstants {
  EmployeeReportConstants._();

  static const double statBoxPadding = 12.0;
  static const double cardSpacing = 12.0;
  static const double sectionSpacing = 16.0;
  static const double iconSpacing = 8.0;
  static const double smallSpacing = 4.0;

  static const double statValueFontSize = 20.0;
  static const double headerFontSize = 10.0;

  static const String attendanceSummaryTitle = 'DEVAM KAYITLARI ÖZETİ';
  static const String paymentInfoTitle = 'ÖDEME BİLGİLERİ';
  static const String advanceInfoTitle = 'AVANS BİLGİLERİ';

  static const String fullDayLabel = 'Tam Gün';
  static const String halfDayLabel = 'Yarım Gün';
  static const String totalLabel = 'Toplam';
  static const String absentLabel = 'Devamsız';
  static const String totalPaidLabel = 'Toplam Ödenen';
  static const String paidDaysLabel = 'Ödenen Gün';
  static const String unpaidDaysLabel = 'Ödenmeyen Gün';
  static const String totalAdvanceLabel = 'Toplam Avans';
  static const String deductedLabel = 'Düşülmüş';
  static const String pendingLabel = 'Bekleyen';

  static const String noPaymentMessage = 'Henüz ödeme yapılmadı.';
  static const String noAdvanceMessage = 'Avans kaydı bulunmamaktadır.';
  static const String noPeriodAdvanceMessage =
      'Bu dönemde avans kaydı bulunmamaktadır.';

  static const String dateHeader = 'Tarih';
  static const String fullDayHeader = 'Tam Gün';
  static const String halfDayHeader = 'Yarım Gün';
  static const String paymentHeader = 'Ödeme';
  static const String amountHeader = 'Tutar';
  static const String statusHeader = 'Durum';
  static const String descriptionHeader = 'Açıklama';

  static const String deductedStatus = 'Düşüldü';
  static const String pendingStatus = 'Bekliyor';
  static const String noDescription = '-';

  static const String evaluationPrefix = 'Değerlendirme: ';
}
