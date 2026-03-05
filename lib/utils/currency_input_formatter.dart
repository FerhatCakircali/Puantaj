import 'package:flutter/services.dart';

/// Türk Lirası formatında tutar girişi için formatter
/// Yazarken otomatik olarak binlik ayırıcı (.) ekler
/// Örnek: 123456 -> 123.456
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Boşsa veya sadece nokta varsa olduğu gibi dön
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Sadece rakamları al (noktaları temizle)
    final digitsOnly = newValue.text.replaceAll('.', '');

    // Rakam değilse eski değeri dön
    if (int.tryParse(digitsOnly) == null) {
      return oldValue;
    }

    // Binlik ayırıcı ekle
    final formatted = _formatWithThousandsSeparator(digitsOnly);

    // Cursor pozisyonunu hesapla
    int cursorPosition = newValue.selection.end;

    // Eski metindeki nokta sayısı
    final oldDots =
        oldValue.text.substring(0, oldValue.selection.end).split('.').length -
        1;

    // Yeni metindeki nokta sayısı
    final newDots =
        formatted
            .substring(0, cursorPosition.clamp(0, formatted.length))
            .split('.')
            .length -
        1;

    // Nokta farkı kadar cursor'u kaydır
    cursorPosition += (newDots - oldDots);

    // Eğer metin uzunluğu değiştiyse cursor'u ayarla
    if (formatted.length < cursorPosition) {
      cursorPosition = formatted.length;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }

  /// Binlik ayırıcı ekler
  String _formatWithThousandsSeparator(String digits) {
    if (digits.isEmpty) return '';

    final buffer = StringBuffer();
    final length = digits.length;

    for (int i = 0; i < length; i++) {
      // Her 3 basamakta bir nokta ekle (sondan başlayarak)
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }

    return buffer.toString();
  }
}
