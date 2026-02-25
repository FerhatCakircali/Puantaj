/// Helper fonksiyonlar - EditPaymentDialog
class EditPaymentDialogHelpers {
  /// Tutarı görüntüleme formatına çevirir (binlik ayırıcı ile)
  static String formatAmountForDisplay(int amount) {
    final str = amount.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }

    return buffer.toString();
  }
}
