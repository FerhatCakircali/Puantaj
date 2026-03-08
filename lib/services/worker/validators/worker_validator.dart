import '../../../core/validation/base_validator.dart';
import '../../validation_service.dart';

/// Çalışan verilerini doğrulayan sınıf
class WorkerValidator extends BaseValidator {
  final ValidationService _validationService;

  WorkerValidator({ValidationService? validationService})
    : _validationService = validationService ?? ValidationService();

  /// Kullanıcı adının kullanılabilir olup olmadığını kontrol eder
  ///
  /// [username] Kontrol edilecek kullanıcı adı
  /// Returns: Kullanıcı adı kullanılıyorsa true, kullanılabilirse false
  Future<bool> isUsernameExists(String username) async {
    return executeValidation(
      () async {
        final result = await _validationService.checkUsernameAvailability(
          username.toLowerCase(),
        );
        return result != null;
      },
      false,
      context: 'WorkerValidator.isUsernameExists',
    );
  }

  /// E-posta adresinin kullanılabilir olup olmadığını kontrol eder
  ///
  /// [email] Kontrol edilecek e-posta adresi
  /// Returns: E-posta kullanılıyorsa true, kullanılabilirse false
  Future<bool> isEmailExists(String email) async {
    if (email.trim().isEmpty) return false;

    return executeValidation(
      () async {
        final result = await _validationService.checkEmailAvailability(
          email.toLowerCase(),
        );
        return result != null;
      },
      false,
      context: 'WorkerValidator.isEmailExists',
    );
  }

  /// E-posta kullanılabilirliğini kontrol eder ve hata mesajı döndürür
  ///
  /// [email] Kontrol edilecek e-posta adresi
  /// [workerId] Güncelleme işleminde mevcut çalışanın ID'si (opsiyonel)
  /// Returns: Hata varsa mesaj, yoksa null
  Future<String?> checkEmailAvailability(String email, {int? workerId}) async {
    return executeValidation(
      () async {
        final lowercaseEmail = email.toLowerCase();
        return await _validationService.checkEmailAvailability(
          lowercaseEmail,
          excludeWorkerId: workerId,
        );
      },
      'E-posta kontrolü sırasında bir hata oluştu',
      context: 'WorkerValidator.checkEmailAvailability',
    );
  }
}
