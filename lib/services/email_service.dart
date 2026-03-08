import '../core/error_handling/error_handler_mixin.dart';
import 'email/handlers/password_reset_handler.dart';
import 'email/handlers/email_verification_handler.dart';

/// Email gönderme servisi - Supabase Functions kullanır
///
/// Şifre sıfırlama ve email doğrulama işlemlerini koordine eder
class EmailService with ErrorHandlerMixin {
  final PasswordResetHandler _passwordResetHandler;
  final EmailVerificationHandler _verificationHandler;

  EmailService({
    PasswordResetHandler? passwordResetHandler,
    EmailVerificationHandler? verificationHandler,
  }) : _passwordResetHandler = passwordResetHandler ?? PasswordResetHandler(),
       _verificationHandler = verificationHandler ?? EmailVerificationHandler();

  /// Şifre sıfırlama email'i gönderir
  Future<String?> sendPasswordResetEmail({
    required String email,
    required String userType,
  }) async {
    return handleError(
      () async => await _passwordResetHandler.sendPasswordResetEmail(
        email: email,
        userType: userType,
      ),
      null,
      context: 'EmailService.sendPasswordResetEmail',
    );
  }

  /// Şifre sıfırlama token'ını doğrular
  Future<String?> verifyResetToken(String token) async {
    return handleError(
      () async => await _passwordResetHandler.verifyResetToken(token),
      null,
      context: 'EmailService.verifyResetToken',
    );
  }

  /// Token ile şifre sıfırlar
  Future<String?> resetPasswordWithToken({
    required String token,
    required String newPassword,
  }) async {
    return handleError(
      () async => await _passwordResetHandler.resetPasswordWithToken(
        token: token,
        newPassword: newPassword,
      ),
      null,
      context: 'EmailService.resetPasswordWithToken',
    );
  }

  /// Email doğrulama kodu gönderir
  Future<String?> sendVerificationEmail({
    required String email,
    required String userType,
    required int userId,
  }) async {
    return handleError(
      () async => await _verificationHandler.sendVerificationEmail(
        email: email,
        userType: userType,
        userId: userId,
      ),
      null,
      context: 'EmailService.sendVerificationEmail',
    );
  }

  /// Email doğrulama kodunu kontrol eder
  Future<String?> verifyEmail({
    required String token,
    required String userType,
    required int userId,
  }) async {
    return handleError(
      () async => await _verificationHandler.verifyEmail(
        token: token,
        userType: userType,
        userId: userId,
      ),
      null,
      context: 'EmailService.verifyEmail',
    );
  }

  /// Süresi dolmuş token'ları temizler
  Future<void> cleanupExpiredTokens() async {
    return handleError(
      () async => await _verificationHandler.cleanupExpiredTokens(),
      null,
      context: 'EmailService.cleanupExpiredTokens',
    );
  }
}
