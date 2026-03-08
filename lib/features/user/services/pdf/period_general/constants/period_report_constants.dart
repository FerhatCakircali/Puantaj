/// Dönem raporu sabitleri
///
/// PDF oluşturma için kullanılan sabit değerler
class PeriodReportConstants {
  PeriodReportConstants._();

  static const double pageMargin = 32.0;
  static const double headerPaddingHorizontal = 20.0;
  static const double headerPaddingVertical = 12.0;
  static const double standardSpacing = 16.0;
  static const double smallSpacing = 8.0;
  static const double tinySpacing = 4.0;
  static const double largeSpacing = 12.0;

  static const double mainTitleFontSize = 14.0;
  static const double sectionTitleFontSize = 16.0;
  static const double labelFontSize = 11.0;
  static const double valueFontSize = 14.0;
  static const double footerFontSize = 9.0;
  static const double periodLabelFontSize = 8.0;
  static const double periodValueFontSize = 11.0;
  static const double statLabelFontSize = 10.0;
  static const double statValueFontSize = 14.0;
  static const double advanceDetailFontSize = 11.0;
  static const double advanceValueFontSize = 12.0;
  static const double totalSpendingLabelFontSize = 11.0;
  static const double totalSpendingValueFontSize = 16.0;

  static const double cardPadding = 14.0;
  static const double advanceCardPadding = 16.0;
  static const double totalSpendingPaddingVertical = 14.0;
  static const double totalSpendingPaddingHorizontal = 18.0;

  static const double borderWidth = 0.5;
  static const double topBorderWidth = 3.0;
  static const double dotSize = 6.0;

  static const double letterSpacing = 1.0;
  static const double totalSpendingLetterSpacing = 1.2;

  static const String reportTitle = 'GENEL DÖNEM RAPORU';
  static const String periodLabel = 'RAPOR DÖNEMİ';
  static const String financialSummaryTitle = 'FİNANSAL ÖZET';
  static const String employeeLabel = 'Çalışan';
  static const String paymentsLabel = 'Ödemeler';
  static const String advancesLabel = 'Avanslar';
  static const String expensesLabel = 'Masraflar';
  static const String deductedAdvanceLabel = 'Düşülmüş Avans';
  static const String pendingAdvanceLabel = 'Bekleyen Avans';
  static const String totalSpendingLabel = 'TOPLAM GİDER';
  static const String reportDateLabel = 'Rapor Oluşturma Tarihi';
  static const String pageLabel = 'Sayfa';
}
