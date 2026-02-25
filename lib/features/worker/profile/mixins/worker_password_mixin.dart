import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/mixins/context_safety_mixin.dart';
import '../../../../data/services/local_storage_service.dart';

/// Çalışan şifre değiştirme mixin'i
///
/// Şifre değiştirme ve doğrulama işlemleri
mixin WorkerPasswordMixin<T extends StatefulWidget> on State<T> {
  ContextSafetyMixin get contextSafety => this as ContextSafetyMixin;

  bool _isChangingPassword = false;

  bool get isChangingPassword => _isChangingPassword;

  /// Şifre değiştirir
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (!mounted) return false;

    // Validasyon
    if (currentPassword.trim().isEmpty ||
        newPassword.trim().isEmpty ||
        confirmPassword.trim().isEmpty) {
      contextSafety.safeShowErrorSnackBar(
        'Lütfen tüm şifre alanlarını doldurunuz',
      );
      return false;
    }

    if (newPassword.trim() != confirmPassword.trim()) {
      contextSafety.safeShowErrorSnackBar('Yeni şifreler eşleşmiyor');
      return false;
    }

    if (newPassword.trim().length < 6) {
      contextSafety.safeShowErrorSnackBar(
        'Yeni şifre en az 6 karakter olmalıdır',
      );
      return false;
    }

    setState(() => _isChangingPassword = true);

    try {
      // Worker session'dan worker ID'yi al
      final localStorage = LocalStorageService.instance;
      final session = await localStorage.getWorkerSession();

      if (session == null) {
        if (!mounted) return false;
        contextSafety.safeShowErrorSnackBar('Oturum bulunamadı');
        return false;
      }

      final workerId = int.parse(session['workerId']!);

      // Supabase RPC ile şifre değiştir
      final response = await Supabase.instance.client.rpc(
        'change_worker_password',
        params: {
          'worker_id': workerId,
          'current_password': currentPassword.trim(),
          'new_password': newPassword.trim(),
        },
      );

      if (!mounted) return false;

      // Response kontrolü
      if (response == null || response == false) {
        contextSafety.safeShowErrorSnackBar('Mevcut şifre hatalı');
        return false;
      }

      contextSafety.safeShowSuccessSnackBar('Şifre başarıyla değiştirildi');
      return true;
    } catch (e) {
      debugPrint('Şifre değiştirme hatası: $e');
      if (mounted) {
        contextSafety.safeShowErrorSnackBar(
          'Şifre değiştirilirken hata oluştu: $e',
        );
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _isChangingPassword = false);
      }
    }
  }

  /// Şifre gücünü kontrol eder
  String? validatePasswordStrength(String password) {
    if (password.isEmpty) return 'Şifre gerekli';
    if (password.length < 6) return 'Şifre en az 6 karakter olmalı';
    if (password.length > 50) return 'Şifre en fazla 50 karakter olabilir';
    return null;
  }

  /// Şifrelerin eşleşip eşleşmediğini kontrol eder
  String? validatePasswordMatch(String password, String confirmPassword) {
    if (confirmPassword.isEmpty) return 'Şifre tekrarı gerekli';
    if (password != confirmPassword) return 'Şifreler eşleşmiyor';
    return null;
  }
}
