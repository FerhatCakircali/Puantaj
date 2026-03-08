/// Çalışan form validasyon yardımcı sınıfı
class EmployeeValidationHelper {
  /// Form alanlarını doğrular
  ///
  /// Tüm zorunlu alanların dolu olup olmadığını kontrol eder.
  /// Hata varsa hata mesajını döndürür, yoksa null döner.
  static String? validateForm({
    required String name,
    required String title,
    required String phone,
  }) {
    if (name.trim().isEmpty) {
      return 'İsim Soyisim alanı boş bırakılamaz';
    }

    if (title.trim().isEmpty) {
      return 'Unvan alanı boş bırakılamaz';
    }

    if (phone.trim().isEmpty) {
      return 'Telefon alanı boş bırakılamaz';
    }

    return null;
  }
}
